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
import kotlin.math.abs

class VaktindeWidgetSmall2Provider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val now = Calendar.getInstance()
        val currentTime = now.timeInMillis
        // Gün dönmüşse yarının seti, yatsıdan sonra yarının imsakı
        val day = PrayerWidgetData.today(widgetData, now)
        val nextPrayer = PrayerWidgetData.nextPrayer(widgetData, day, now)
        // Vakit gelince kendini yeniler (bu türdeki tüm widget'lar için tek alarm)
        if (nextPrayer != null && nextPrayer.first > 0L) {
            PrayerWidgetData.scheduleWidgetUpdate(context, VaktindeWidgetSmall2Provider::class.java, nextPrayer.first)
        }

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.vaktinde_widget_small2).apply {
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                setTextViewText(R.id.widget_location, widgetData.getString("location_text", ""))
                setTextViewText(R.id.widget_hijri_date, PrayerWidgetData.hijriText(widgetData, day))

                if (nextPrayer != null && nextPrayer.first > 0L) {
                    val targetTime = nextPrayer.first
                    val prayerName = nextPrayer.second

                    val dartTargetTime = widgetData.getLong("target_time_ms", 0L)
                    if (abs(dartTargetTime - targetTime) < 60000) {
                        setTextViewText(R.id.widget_next_prayer_name, widgetData.getString("title_text", ""))
                    } else {
                        setTextViewText(R.id.widget_next_prayer_name, prayerName)
                    }

                    val baseTime = SystemClock.elapsedRealtime() + (targetTime - currentTime)
                    setChronometer(R.id.widget_countdown, baseTime, null, true)
                    setBoolean(R.id.widget_countdown, "setCountDown", true)
                } else {
                    setChronometer(R.id.widget_countdown, SystemClock.elapsedRealtime(), null, false)
                    setBoolean(R.id.widget_countdown, "setCountDown", true)
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
        PrayerWidgetData.cancelWidgetUpdate(context, VaktindeWidgetSmall2Provider::class.java)
    }
}
