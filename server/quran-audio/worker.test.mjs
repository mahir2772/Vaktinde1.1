// node --test server/quran-audio/ (Node 20+): yollar, doğrulama, belirteç,
// önbellek ve hata yanıtları; ağ çağrıları sahte.
import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import worker, { parseRoute, safeAudioUrl, resetForTest } from './worker.js';

const env = {
  ENABLED: '1',
  QF_ENV: 'prelive',
  QF_CLIENT_ID: 'id',
  QF_CLIENT_SECRET: 'secret',
};
let calls;
let tokenCount;
let apiStatus;
let store;

function ctx() {
  const pending = [];
  return { waitUntil: (p) => pending.push(p), pending };
}

beforeEach(() => {
  resetForTest();
  calls = [];
  tokenCount = 0;
  apiStatus = [];
  store = new Map();
  globalThis.caches = {
    default: {
      match: async (req) => store.get(req.url)?.clone(),
      put: async (req, res) => void store.set(req.url, res),
    },
  };
  globalThis.fetch = async (url, init = {}) => {
    calls.push({ url: String(url), init });
    if (String(url).endsWith('/oauth2/token')) {
      tokenCount++;
      return Response.json({ access_token: `t${tokenCount}`, expires_in: 3600 });
    }
    const status = apiStatus.shift() ?? 200;
    if (status !== 200) return new Response('{}', { status });
    if (String(url).includes('/resources/chapter_reciters')) {
      return Response.json({
        reciters: [
          { id: 7, name: 'Mishari Rashid al-`Afasy', style: { name: 'Murattal' }, translated_name: { name: 'Mişari Raşid el-Afasi' } },
          { id: 'x', name: 'bozuk' },
        ],
      });
    }
    return Response.json({
      audio_file: {
        audio_url: 'https://download.quranicaudio.com/qdc/x/1.mp3',
        timestamps: [
          { verse_key: '1:2', timestamp_from: 6493, timestamp_to: 11546 },
          { verse_key: '1:1', timestamp_from: 0, timestamp_to: 6493 },
        ],
      },
    });
  };
});

const get = (path, e = env, c = ctx()) =>
  worker.fetch(new Request(`https://w.example${path}`), e, c);

test('kârî listesi: dil doğrulanır, bozuk kayıt atılır, ad dile göre', async () => {
  const res = await get('/v1/reciters?lang=tr');
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), {
    reciters: [{ id: 7, name: 'Mişari Raşid el-Afasi', style: 'Murattal' }],
  });
  assert.match(calls[1].url, /chapter_reciters\?language=tr$/);
  assert.equal(calls[1].init.headers['x-client-id'], 'id');
  assert.equal(calls[1].init.headers['x-auth-token'], 't1');
  // Desteklenmeyen dil İngilizceye düşer
  await get('/v1/reciters?lang=xx');
  assert.match(calls.at(-1).url, /language=en$/);
});

test('sure sesi: adres + sıralı ayet zamanları; sadece https', async () => {
  const res = await get('/v1/chapter/7/1');
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), {
    url: 'https://download.quranicaudio.com/qdc/x/1.mp3',
    verses: [[0, 6493], [6493, 11546]],
  });
  assert.match(calls[1].url, /chapter_recitations\/7\/1\?segments=false$/);
  assert.equal(safeAudioUrl('http://a.com/1.mp3'), null);
  assert.equal(safeAudioUrl('https://u:p@a.com/1.mp3'), null);
  assert.equal(safeAudioUrl('javascript:alert(1)'), null);
  // Sadece Quran Foundation / Quran.com ses sunucuları
  assert.equal(safeAudioUrl('https://evil.example/1.mp3'), null);
  assert.equal(safeAudioUrl('https://quranicaudio.com.evil.example/1.mp3'), null);
  assert.ok(safeAudioUrl('https://verses.quran.foundation/Alafasy/mp3/001001.mp3'));
});

test('ses adresi bilinmeyen sunucudaysa 404; yok yanıtı hatırlanır', async () => {
  const realFetch = globalThis.fetch;
  globalThis.fetch = async (url, init) => {
    if (String(url).includes('/chapter_recitations/')) {
      calls.push({ url: String(url), init });
      return Response.json({ audio_file: { audio_url: 'https://evil.example/1.mp3' } });
    }
    return realFetch(url, init);
  };
  assert.equal((await get('/v1/chapter/7/5')).status, 404);
  const before = calls.length;
  assert.equal((await get('/v1/chapter/7/5')).status, 404);
  assert.equal(calls.length, before);
});

test('aynı anda gelen istekler tek belirteç alır', async () => {
  await Promise.all([get('/v1/chapter/7/1'), get('/v1/chapter/7/2'), get('/v1/reciters')]);
  assert.equal(tokenCount, 1);
});

test('geçersiz yol ve parametreler 404, GET dışı 405', async () => {
  for (const path of ['/v1/chapter/7/115', '/v1/chapter/0/1', '/v1/chapter/7/1a',
    '/v1/chapter/7', '/v2/reciters', '/', '/v1/chapter/123456/1']) {
    assert.equal((await get(path)).status, 404, path);
  }
  assert.equal(parseRoute(new URL('https://w/v1/chapter/7/114')).key, 'chapter/7/114');
  const post = await worker.fetch(
    new Request('https://w.example/v1/reciters', { method: 'POST' }), env, ctx());
  assert.equal(post.status, 405);
  assert.equal(calls.length, 0);
});

test('kapalıysa ya da anahtar yoksa 503 (uygulama dinlemeyi gizler)', async () => {
  assert.equal((await get('/v1/reciters', { ...env, ENABLED: '0' })).status, 503);
  assert.equal((await get('/v1/reciters', { ...env, QF_CLIENT_SECRET: '' })).status, 503);
  assert.equal(calls.length, 0);
});

test('belirteç bir kez alınır; 401 gelince yenilenip bir kez tekrar denenir', async () => {
  await get('/v1/chapter/7/1');
  await get('/v1/chapter/7/2');
  assert.equal(tokenCount, 1);
  apiStatus = [401];
  const res = await get('/v1/chapter/7/3');
  assert.equal(res.status, 200);
  assert.equal(tokenCount, 2);
});

test('başarılı yanıt önbelleğe alınır (1 gün), hata alınmaz; hata ayrıntısı verilmez', async () => {
  const c = ctx();
  await get('/v1/chapter/7/1', env, c);
  await Promise.all(c.pending);
  assert.equal(store.size, 1);
  const [stored] = store.values();
  assert.equal(stored.headers.get('Cache-Control'), 'public, max-age=86400');
  const before = calls.length;
  // workers.dev: Cache API boş döner, süreç içi önbellek yine yanıtlar
  store.clear();
  const again = await get('/v1/chapter/7/1?x=1');
  assert.equal(again.status, 200);
  assert.equal(calls.length, before); // sorgu eklemek önbelleği atlatmaz
  assert.equal(again.headers.get('Cache-Control'), 'private, max-age=3600');

  apiStatus = [500];
  const failed = await get('/v1/chapter/7/9');
  assert.equal(failed.status, 502);
  assert.deepEqual(await failed.json(), { error: 'upstream' });
  assert.equal(store.size, 0);
  apiStatus = [];
  assert.equal((await get('/v1/chapter/7/9')).status, 200); // hata hatırlanmaz
});

test('IP başına sınır aşılınca 429', async () => {
  const limited = { ...env, RATE_LIMITER: { limit: async () => ({ success: false }) } };
  assert.equal((await get('/v1/reciters', limited)).status, 429);
});
