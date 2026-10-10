package com.mmdigital.vaktinde

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar

/**
 * Ramazan widget'ı: Ramazan'da iftara (imsak–akşam) ya da sahura (akşamdan imsaka; ilk sahur
 * gecesi dahil) kalan süre, hedef vakit ve "Ramazan · N. gün"; Ramazan dışında Ramazan'a kalan
 * gün ve başlangıç tarihi. Ramazan tarihleri ve metinler Dart'tan (WidgetService.ramadanData),
 * vakitler diğer widget'larla ortak (PrayerWidgetData). Gün numarası ve kalan gün burada
 * tarihlerden hesaplanır: gece yarısı ve son iftardan sonra uygulama beklenmez.
 */
class VaktindeWidgetRamadanProvider : HomeWidgetProvider() {

    enum class Mode { NONE, SAHUR, IFTAR, UNTIL }

    /**
     * Çizilecek durum. [target]: sayacın hedefi (SAHUR/IFTAR), [day]: Ramazan günü ya da (UNTIL)
     * Ramazan'a kalan gün, [switchAt]: görünümün değiştiği an (yenileme alarmı; NONE'da 0).
     */
    class State(
        val mode: Mode,
        val target: Long = 0L,
        val targetText: String = "",
        val day: Int = 0,
        val startText: String = "",
        val switchAt: Long = 0L,
    )

