package com.mmdigital.vaktinde

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class VaktindeWidgetSmallProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.vaktinde_widget_small).apply {
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                setTextViewText(R.id.tv_title_small, widgetData.getString("title_text", ""))

                val targetTime = widgetData.getLong("target_time_ms", 0L)
                if (targetTime > 0L) {
                    val baseTime = SystemClock.elapsedRealtime() + (targetTime - System.currentTimeMillis())
                    setChronometer(R.id.chronometer_small, baseTime, null, true)
                    setBoolean(R.id.chronometer_small, "setCountDown", true)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}