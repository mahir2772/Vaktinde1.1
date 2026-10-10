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
 */
object PrayerWidgetData {
    const val PREFS = "HomeWidgetPreferences"
    private val TIME_KEYS = arrayOf("imsak_time", "gunes_time", "ogle_time", "ikindi_time", "aksam_time", "yatsi_time")
    private val LABEL_KEYS = arrayOf("label_imsak", "label_gunes", "label_ogle", "label_ikindi", "label_aksam", "label_yatsi")
    // Dart'ın yönelme hâli başlıkları ("İmsaka", "İkindiye"); yoksa title_text / vakit adı
    private val TITLE_KEYS = arrayOf("title_imsak", "title_gunes", "title_ogle", "title_ikindi", "title_aksam", "title_yatsi")
    private val DEFAULT_LABELS = arrayOf("İmsak", "Güneş", "Öğle", "İkindi", "Akşam", "Yatsı")
    private const val DATE_KEY = "times_date"
    private const val TOMORROW_PREFIX = "tomorrow_"
    private const val HIJRI_KEY = "hijri_date_text"
    private const val TOMORROW_HIJRI_KEY = "tomorrow_hijri_date_text"
    private val DATE_PATTERN = Regex("\\d{4}-\\d{2}-\\d{2}")
    private const val DAY_MS = 24 * 60 * 60 * 1000L

    // Sağlayıcı başına tek güncelleme alarmı; kurulum ve iptal aynı requestCode + intent
    private const val UPDATE_REQUEST_CODE = 0

    // İzinsiz yenileme penceresi (Android 12+ en kısa pencere 10 dk)
    private const val REFRESH_WINDOW_MS = 10 * 60 * 1000L

    /** Bugün gösterilecek 6 vakit, yatsıdan sonraki imsak; [rolledOver]: gün dönmüş, yarının seti bugünün */
    class Day(val times: List<String>, val nextImsak: String, val rolledOver: Boolean)

    /** Sıradaki vakit: zaman (ms), ad, sıra (0 imsak … 5 yatsı; ertesi günün imsakı da 0) */
    class NextPrayer(val time: Long, val label: String, val index: Int)

    /** Saat veya saat dilimi elle/şebekeden değişti */
    fun isTimeChange(action: String?): Boolean =
        action == Intent.ACTION_TIME_CHANGED || action == Intent.ACTION_TIMEZONE_CHANGED

    fun hasTimes(data: SharedPreferences): Boolean = !data.getString(TIME_KEYS[0], "").isNullOrEmpty()

    fun today(data: SharedPreferences, now: Calendar): Day {
        val todaySet = TIME_KEYS.map { data.getString(it, "") ?: "" }
        val tomorrowSet = TIME_KEYS.map { data.getString(TOMORROW_PREFIX + it, "") ?: "" }
        val stored = data.getString(DATE_KEY, null)
        if (stored == null || !DATE_PATTERN.matches(stored) || tomorrowSet.any { timeMs(it, 0, now) == 0L }) {
            return Day(todaySet, todaySet[0], false)
        }
        val current = dateKey(now)
        return when {
            stored == current -> Day(todaySet, tomorrowSet[0], false)
            // Gece yarısı geçti, Dart henüz yazmadı: yarının seti bugünün (sonraki imsak yaklaşık)
            stored < current -> Day(tomorrowSet, tomorrowSet[0], true)
            // Saat geri alınmış: eski davranış
            else -> Day(todaySet, todaySet[0], false)
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
     * "9 dk'da bir" kotasını paylaşıp ezanı geciktirir.
     */
    fun setRefreshAlarm(context: Context, targetTime: Long, pendingIntent: PendingIntent) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
            alarmManager.setWindow(AlarmManager.RTC, targetTime, REFRESH_WINDOW_MS, pendingIntent)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, targetTime, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, targetTime, pendingIntent)
        }
    }
}
