package com.mmdigital.vaktinde

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import java.util.Calendar

class NotificationUpdater : BroadcastReceiver() {

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

    override fun onReceive(context: Context, intent: Intent) {
        // Notification.Builder(context, kanal) API 26+ ister; eski sürümde servisin kendi bildirimi kalır
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        try {
            // Dart'ın sisteme kaydettiği verileri okuyoruz
            val widgetData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            
            // 2. adımda hazırladığımız o şık XML tasarımını belleğe alıyoruz
            val views = RemoteViews(context.packageName, R.layout.custom_notification)
            
            views.setTextViewText(R.id.notif_location, widgetData.getString("location_text", ""))
            views.setTextViewText(R.id.notif_hijri_date, widgetData.getString("hijri_date_text", ""))
            
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
                if (kotlin.math.abs(dartTargetTime - targetTime) < 60000) { 
                    views.setTextViewText(R.id.notif_next_prayer_name, widgetData.getString("title_text", ""))
                } else {
                    views.setTextViewText(R.id.notif_next_prayer_name, prayerName)
                }

                // Native Sayacı (Chronometer) başlatıyoruz
                val baseTime = SystemClock.elapsedRealtime() + (targetTime - currentTime)
                views.setChronometer(R.id.notif_countdown, baseTime, null, true)

                // Vakit gelince bildirim kendini yeniler (uygulama açılmasa da sayaç eksiye düşmez)
                scheduleNextUpdate(context, targetTime)
            } else {
                views.setChronometer(R.id.notif_countdown, SystemClock.elapsedRealtime(), null, false)
            }

            // Bildirime tıklanınca uygulamayı açacak intent
            val launchIntent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(context, 0, launchIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Background Service'in kullandığı 888 ID'sini ezerek kendi profesyonel XML tasarımımızı basıyoruz
            val builder = android.app.Notification.Builder(context, "vaktinde_sticky_channel")
                .setSmallIcon(R.mipmap.launcher_icon)
                .setStyle(android.app.Notification.DecoratedCustomViewStyle())
                .setCustomContentView(views)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setContentIntent(pendingIntent)
            
            notificationManager.notify(888, builder.build())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // Widget sağlayıcılarındaki scheduleExactUpdate ile aynı mantık; sabit requestCode ile tek alarm
    private fun scheduleNextUpdate(context: Context, targetTime: Long) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, NotificationUpdater::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            }
            val pendingIntent = PendingIntent.getBroadcast(context, 888, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
                val alarmClockInfo = AlarmManager.AlarmClockInfo(targetTime, pendingIntent)
                alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
            } else {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, targetTime, pendingIntent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}