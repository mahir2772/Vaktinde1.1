package com.mmdigital.vaktinde

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class VaktindeWidgetLargeProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
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
                setTextViewText(R.id.tv_imsak_l, widgetData.getString("imsak_time", ""))
                setTextViewText(R.id.tv_gunes_l, widgetData.getString("gunes_time", ""))
                setTextViewText(R.id.tv_ogle_l, widgetData.getString("ogle_time", ""))
                setTextViewText(R.id.tv_ikindi_l, widgetData.getString("ikindi_time", ""))
                setTextViewText(R.id.tv_aksam_l, widgetData.getString("aksam_time", ""))
                setTextViewText(R.id.tv_yatsi_l, widgetData.getString("yatsi_time", ""))

                val targetTime = widgetData.getLong("target_time_ms", 0L)
                if (targetTime > 0L) {
                    val baseTime = SystemClock.elapsedRealtime() + (targetTime - System.currentTimeMillis())
                    setChronometer(R.id.chronometer_large, baseTime, null, true)
                    setBoolean(R.id.chronometer_large, "setCountDown", true)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}