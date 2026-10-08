package com.mmdigital.vaktinde

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar

class VaktindeWidgetSmallProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val now = Calendar.getInstance()
        val currentTime = now.timeInMillis
        // Gün dönmüşse yarının seti, yatsıdan sonra yarının imsakı
        val day = PrayerWidgetData.today(widgetData, now)
        val nextPrayer = PrayerWidgetData.nextPrayer(widgetData, day, now)
        // Vakit gelince kendini yeniler (bu türdeki tüm widget'lar için tek alarm)
        if (nextPrayer != null && nextPrayer.time > 0L) {
            PrayerWidgetData.scheduleWidgetUpdate(context, VaktindeWidgetSmallProvider::class.java, nextPrayer.time)
        }

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.vaktinde_widget_small).apply {
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                if (nextPrayer != null && nextPrayer.time > 0L) {
                    // "İkindiye" (title_<vakit>; yoksa title_text / vakit adı)
                    setTextViewText(R.id.tv_title_small, PrayerWidgetData.title(widgetData, nextPrayer))

                    val baseTime = SystemClock.elapsedRealtime() + (nextPrayer.time - currentTime)
                    setChronometer(R.id.chronometer_small, baseTime, null, true)
                    setBoolean(R.id.chronometer_small, "setCountDown", true)
                } else {
                    setChronometer(R.id.chronometer_small, SystemClock.elapsedRealtime(), null, false)
                    setBoolean(R.id.chronometer_small, "setCountDown", true)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
        // Alarm gelmezse WidgetRefresher bu kayda bakıp yeniden çizer
        WidgetRefresher.markWidgetsDrawn(context, VaktindeWidgetSmallProvider::class.java, appWidgetIds, nextPrayer?.time ?: 0L, now)
    }

    // Saat / saat dilimi değişince sayaç hemen yeniden kurulur
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (PrayerWidgetData.isTimeChange(intent.action)) PrayerWidgetData.redrawAll(context, this)
    }

    // Bu türün son widget'ı kaldırıldı: kendi güncelleme alarmı iptal
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        PrayerWidgetData.cancelWidgetUpdate(context, VaktindeWidgetSmallProvider::class.java)
    }
}
