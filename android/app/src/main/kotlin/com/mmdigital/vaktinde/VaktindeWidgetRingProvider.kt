package com.mmdigital.vaktinde

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.util.TypedValue
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar

/**
 * Vakit halkası (2x2): önceki vakitten sıradaki vakte geçen sürenin oranı halka (ProgressBar +
 * widget_ring), ortada sıradaki vaktin adı, sayaç ve saati. Vakitler diğer widget'larla ortak
 * (PrayerWidgetData: Güneş dahil, yatsıdan sonra yarının imsakı). Vakit gelince yenileme alarmı
 * halkayı sıfırlar ve sayacı sıradakine kurar. Arada halka [STEPS] adımda ilerler: kayıtlı hedef
 * sonraki adım olduğundan WidgetRefresher (dakika tıkı, ekran / kilit açılışı, onarım işi) adım
 * geçince yeniden çizer; dakikalık doğruluk gerekmez.
 */
class VaktindeWidgetRingProvider : HomeWidgetProvider() {

    /**
     * Çizilecek durum. [next]: sıradaki vakit (veri yoksa null), [timeText]: onun ekrandaki saati
     * (uygulama dilinde), [progress]: geçen süre 0..[MAX], [redrawAt]: halkanın sonraki adımı (en
     * geç sıradaki vakit; veri yoksa 0)
     */
    class State(
        val next: PrayerWidgetData.NextPrayer?,
        val timeText: String = "",
        val progress: Int = 0,
        val redrawAt: Long = 0L,
    )

    companion object {
        const val MAX = 1000

        /** Vakitler arası adım sayısı (6°): 90 dk'lık arada ~1,5 dk, 8 saatlikte 8 dk'da bir */
        const val STEPS = 60

        // Düzendeki kenar payı; ad ve saatin genişliği halka çapının 0,6'sı (iç çap 0,83, metin
        // satırları merkezin üstünde / altında: daha dar kiriş)
        private const val PADDING_DP = 6
        private const val TEXT_RATIO = 0.6f
        private const val MIN_RING_DP = 72

        fun state(data: SharedPreferences, now: Calendar): State {
            val day = PrayerWidgetData.today(data, now)
            val next = PrayerWidgetData.nextPrayer(data, day, now)
            if (next == null || next.time <= 0L) return State(null)
            val nowMs = now.timeInMillis
            val timeText = if (next.time == PrayerWidgetData.timeMs(day.times[next.index], 0, now)) {
                day.texts[next.index]
            } else {
                day.nextImsakText
            }
            // Önceki vakit: sıradakinden önceki en geç vakit (nextPrayer'ın 1 sn payıyla); imsaktan
            // önce dünün yatsısı (dünün seti yok: bugünkü saati, dün)
            val previous = (day.times.map { PrayerWidgetData.timeMs(it, 0, now) } +
                PrayerWidgetData.timeMs(day.times[5], -1, now))
                .filter { it in 1..nowMs + 1000L }
                .maxOrNull() ?: return State(next, timeText, 0, next.time)
            val span = next.time - previous
            val elapsed = (nowMs - previous).coerceIn(0L, span)
            val step = elapsed * STEPS / span
            return State(
                next, timeText,
                (elapsed * MAX / span).toInt(),
                minOf(previous + (step + 1) * span / STEPS, next.time),
            )
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val now = Calendar.getInstance()
        val currentTime = now.timeInMillis
        val state = state(widgetData, now)
        val next = state.next
        // Vakit gelince kendini yeniler: halka sıfırlanır (bu türdeki tüm widget'lar için tek alarm)
        if (next != null) {
            PrayerWidgetData.scheduleWidgetUpdate(context, VaktindeWidgetRingProvider::class.java, next.time)
        }

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.vaktinde_widget_ring).apply {
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                setProgressBar(R.id.ring_progress, MAX, state.progress, false)
                if (next != null) {
                    // "İkindi", sayaç, "16:04" (en: "4:04 PM")
                    setTextViewText(R.id.tv_ring_name, next.label)
                    setTextViewText(R.id.tv_ring_time, PrayerWidgetData.styledTime(state.timeText))

                    val baseTime = SystemClock.elapsedRealtime() + (next.time - currentTime)
                    setChronometer(R.id.chronometer_ring, baseTime, null, true)
                    setBoolean(R.id.chronometer_ring, "setCountDown", true)
                } else {
                    // Vakit yok: yer tutucu ad / saat gösterilmez
                    setTextViewText(R.id.tv_ring_name, "")
                    setTextViewText(R.id.tv_ring_time, "")
                    setChronometer(R.id.chronometer_ring, SystemClock.elapsedRealtime(), null, false)
                    setBoolean(R.id.chronometer_ring, "setCountDown", true)
                }
                fitToWidget(this, appWidgetManager, widgetId)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
        // Alarm / adım çizimi gelmezse WidgetRefresher bu kayda (sonraki adım + gün) bakıp yeniden çizer
        WidgetRefresher.markWidgetsDrawn(context, VaktindeWidgetRingProvider::class.java, appWidgetIds, state.redrawAt, now)
    }

    /**
     * Android 12+: halka widget'ın iki yöndeki en kısa kenarına sığar (büyütülünce büyür), ortadaki
     * metin halkanın içinde kalır. Boyut bilinmiyorsa ve eski sürümlerde düzenin 100dp'si.
     */
    private fun fitToWidget(views: RemoteViews, manager: AppWidgetManager, widgetId: Int) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        val options = manager.getAppWidgetOptions(widgetId) ?: return
        val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
        if (width <= 0 || height <= 0) return
        val side = maxOf(minOf(width, height) - 2 * PADDING_DP, MIN_RING_DP).toFloat()
        views.setViewLayoutWidth(R.id.ring_progress, side, TypedValue.COMPLEX_UNIT_DIP)
        views.setViewLayoutHeight(R.id.ring_progress, side, TypedValue.COMPLEX_UNIT_DIP)
        views.setViewLayoutWidth(R.id.tv_ring_name, side * TEXT_RATIO, TypedValue.COMPLEX_UNIT_DIP)
        views.setViewLayoutWidth(R.id.tv_ring_time, side * TEXT_RATIO, TypedValue.COMPLEX_UNIT_DIP)
    }

    // Boyut değişti (Android 12+): halka yeni boyuta göre
    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) onUpdate(context, appWidgetManager, intArrayOf(appWidgetId))
    }

    // Saat / saat dilimi değişince sayaç hemen yeniden kurulur
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (PrayerWidgetData.isTimeChange(intent.action)) PrayerWidgetData.redrawAll(context, this)
    }

    // Bu türün son widget'ı kaldırıldı: kendi güncelleme alarmı iptal
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        PrayerWidgetData.cancelWidgetUpdate(context, VaktindeWidgetRingProvider::class.java)
    }
}
