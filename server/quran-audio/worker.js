// Vaktinde Kur'an sesi ara sunucusu (Cloudflare Worker).
//
// Quran Foundation Content API'si gizli anahtar (client_secret) ister; QF
// şartlarına göre bu anahtar mobil uygulamaya konamaz, sadece geliştiricinin
// kendi sunucusunda durur. Bu Worker anahtarı saklar, belirteci (token) alır
// ve uygulamaya sadece iki şeyi döner: kârî listesi ve bir surenin ses adresi
// + ayet zamanları. Ses dosyasının kendisi QF'nin döndürdüğü adresten
// uygulamada akışla çalınır (saklanmaz / indirilmez).
//
// Gizli değişkenler (wrangler secret put): QF_CLIENT_ID, QF_CLIENT_SECRET
// Değişkenler (wrangler.toml [vars]): QF_ENV = "prelive" | "production",
// ENABLED = "1" (başka değerde uygulama dinlemeyi gizler)
// İsteğe bağlı: RATE_LIMITER bağlaması (IP başına istek sınırı)

const ENVIRONMENTS = {
  prelive: {
    auth: 'https://prelive-oauth2.quran.foundation',
    api: 'https://apis-prelive.quran.foundation/content/api/v4',
  },
  production: {
    auth: 'https://oauth2.quran.foundation',
    api: 'https://apis.quran.foundation/content/api/v4',
  },
};

const LANGUAGES = new Set(['tr', 'en', 'de', 'fr', 'ar']);

// En uzun sure (Bakara) 286 ayet
const MAX_AYAHS = 286;

// QF şartı: içerik en çok 1 hafta saklanır; burada 1 gün
const EDGE_CACHE_SECONDS = 86400;
const CLIENT_CACHE_SECONDS = 3600;
const UPSTREAM_TIMEOUT_MS = 10000;
const USER_AGENT = 'Vaktinde-Audio-Proxy/1.0';

// Süreç (isolate) içi belirteç önbelleği; süresi dolmadan 60 sn önce yenilenir
let tokenCache = null;

export default {
  async fetch(request, env, ctx) {
    try {
      return await handle(request, env, ctx);
    } catch (error) {
      // Ayrıntı (anahtar, belirteç, yukarı yanıt) dışarı verilmez
      console.error('istek işlenemedi', error && error.name);
      return json({ error: 'unavailable' }, 502);
    }
  },
};

async function handle(request, env, ctx) {
  if (request.method !== 'GET') return json({ error: 'method' }, 405);
  if (env.ENABLED !== '1') return json({ error: 'disabled' }, 503);
  const upstream = ENVIRONMENTS[env.QF_ENV] || ENVIRONMENTS.prelive;
  if (!env.QF_CLIENT_ID || !env.QF_CLIENT_SECRET) {
    return json({ error: 'disabled' }, 503);
  }

  const url = new URL(request.url);
  const route = parseRoute(url);
  if (!route) return json({ error: 'not_found' }, 404);

  if (env.RATE_LIMITER) {
    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    const { success } = await env.RATE_LIMITER.limit({ key: ip });
    if (!success) return json({ error: 'rate_limited' }, 429);
  }

  // Önbellek anahtarı sadece doğrulanmış parametrelerden (gereksiz sorgu
  // parametreleriyle önbellek atlatılamaz)
  const cacheKey = new Request(`https://cache.vaktinde/${route.key}`);
  const cache = caches.default;
  const cached = await cache.match(cacheKey);
  if (cached) return withClientCache(cached);

  const result = await route.load(env, upstream);
  const response = json(result.body, result.status);
  if (result.status === 200) {
    const stored = new Response(response.clone().body, response);
    stored.headers.set('Cache-Control', `public, max-age=${EDGE_CACHE_SECONDS}`);
    ctx.waitUntil(cache.put(cacheKey, stored));
  }
  return withClientCache(response);
}

/** /v1/reciters?lang=xx ve /v1/chapter/{kârî}/{sure}; başka yol yok */
export function parseRoute(url) {
  const parts = url.pathname.split('/').filter(Boolean);
  if (parts.length === 2 && parts[0] === 'v1' && parts[1] === 'reciters') {
    const requested = url.searchParams.get('lang') || 'en';
    const lang = LANGUAGES.has(requested) ? requested : 'en';
    return {
      key: `reciters/${lang}`,
      load: (env, upstream) => loadReciters(env, upstream, lang),
    };
  }
  if (parts.length === 4 && parts[0] === 'v1' && parts[1] === 'chapter') {
    const reciter = positiveInt(parts[2], 99999);
    const surah = positiveInt(parts[3], 114);
    if (reciter === null || surah === null) return null;
    return {
      key: `chapter/${reciter}/${surah}`,
      load: (env, upstream) => loadChapter(env, upstream, reciter, surah),
    };
  }
  return null;
}

function positiveInt(text, max) {
  if (!/^[0-9]{1,5}$/.test(text)) return null;
  const value = Number(text);
  return value >= 1 && value <= max ? value : null;
}

