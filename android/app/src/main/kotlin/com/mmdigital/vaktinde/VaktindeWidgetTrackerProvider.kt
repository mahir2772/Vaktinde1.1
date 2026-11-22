package com.mmdigital.vaktinde

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar

/**
 * Namaz takibi widget'ı (4x1): bugünün beş farz vakti (sabah…yatsı) kılındı / kılınmadı / vakti
 * girmedi / özel gün. Kayıt uygulamada (Dart PrayerTrackerService); Dart günün işaret maskesini,
 * özel günleri (açık dönemin sonraki günleri dahil) ve metinleri yazar (TrackerWidgetService).
 * Vakti girmiş hücreye dokununca home_widget arka plan geri çağrısı uygulama açılmadan işareti
 * değiştirir ve widget'ı yeniden çizdirir; vakti girmemiş ve özel gün hücreleri pasif. Maske
 * sadece yazıldığı gün geçerli: gece yarısı (yenileme alarmı / WidgetRefresher) Dart beklenmeden
 * sıfırlanır. Vakitler diğer widget'larla ortak (PrayerWidgetData).
 */
class VaktindeWidgetTrackerProvider : VaktindeWidgetProvider() {

    enum class Cell { PRAYED, OPEN, NOT_DUE, EXCUSED }

    /** [cells] sabah…yatsı; [prayed]: kılınan sayısı; [switchAt]: sıradaki farz vakti ya da gece yarısı */
    class State(val date: String, val cells: List<Cell>, val excused: Boolean, val prayed: Int, val switchAt: Long)