    companion object {
        // Dart: WidgetService.ramadanData (yyyy-MM-dd; bitiş = son oruç günü)
        private const val START_KEY = "ramadan_start"
        private const val END_KEY = "ramadan_end"
        private const val NEXT_START_KEY = "ramadan_next_start"
        private const val START_TEXT_KEY = "ramadan_start_text"
        private const val NEXT_START_TEXT_KEY = "ramadan_next_start_text"
        private const val SAHUR_TITLE_KEY = "ramadan_title_sahur"
        private const val IFTAR_TITLE_KEY = "ramadan_title_iftar"
        private const val UNTIL_TITLE_KEY = "ramadan_title_until"
        private const val DAY_TEXT_KEY = "ramadan_day_text" // %d: gün numarası

        // Dart henüz yazmadıysa (eski veri) Türkçe
        private val DEFAULT_TEXTS = mapOf(
            SAHUR_TITLE_KEY to "Sahura Kalan",
            IFTAR_TITLE_KEY to "İftara Kalan",
            UNTIL_TITLE_KEY to "Ramazan'a Kalan Gün",
            DAY_TEXT_KEY to "Ramazan · %d. gün",
        )

        private fun text(data: SharedPreferences, key: String): String {
            val value = data.getString(key, null)
            return if (value.isNullOrEmpty()) DEFAULT_TEXTS[key] ?: "" else value
        }

        /**
         * [now] anındaki durum: önce yazılan Ramazan, bittiyse (son iftar geçtiyse) sıradaki.
         * Vakitler PrayerWidgetData.today'den (gün dönmüşse yarının seti, sonraki imsak).
         */
        fun state(data: SharedPreferences, now: Calendar): State {
            if (!PrayerWidgetData.hasTimes(data)) return State(Mode.NONE)
            val day = PrayerWidgetData.today(data, now)
            val imsak = PrayerWidgetData.timeMs(day.times[0], 0, now)
            val aksam = PrayerWidgetData.timeMs(day.times[4], 0, now)
            val nextImsak = PrayerWidgetData.timeMs(day.nextImsak, 1, now)
            val today = PrayerWidgetData.epochDay(PrayerWidgetData.dateKey(now))
            if (imsak == 0L || aksam == 0L || nextImsak == 0L || today == null) return State(Mode.NONE)
            val midnight = PrayerWidgetData.timeMs("00:00", 1, now)
            val nowMs = now.timeInMillis
            // En az 1 sn sonra (PrayerWidgetData.nextPrayer ile aynı sınır)
            fun ahead(time: Long) = time > nowMs + 1000L

            // [start]..[end] Ramazan'ı; bitmişse null
            fun of(start: Long?, end: Long?, startText: String): State? {
                if (start == null) return null
                if (today < start) {
                    val eve = today == start - 1
                    // Arefe akşamı ilk sahur
                    if (eve && !ahead(aksam)) {
                        return State(Mode.SAHUR, nextImsak, day.nextImsak, 1, switchAt = nextImsak)
                    }
                    return State(
                        Mode.UNTIL, day = (start - today).toInt(), startText = startText,
                        switchAt = if (eve) aksam else midnight,
                    )
                }
                if (end == null || today > end) return null
                val n = (today - start + 1).toInt()
                return when {
                    ahead(imsak) -> State(Mode.SAHUR, imsak, day.times[0], n, switchAt = imsak)
                    ahead(aksam) -> State(Mode.IFTAR, aksam, day.times[4], n, switchAt = aksam)
                    // Akşamdan sonra yarının sahuru (yarının oruç günü)
                    today < end -> State(Mode.SAHUR, nextImsak, day.nextImsak, n + 1, switchAt = nextImsak)
                    else -> null
                }
            }

            return of(
                PrayerWidgetData.epochDay(data.getString(START_KEY, null)),
                PrayerWidgetData.epochDay(data.getString(END_KEY, null)),
                text(data, START_TEXT_KEY),
            ) ?: of(
                PrayerWidgetData.epochDay(data.getString(NEXT_START_KEY, null)),
                null,
                text(data, NEXT_START_TEXT_KEY),
            ) ?: State(Mode.NONE)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val now = Calendar.getInstance()
        val currentTime = now.timeInMillis
        val state = state(widgetData, now)
        // İmsak / akşam / gece yarısı gelince kendini yeniler (bu türdeki tüm widget'lar için tek alarm)
        if (state.switchAt > 0L) {
            PrayerWidgetData.scheduleWidgetUpdate(context, VaktindeWidgetRamadanProvider::class.java, state.switchAt)
        }
        val counting = state.mode == Mode.SAHUR || state.mode == Mode.IFTAR

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.vaktinde_widget_ramadan).apply {
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                setViewVisibility(R.id.tv_ramadan_day, if (counting) View.VISIBLE else View.GONE)
                setViewVisibility(R.id.chronometer_ramadan, if (counting) View.VISIBLE else View.GONE)
                setViewVisibility(R.id.tv_ramadan_days_left, if (counting) View.GONE else View.VISIBLE)
                setViewVisibility(R.id.tv_ramadan_time, if (state.mode == Mode.NONE) View.GONE else View.VISIBLE)

                if (counting) {
                    val sahur = state.mode == Mode.SAHUR
                    // "Ramazan · 12. gün", "İftara Kalan" + sayaç, "Akşam 19:05"
                    setTextViewText(R.id.tv_ramadan_day, text(widgetData, DAY_TEXT_KEY).replace("%d", state.day.toString()))
                    setTextViewText(R.id.tv_ramadan_title, text(widgetData, if (sahur) SAHUR_TITLE_KEY else IFTAR_TITLE_KEY))
                    setTextViewText(R.id.tv_ramadan_time, PrayerWidgetData.label(widgetData, if (sahur) 0 else 4) + " " + state.targetText)

                    val baseTime = SystemClock.elapsedRealtime() + (state.target - currentTime)
                    setChronometer(R.id.chronometer_ramadan, baseTime, null, true)
                    setBoolean(R.id.chronometer_ramadan, "setCountDown", true)
                } else {
                    // "Ramazan'a Kalan Gün", 121, "8 Şubat 2027" (veri yoksa "--")
                    setTextViewText(R.id.tv_ramadan_title, text(widgetData, UNTIL_TITLE_KEY))
                    setTextViewText(R.id.tv_ramadan_days_left, if (state.mode == Mode.UNTIL) state.day.toString() else "--")
                    setTextViewText(R.id.tv_ramadan_time, state.startText)

                    setChronometer(R.id.chronometer_ramadan, SystemClock.elapsedRealtime(), null, false)
                    setBoolean(R.id.chronometer_ramadan, "setCountDown", true)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
        // Alarm gelmezse WidgetRefresher bu kayda (değişim anı + gün) bakıp yeniden çizer
        WidgetRefresher.markWidgetsDrawn(context, VaktindeWidgetRamadanProvider::class.java, appWidgetIds, state.switchAt, now)
    }

    // Saat / saat dilimi değişince sayaç hemen yeniden kurulur
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (PrayerWidgetData.isTimeChange(intent.action)) PrayerWidgetData.redrawAll(context, this)
    }

    // Bu türün son widget'ı kaldırıldı: kendi güncelleme alarmı iptal
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        PrayerWidgetData.cancelWidgetUpdate(context, VaktindeWidgetRamadanProvider::class.java)
    }
}
