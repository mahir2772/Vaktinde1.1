package com.mmdigital.vaktinde

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.text.SpannableString
import android.text.Spanned
import android.text.style.RelativeSizeSpan
import java.util.Calendar
import java.util.GregorianCalendar
import java.util.Locale
import java.util.TimeZone
import kotlin.math.abs

/**
 * Widget'ların ve kalıcı bildirimin ortak vakit mantığı (HomeWidgetPreferences).
 * Dart bugünün vakitlerini ("HH:mm"), bu setin gününü (times_date, yyyy-MM-dd) ve koordinat
 * varsa yarının vakitlerini (tomorrow_*) yazar. Yeni anahtarlar yoksa (eski sürüm verisi)
 * eski davranış: yatsıdan sonra bugünün imsakı +1 gün.
 * Hesap hep "HH:mm" anahtarlarıyla; ekrana yazılan saat Dart'ın aynı anahtar + "_text" metni
 * (uygulama dilinde: en/ar 12 saat "4:08 PM", diğerleri 24 saat), yoksa "HH:mm".
 */
object PrayerWidgetData {
    const val PREFS = "HomeWidgetPreferences"
    private val TIME_KEYS = arrayOf("imsak_time", "gunes_time", "ogle_time", "ikindi_time", "aksam_time", "yatsi_time")
    private const val TEXT_SUFFIX = "_text"
    private val LABEL_KEYS = arrayOf("label_imsak", "label_gunes", "label_ogle", "label_ikindi", "label_aksam", "label_yatsi")
    // Dart'ın yönelme hâli başlıkları ("İmsaka", "İkindiye"); yoksa title_text / vakit adı
    private val TITLE_KEYS = arrayOf("title_imsak", "title_gunes", "title_ogle", "title_ikindi", "title_aksam", "title_yatsi")
    private val DEFAULT_LABELS = arrayOf("İmsak", "Güneş", "Öğle", "İkindi", "Akşam", "Yatsı")
    private const val DATE_KEY = "times_date"
    private const val TOMORROW_PREFIX = "tomorrow_"
    private const val HIJRI_KEY = "hijri_date_text"
    private const val TOMORROW_HIJRI_KEY = "tomorrow_hijri_date_text"
    // Dart'ın kalıcı bildirim ayarı (BackgroundManager.widgetFlagKey)
    private const val PERSISTENT_NOTIFICATION_KEY = "persistent_notification"
    private val DATE_PATTERN = Regex("\\d{4}-\\d{2}-\\d{2}")
    private const val DAY_MS = 24 * 60 * 60 * 1000L

    // Sağlayıcı başına tek güncelleme alarmı; kurulum ve iptal aynı requestCode + intent
    private const val UPDATE_REQUEST_CODE = 0

    // İzinsiz yenileme penceresi (Android 12+ en kısa pencere 10 dk)
    private const val REFRESH_WINDOW_MS = 10 * 60 * 1000L

    /** Yenileme alarmının hedeflediği an (ms): gelince gecikme ölçülür ([noteRefreshDelay]) */
    const val EXTRA_TARGET = "vaktinde_refresh_target"

    // Dart'ın yazdığı ezan "alarm saati" anları (WidgetService.alarmClockTimesKey)
    private const val ALARM_CLOCK_TIMES_KEY = "alarm_clock_times"
    private const val ALARM_CLOCK_MATCH_MS = 60 * 1000L

    // Son geç yenileme: ne zaman, kaç ms (Bildirim Kontrolü okur); soğuk başlangıç payı 2 dk
    private const val LATE_AT_KEY = "refresh_late_at"
    private const val LATE_MS_KEY = "refresh_late_ms"
    private const val LATE_THRESHOLD_MS = 2 * 60 * 1000L

    /**
     * Bugün gösterilecek 6 vakit ("HH:mm"), yatsıdan sonraki imsak; [rolledOver]: gün dönmüş, yarının
     * seti bugünün. [texts] / [nextImsakText]: aynı vakitlerin ekrandaki yazımı ([displayTime])
     */
    class Day(
        val times: List<String>,
        val nextImsak: String,
        val rolledOver: Boolean,
        val texts: List<String> = times,
        val nextImsakText: String = nextImsak,
    )