    companion object {
        // Dart: TrackerWidgetService.data
        private const val DATE_KEY = "tracker_date"
        private const val MASK_KEY = "tracker_mask"
        private const val EXCUSED_KEY = "tracker_excused_days" // virgüllü yyyy-MM-dd
        private const val TITLE_KEY = "tracker_title"
        private const val LABELS_KEY = "tracker_labels" // sabah…yatsı, satır satır
        private const val STATES_KEY = "tracker_states" // Cell sırasıyla durum sözleri, satır satır
        private const val CELL_TEXT_KEY = "tracker_cell_text" // "Bugün, %1$s: %2$s"

        // Hücre i: Dart PrayerTracker.prayerKeys[i] (maskenin i. biti); PrayerWidgetData vakit sırası
        private val PRAYERS = intArrayOf(0, 2, 3, 4, 5)
        private val DEFAULT_LABELS = intArrayOf(
            R.string.vaktinde_widget_sabah, R.string.vaktinde_widget_ogle, R.string.vaktinde_widget_ikindi,
            R.string.vaktinde_widget_aksam, R.string.vaktinde_widget_yatsi,
        )
        private val CELL_IDS = intArrayOf(
            R.id.tracker_cell_0, R.id.tracker_cell_1, R.id.tracker_cell_2, R.id.tracker_cell_3, R.id.tracker_cell_4,
        )
        private val CELL_DRAWABLES = mapOf(
            Cell.PRAYED to R.drawable.widget_cell_prayed,
            Cell.OPEN to R.drawable.widget_cell_open,
            Cell.NOT_DUE to R.drawable.widget_cell_pending,
            Cell.EXCUSED to R.drawable.widget_cell_excused,
        )
        private const val TEXT_COLOR = 0xFFFFFFFF.toInt()
        private const val PASSIVE_TEXT_COLOR = 0xB3FFFFFF.toInt()

        /** Hücre dokunuşunun adresi (Dart TrackerWidgetService.parseTap) */
        fun tapUri(date: String, cell: Int): Uri = Uri.parse("vaktinde://tracker/toggle?date=$date&prayer=$cell")

        fun state(data: SharedPreferences, now: Calendar): State {
            val date = PrayerWidgetData.dateKey(now)
            val mask = if (data.getString(DATE_KEY, null) == date) (data.all[MASK_KEY] as? Number)?.toInt() ?: 0 else 0
            val excused = data.getString(EXCUSED_KEY, null)?.split(",")?.contains(date) == true
            val day = PrayerWidgetData.today(data, now)
            val nowMs = now.timeInMillis
            // Vakti giren hücre açılır (sıradaki vakitle aynı 1 sn payı); vakit yoksa (0) hiçbiri
            val times = PRAYERS.map { PrayerWidgetData.timeMs(day.times[it], 0, now) }
            val cells = times.mapIndexed { i, time ->
                when {
                    excused -> Cell.EXCUSED
                    (mask and (1 shl i)) != 0 -> Cell.PRAYED
                    time in 1..nowMs + 1000L -> Cell.OPEN
                    else -> Cell.NOT_DUE
                }
            }
            val midnight = PrayerWidgetData.timeMs("00:00", 1, now)
            val switchAt = times.filter { it > nowMs + 1000L }.fold(midnight) { a, b -> minOf(a, b) }
            return State(date, cells, excused, Integer.bitCount(mask and 31), switchAt)
        }

        private fun text(data: SharedPreferences, key: String): String? = data.getString(key, null)?.takeIf { it.isNotEmpty() }

        private fun lines(data: SharedPreferences, key: String, count: Int): List<String>? =
            text(data, key)?.split("\n")?.takeIf { it.size == count }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val now = Calendar.getInstance()
        val state = state(widgetData, now)
        // Sıradaki farz vaktinde hücre açılır, gece yarısı gün sıfırlanır (bu türdeki tüm widget'lar için tek alarm)
        PrayerWidgetData.scheduleWidgetUpdate(context, VaktindeWidgetTrackerProvider::class.java, state.switchAt)

        val openApp = PendingIntent.getActivity(
            context, 0, Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        // Dart geri çağrısı kayıtlı değilse (güncellemeden sonra uygulama hiç açılmadı) dokunuş uygulamayı açar
        val interactive = HomeWidgetPlugin.getHandle(context) != 0L
        val labels = lines(widgetData, LABELS_KEY, CELL_IDS.size) ?: DEFAULT_LABELS.map { context.getString(it) }
        val states = lines(widgetData, STATES_KEY, Cell.entries.size)
        val cellText = text(widgetData, CELL_TEXT_KEY)
        val clicks = state.cells.mapIndexed { i, cell ->
            when {
                cell != Cell.PRAYED && cell != Cell.OPEN -> null
                interactive -> HomeWidgetBackgroundIntent.getBroadcast(context, tapUri(state.date, i))
                else -> openApp
            }
        }

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.vaktinde_widget_tracker).apply {
                setOnClickPendingIntent(R.id.tracker_header, openApp)
                setTextViewText(R.id.tv_tracker_title, text(widgetData, TITLE_KEY) ?: context.getString(R.string.vaktinde_widget_today))
                // "2/5"; özel günde sayı yerine "Özel gün" (sayılmaz)
                setTextViewText(
                    R.id.tv_tracker_count,
                    if (state.excused) states?.get(Cell.EXCUSED.ordinal) ?: "" else "${state.prayed}/${CELL_IDS.size}",
                )
                state.cells.forEachIndexed { i, cell ->
                    val id = CELL_IDS[i]
                    setTextViewText(id, labels[i])
                    setTextColor(id, if (clicks[i] != null) TEXT_COLOR else PASSIVE_TEXT_COLOR)
                    setTextViewCompoundDrawables(id, 0, CELL_DRAWABLES.getValue(cell), 0, 0)
                    // Ekran okuyucu: "Bugün, Öğle: Kılındı" (durum sözle); metin yoksa ad okunur
                    setContentDescription(
                        id,
                        if (cellText == null || states == null) null
                        else cellText.replace("%1\$s", labels[i]).replace("%2\$s", states[cell.ordinal]),
                    )
                    // Aynı düzen yeniden uygulanır: pasifleşen hücrenin önceki tıklaması da kalkar
                    setOnClickPendingIntent(id, clicks[i])
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
        // Alarm gelmezse WidgetRefresher bu kayda (değişim anı + gün) bakıp yeniden çizer
        WidgetRefresher.markWidgetsDrawn(context, VaktindeWidgetTrackerProvider::class.java, appWidgetIds, state.switchAt, now)
    }

    // Saat / saat dilimi değişince hücreler ve gün hemen yeniden hesaplanır
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (PrayerWidgetData.isTimeChange(intent.action)) PrayerWidgetData.redrawAll(context, this)
    }

    // Bu türün son widget'ı kaldırıldı: kendi güncelleme alarmı iptal
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        PrayerWidgetData.cancelWidgetUpdate(context, VaktindeWidgetTrackerProvider::class.java)
    }
}