async function loadReciters(env, upstream, lang) {
  const data = await callApi(
    env,
    upstream,
    `/resources/chapter_reciters?language=${lang}`,
  );
  if (!data.ok) return { status: data.status, body: { error: 'upstream' } };
  const reciters = [];
  for (const r of Array.isArray(data.body.reciters) ? data.body.reciters : []) {
    if (!Number.isInteger(r.id) || typeof r.name !== 'string') continue;
    const translated = r.translated_name && r.translated_name.name;
    reciters.push({
      id: r.id,
      name: text(translated) || text(r.name),
      style: text(r.style && r.style.name),
    });
  }
  return { status: 200, body: { reciters } };
}

async function loadChapter(env, upstream, reciter, surah) {
  const data = await callApi(
    env,
    upstream,
    `/chapter_recitations/${reciter}/${surah}?segments=false`,
  );
  if (!data.ok) {
    return { status: data.status === 404 ? 404 : data.status, body: { error: 'upstream' } };
  }
  const file = data.body.audio_file || {};
  const audioUrl = safeAudioUrl(file.audio_url);
  if (!audioUrl) return { status: 404, body: { error: 'no_audio' } };
  // Ayet zamanları ([başlangıç, bitiş] ms); ayet sırasıyla, eksik/bozuksa boş
  const verses = [];
  for (const t of Array.isArray(file.timestamps) ? file.timestamps : []) {
    const match = /^([0-9]+):([0-9]+)$/.exec(String(t.verse_key || ''));
    if (!match || Number(match[1]) !== surah) continue;
    const ayah = Number(match[2]);
    if (ayah < 1 || ayah > MAX_AYAHS) continue;
    const from = Number(t.timestamp_from);
    const to = Number(t.timestamp_to);
    if (!Number.isFinite(from) || !Number.isFinite(to) || to < from) continue;
    verses[ayah - 1] = [Math.round(from), Math.round(to)];
  }
  // Seyrek dizide every() boşlukları atlar: her ayet tek tek denetlenir
  let complete = verses.length > 0;
  for (let i = 0; i < verses.length; i++) {
    if (!verses[i]) complete = false;
  }
  return {
    status: 200,
    body: { url: audioUrl, verses: complete ? verses : [] },
  };
}

/** Sadece https, kullanıcı adı/şifre yok */
export function safeAudioUrl(value) {
  if (typeof value !== 'string') return null;
  try {
    const url = new URL(value);
    if (url.protocol !== 'https:' || url.username || url.password) return null;
    return url.toString();
  } catch {
    return null;
  }
}

function text(value) {
  return typeof value === 'string' ? value.trim().slice(0, 120) : '';
}

/** Content API çağrısı; 401'de belirteç yenilenip bir kez daha denenir */
async function callApi(env, upstream, path) {
  for (let attempt = 0; attempt < 2; attempt++) {
    const token = await accessToken(env, upstream, attempt > 0);
    const response = await fetch(`${upstream.api}${path}`, {
      headers: {
        'x-auth-token': token,
        'x-client-id': env.QF_CLIENT_ID,
        'User-Agent': USER_AGENT,
        Accept: 'application/json',
      },
      signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
    });
    if (response.status === 401 && attempt === 0) continue;
    if (!response.ok) return { ok: false, status: mapStatus(response.status) };
    return { ok: true, status: 200, body: await response.json() };
  }
  return { ok: false, status: 502 };
}

function mapStatus(status) {
  if (status === 404) return 404;
  if (status === 429) return 429;
  return 502;
}

async function accessToken(env, upstream, forceRefresh) {
  const now = Date.now();
  if (
    !forceRefresh &&
    tokenCache &&
    tokenCache.auth === upstream.auth &&
    tokenCache.expires - 60000 > now
  ) {
    return tokenCache.token;
  }
  const response = await fetch(`${upstream.auth}/oauth2/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${btoa(`${env.QF_CLIENT_ID}:${env.QF_CLIENT_SECRET}`)}`,
      'Content-Type': 'application/x-www-form-urlencoded',
      'User-Agent': USER_AGENT,
    },
    body: 'grant_type=client_credentials&scope=content',
    signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
  });
  if (!response.ok) throw new Error('token');
  const data = await response.json();
  if (typeof data.access_token !== 'string') throw new Error('token');
  const lifetime = Number(data.expires_in) > 0 ? Number(data.expires_in) : 300;
  tokenCache = {
    auth: upstream.auth,
    token: data.access_token,
    expires: now + lifetime * 1000,
  };
  return tokenCache.token;
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'X-Content-Type-Options': 'nosniff',
      'Cache-Control': 'no-store',
    },
  });
}

function withClientCache(response) {
  const result = new Response(response.body, response);
  result.headers.set(
    'Cache-Control',
    response.status === 200 ? `private, max-age=${CLIENT_CACHE_SECONDS}` : 'no-store',
  );
  return result;
}

// Testler için
export function resetTokenCacheForTest() {
  tokenCache = null;
}
