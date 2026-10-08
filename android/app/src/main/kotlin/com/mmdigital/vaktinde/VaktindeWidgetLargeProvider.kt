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

class VaktindeWidgetLargeProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val now = Calendar.getInstance()
        val currentTime = now.timeInMillis
        // Gün dönmüşse yarının seti, yatsıdan sonra yarının imsakı
        val day = PrayerWidgetData.today(widgetData, now)
        val nextPrayer = PrayerWidgetData.nextPrayer(widgetData, day, now)
        // Vakit gelince kendini yeniler (bu türdeki tüm widget'lar için tek alarm)
        if (nextPrayer != null && nextPrayer.first > 0L) {
            PrayerWidgetData.scheduleWidgetUpdate(context, VaktindeWidgetLargeProvider::class.java, nextPrayer.first)
        }

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.vaktinde_widget_large).apply {
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                setTextViewText(R.id.tv_label_imsak, widgetData.getString("label_imsak", ""))
                setTextViewText(R.id.tv_label_gunes, widgetData.getString("label_gunes", ""))
                setTextViewText(R.id.tv_label_ogle, widgetData.getString("label_ogle", ""))
                setTextViewText(R.id.tv_label_ikindi, widgetData.getString("label_ikindi", ""))
                setTextViewText(R.id.tv_label_aksam, widgetData.getString("label_aksam", ""))
                setTextViewText(R.id.tv_label_yatsi, widgetData.getString("label_yatsi", ""))

                setTextViewText(R.id.tv_location, widgetData.getString("location_text", ""))
                setTextViewText(R.id.tv_hijri_date, PrayerWidgetData.hijriText(widgetData, day))

                setTextViewText(R.id.tv_imsak_l, day.times[0])
                setTextViewText(R.id.tv_gunes_l, day.times[1])
                setTextViewText(R.id.tv_ogle_l, day.times[2])
                setTextViewText(R.id.tv_ikindi_l, day.times[3])
                setTextViewText(R.id.tv_aksam_l, day.times[4])
                setTextViewText(R.id.tv_yatsi_l, day.times[5])

                if (nextPrayer != null && nextPrayer.first > 0L) {
                    val baseTime = SystemClock.elapsedRealtime() + (nextPrayer.first - currentTime)
                    setChronometer(R.id.chronometer_large, baseTime, null, true)
                    setBoolean(R.id.chronometer_large, "setCountDown", true)
                } else {
                    setChronometer(R.id.chronometer_large, SystemClock.elapsedRealtime(), null, false)
                    setBoolean(R.id.chronometer_large, "setCountDown", true)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    // Saat / saat dilimi değişince sayaç hemen yeniden kurulur
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (PrayerWidgetData.isTimeChange(intent.action)) PrayerWidgetData.redrawAll(context, this)
    }

    // Bu türün son widget'ı kaldırıldı: kendi güncelleme alarmı iptal
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        PrayerWidgetData.cancelWidgetUpdate(context, VaktindeWidgetLargeProvider::class.java)
    }
}
