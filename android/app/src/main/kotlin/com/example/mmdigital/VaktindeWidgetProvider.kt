package com.mmdigital.vaktinde // <-- Kendi paket adınla aynı olduğundan emin ol!

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class VaktindeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                
                // 1. Ana Başlık ve Kalan Süre
                setTextViewText(R.id.tv_title, widgetData.getString("title_text", "Vaktinde"))
                setTextViewText(R.id.tv_countdown, widgetData.getString("countdown_text", "--:--"))

                // 2. Alt Taraftaki Tüm Vakitler
                setTextViewText(R.id.tv_imsak, widgetData.getString("imsak_time", "--:--"))
                setTextViewText(R.id.tv_gunes, widgetData.getString("gunes_time", "--:--"))
                setTextViewText(R.id.tv_ogle, widgetData.getString("ogle_time", "--:--"))
                setTextViewText(R.id.tv_ikindi, widgetData.getString("ikindi_time", "--:--"))
                setTextViewText(R.id.tv_aksam, widgetData.getString("aksam_time", "--:--"))
                setTextViewText(R.id.tv_yatsi, widgetData.getString("yatsi_time", "--:--"))
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}