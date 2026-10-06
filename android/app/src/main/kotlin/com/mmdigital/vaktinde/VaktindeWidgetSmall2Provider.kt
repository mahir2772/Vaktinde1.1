package com.mmdigital.vaktinde

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import kotlin.math.abs

class VaktindeWidgetSmall2Provider : HomeWidgetProvider() {

    private fun getPrayerTimeMs(timeStr: String?, addDay: Boolean = false): Long {
        if (timeStr.isNullOrEmpty() || !timeStr.contains(":")) return 0L
        try {
            val parts = timeStr.split(":")
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, parts[0].toInt())
            calendar.set(Calendar.MINUTE, parts[1].toInt())
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            if (addDay) calendar.add(Calendar.DAY_OF_YEAR, 1)
            return calendar.timeInMillis
        } catch (e: Exception) { return 0L }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.vaktinde_widget_small2).apply {
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                setTextViewText(R.id.widget_location, widgetData.getString("location_text", ""))
                setTextViewText(R.id.widget_hijri_date, widgetData.getString("hijri_date_text", ""))

                val currentTime = System.currentTimeMillis()
                
                val times = listOf(
                    Pair(getPrayerTimeMs(widgetData.getString("imsak_time", "")), widgetData.getString("label_imsak", "İmsak")),
                    Pair(getPrayerTimeMs(widgetData.getString("gunes_time", "")), widgetData.getString("label_gunes", "Güneş")),
                    Pair(getPrayerTimeMs(widgetData.getString("ogle_time", "")), widgetData.getString("label_ogle", "Öğle")),
                    Pair(getPrayerTimeMs(widgetData.getString("ikindi_time", "")), widgetData.getString("label_ikindi", "İkindi")),
                    Pair(getPrayerTimeMs(widgetData.getString("aksam_time", "")), widgetData.getString("label_aksam", "Akşam")),
                    Pair(getPrayerTimeMs(widgetData.getString("yatsi_time", "")), widgetData.getString("label_yatsi", "Yatsı")),
                    Pair(getPrayerTimeMs(widgetData.getString("imsak_time", ""), true), widgetData.getString("label_imsak", "İmsak"))
                )

                val nextPrayer = times.filter { it.first > currentTime + 1000L }.minByOrNull { it.first }

                if (nextPrayer != null && nextPrayer.first > 0L) {
                    val targetTime = nextPrayer.first
                    val prayerName = nextPrayer.second ?: ""

                    val dartTargetTime = widgetData.getLong("target_time_ms", 0L)
                    if (abs(dartTargetTime - targetTime) < 60000) { 
                        setTextViewText(R.id.widget_next_prayer_name, widgetData.getString("title_text", ""))
                    } else {
                        setTextViewText(R.id.widget_next_prayer_name, prayerName)
                    }

                    val baseTime = SystemClock.elapsedRealtime() + (targetTime - currentTime)
                    setChronometer(R.id.widget_countdown, baseTime, null, true)
                    setBoolean(R.id.widget_countdown, "setCountDown", true)

                    scheduleExactUpdate(context, widgetId, targetTime, VaktindeWidgetSmall2Provider::class.java)
                } else {
                    setChronometer(R.id.widget_countdown, SystemClock.elapsedRealtime(), null, false)
                    setBoolean(R.id.widget_countdown, "setCountDown", true)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun scheduleExactUpdate(context: Context, widgetId: Int, targetTime: Long, providerClass: Class<*>) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, providerClass).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(widgetId))
            }
            val pendingIntent = PendingIntent.getBroadcast(context, widgetId, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, targetTime, pendingIntent)
                } else {
                    val alarmClockInfo = AlarmManager.AlarmClockInfo(targetTime, pendingIntent)
                    alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, targetTime, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, targetTime, pendingIntent)
            }
        } catch (e: SecurityException) {
            e.printStackTrace()
        } catch (e: Exception) { 
            e.printStackTrace() 
        }
    }
}