    /** Sıradaki vakit: zaman (ms), ad, sıra (0 imsak … 5 yatsı; ertesi günün imsakı da 0) */
    class NextPrayer(val time: Long, val label: String, val index: Int)

    /** Saat veya saat dilimi elle/şebekeden değişti */
    fun isTimeChange(action: String?): Boolean =
        action == Intent.ACTION_TIME_CHANGED || action == Intent.ACTION_TIMEZONE_CHANGED

    fun hasTimes(data: SharedPreferences): Boolean = !data.getString(TIME_KEYS[0], "").isNullOrEmpty()

    /**
     * Kalıcı bildirim (888) açık mı. Dart her açılışta ve ayar değişince yazar; yeni kurulumda
     * vakitlerden önce (false). Yoksa ayardan önceki sürümün verisidir (güncelleme sonrası uygulama
     * henüz açılmadı): açık, güncelleyen kullanıcının bildirimi kaybolmaz.
     */
    fun persistentNotificationEnabled(data: SharedPreferences): Boolean = try {
        data.getBoolean(PERSISTENT_NOTIFICATION_KEY, true)
    } catch (e: ClassCastException) {
        true
    }

    fun today(data: SharedPreferences, now: Calendar): Day {
        val todaySet = TIME_KEYS.map { data.getString(it, "") ?: "" }
        val tomorrowSet = TIME_KEYS.map { data.getString(TOMORROW_PREFIX + it, "") ?: "" }
        val todayTexts = texts(data, "", todaySet)
        val stored = data.getString(DATE_KEY, null)
        if (stored == null || !DATE_PATTERN.matches(stored) || tomorrowSet.any { timeMs(it, 0, now) == 0L }) {
            return Day(todaySet, todaySet[0], false, todayTexts, todayTexts[0])
        }
        val tomorrowTexts = texts(data, TOMORROW_PREFIX, tomorrowSet)
        val current = dateKey(now)
        return when {
            stored == current -> Day(todaySet, tomorrowSet[0], false, todayTexts, tomorrowTexts[0])
            // Gece yarısı geçti, Dart henüz yazmadı: yarının seti bugünün (sonraki imsak yaklaşık)
            stored < current -> Day(tomorrowSet, tomorrowSet[0], true, tomorrowTexts, tomorrowTexts[0])
            // Saat geri alınmış: eski davranış
            else -> Day(todaySet, todaySet[0], false, todayTexts, todayTexts[0])
        }
    }

    // [prefix] setinin ("" bugün, "tomorrow_" yarın) ekrandaki yazımı
    private fun texts(data: SharedPreferences, prefix: String, times: List<String>): List<String> =
        TIME_KEYS.mapIndexed { i, key -> displayTime(times[i], data.getString(prefix + key + TEXT_SUFFIX, null)) }

    /**
     * "HH:mm" vaktinin ekrandaki yazımı: Dart'ın biçimlediği [text] ("4:08 PM", "4:08 م", "16:08"),
     * saati ve dakikası vakitle tutuyorsa; yoksa (eski veri, yarım kalmış yazım) [time] olduğu gibi.
     * Başka bir vaktin saati asla gösterilmez.
     */
    fun displayTime(time: String, text: String?): String {
        if (text.isNullOrBlank()) return time
        val parts = time.split(":")
        val hour = parts.getOrNull(0)?.trim()?.toIntOrNull() ?: return time
        val minute = parts.getOrNull(1)?.trim()?.toIntOrNull() ?: return time
        // Metindeki ilk iki sayı (Character.digit: Arapça-Hint rakamları da)
        val numbers = mutableListOf<Int>()
        var current = -1
        for (c in text) {
            val d = Character.digit(c, 10)
            if (d >= 0) {
                current = if (current < 0) d else current * 10 + d
            } else if (current >= 0) {
                numbers.add(current)
                current = -1
            }
        }
        if (current >= 0) numbers.add(current)
        if (numbers.size < 2 || numbers[1] != minute) return time
        val hour12 = if (hour % 12 == 0) 12 else hour % 12
        return if (numbers[0] == hour || numbers[0] == hour12) text else time
    }

    /**
     * Saat içeren yazı ("4:08 PM", "Maghrib 7:05 PM", "المغرب 7:05 م"): sondaki öğleden önce/sonra
     * eki <small> boyutunda (dar widget'ta saat sığsın). Son parça rakamlıysa (24 saat) olduğu gibi.
     */
    fun styledTime(text: String): CharSequence {
        val space = text.indexOfLast { it.isWhitespace() }
        if (space <= 0 || space == text.length - 1 || text.substring(space + 1).any { Character.isDigit(it) }) return text
        return SpannableString(text).apply {
            setSpan(RelativeSizeSpan(0.8f), space + 1, text.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
    }

    /** Vaktin adı (0 imsak … 5 yatsı): Dart'ın label_<vakit> anahtarı, yoksa Türkçe */
    fun label(data: SharedPreferences, index: Int): String =
        data.getString(LABEL_KEYS[index], DEFAULT_LABELS[index]) ?: DEFAULT_LABELS[index]

    /** Sıradaki vakit; veri yoksa null */
    fun nextPrayer(data: SharedPreferences, day: Day, now: Calendar): NextPrayer? {
        val labels = LABEL_KEYS.indices.map { label(data, it) }
        val candidates = day.times.mapIndexed { i, time -> NextPrayer(timeMs(time, 0, now), labels[i], i) } +
            NextPrayer(timeMs(day.nextImsak, 1, now), labels[0], 0)
        val nowMs = now.timeInMillis
        return candidates.filter { it.time > nowMs + 1000L }.minByOrNull { it.time }
    }

    /**
     * Sayacın başlığı ("İkindiye"): Dart'ın title_<vakit> anahtarı. Yoksa (eski veri) Dart'ın
     * hedefi bu vakitse title_text, değilse vakit adı.
     */
    fun title(data: SharedPreferences, next: NextPrayer): String {
        val own = data.getString(TITLE_KEYS[next.index], null)
        if (!own.isNullOrEmpty()) return own
        return if (abs(longValue(data, "target_time_ms") - next.time) < 60000) {
            data.getString("title_text", "") ?: ""
        } else {
            next.label
        }
    }

    // home_widget küçük tam sayıyı Int yazar: getLong ClassCastException atmasın
    private fun longValue(data: SharedPreferences, key: String): Long = try {
        data.getLong(key, 0L)
    } catch (e: ClassCastException) {
        (data.all[key] as? Number)?.toLong() ?: 0L
    }

    /** Gün dönmüşse yarının hicri tarihi (yazılmışsa) */
    fun hijriText(data: SharedPreferences, day: Day): String {
        val todayText = data.getString(HIJRI_KEY, "") ?: ""
        if (!day.rolledOver) return todayText
        val tomorrowText = data.getString(TOMORROW_HIJRI_KEY, "") ?: ""
        return if (tomorrowText.isNotEmpty()) tomorrowText else todayText
    }

    /** "HH:mm" → [now] gününden [dayOffset] gün sonraki zaman (ms); geçersizse 0 */
    fun timeMs(timeStr: String?, dayOffset: Int, now: Calendar): Long {
        if (timeStr.isNullOrEmpty() || !timeStr.contains(":")) return 0L
        return try {
            val parts = timeStr.split(":")
            val calendar = now.clone() as Calendar
            calendar.set(Calendar.HOUR_OF_DAY, parts[0].toInt())
            calendar.set(Calendar.MINUTE, parts[1].toInt())
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            if (dayOffset != 0) calendar.add(Calendar.DAY_OF_YEAR, dayOffset)
            calendar.timeInMillis
        } catch (e: Exception) {
            0L
        }
    }

    // Dart'ın yazdığıyla aynı biçim; Locale.US: Arapça yerelde de ASCII rakam
    fun dateKey(c: Calendar): String = String.format(
        Locale.US, "%04d-%02d-%02d",
        c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1, c.get(Calendar.DAY_OF_MONTH)
    )

    /** "yyyy-MM-dd" → 1970'ten beri gün (UTC: yaz saati farkı yok); geçersizse null */
    fun epochDay(key: String?): Long? {
        if (key == null || !DATE_PATTERN.matches(key)) return null
        val parts = key.split("-")
        val c = GregorianCalendar(TimeZone.getTimeZone("UTC"))
        c.clear()
        c.set(parts[0].toInt(), parts[1].toInt() - 1, parts[2].toInt())
        return c.timeInMillis / DAY_MS
    }

    private fun updateIntent(context: Context, providerClass: Class<*>): Intent =
        Intent(context, providerClass).apply { action = AppWidgetManager.ACTION_APPWIDGET_UPDATE }

    /** Vakit gelince bu türdeki tüm widget'lar yenilenir; widget kalmadıysa alarm iptal */
    fun scheduleWidgetUpdate(context: Context, providerClass: Class<*>, targetTime: Long) {
        try {
            val manager = AppWidgetManager.getInstance(context) ?: return
            val ids = manager.getAppWidgetIds(ComponentName(context, providerClass))
            if (ids == null || ids.isEmpty()) {
                cancelWidgetUpdate(context, providerClass)
                return
            }
            val intent = updateIntent(context, providerClass).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                putExtra(EXTRA_TARGET, targetTime)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, UPDATE_REQUEST_CODE, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            setRefreshAlarm(context, targetTime, pendingIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /** Son widget kaldırılınca (onDisabled): kurulumdaki requestCode + intent ile iptal */
    fun cancelWidgetUpdate(context: Context, providerClass: Class<*>) {
        try {
            val pendingIntent = PendingIntent.getBroadcast(
                context, UPDATE_REQUEST_CODE, updateIntent(context, providerClass),
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            ) ?: return
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /** Saat değişiminde bu sağlayıcının tüm widget'ları hemen yeniden çizilir (alarm da yeniden kurulur) */
    fun redrawAll(context: Context, provider: AppWidgetProvider) {
        try {
            val manager = AppWidgetManager.getInstance(context) ?: return
            val ids = manager.getAppWidgetIds(ComponentName(context, provider.javaClass))
            if (ids != null && ids.isNotEmpty()) provider.onUpdate(context, manager, ids)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Yenileme alarmı (widget'lar ve NotificationUpdater ortak). Tam zamanlı alarm izni yoksa
     * (Android 12/12L'de "Alarmlar ve hatırlatıcılar" kapalı) setAlarmClock da SecurityException
     * atar: izin istemeyen, cihazı uyandırmayan pencereli alarm kurulur (ekran açıkken en geç
     * 10 dk, kapalıyken açılınca gelir). setAndAllowWhileIdle olmaz: Doze'da ezanla aynı
     * "9 dk'da bir" kotasını paylaşıp ezanı geciktirir. O dakikada ezan "alarm saati" kipinde
     * kuruluysa yenileme de o kipte (güç yöneticileri geciktirmez; simge zaten ezan için var),
     * değilse setExactAndAllowWhileIdle (bazı üreticiler dakikalarca geciktirir).
     */
    fun setRefreshAlarm(context: Context, targetTime: Long, pendingIntent: PendingIntent) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
            alarmManager.setWindow(AlarmManager.RTC, targetTime, REFRESH_WINDOW_MS, pendingIntent)
        } else if (hasAlarmClockAt(context, targetTime)) {
            val show = PendingIntent.getActivity(
                context, 0, Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.setAlarmClock(AlarmManager.AlarmClockInfo(targetTime, show), pendingIntent)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, targetTime, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, targetTime, pendingIntent)
        }
    }

    /** [targetTime]'ın dakikasında ezan "alarm saati" kipinde kurulu mu (Dart'ın son kurulumu) */
    fun hasAlarmClockAt(context: Context, targetTime: Long): Boolean = try {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(ALARM_CLOCK_TIMES_KEY, null)
            ?.split(',')
            ?.any { abs((it.trim().toLongOrNull() ?: 0L) - targetTime) < ALARM_CLOCK_MATCH_MS }
            ?: false
    } catch (e: ClassCastException) {
        false
    }

    /**
     * Yenileme alarmı geldiğinde: hedeften 2 dk'dan geç geldiyse son gecikme kaydedilir
     * (Bildirim Kontrolü "telefon widget'ı geciktiriyor" der). Hedefsiz yayın (sistemin 30 dk'lık
     * güncellemesi, uygulamanın yazımı) ölçülmez.
     */
    fun noteRefreshDelay(context: Context, intent: Intent?) {
        try {
            val target = intent?.getLongExtra(EXTRA_TARGET, 0L) ?: 0L
            if (target <= 0L) return
            val now = System.currentTimeMillis()
            val late = now - target
            if (late < LATE_THRESHOLD_MS) return
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putLong(LATE_AT_KEY, now)
                .putLong(LATE_MS_KEY, late)
                .apply()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
