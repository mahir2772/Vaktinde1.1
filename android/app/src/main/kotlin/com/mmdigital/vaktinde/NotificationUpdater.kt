package com.mmdigital.vaktinde

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

    override fun onReceive(context: Context, intent: Intent) {
        // Notification.Builder(context, kanal) API 26+ ister; eski sürümde servisin kendi bildirimi kalır
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        try {
            // Dart'ın sisteme kaydettiği verileri okuyoruz
            val widgetData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

            // Saat değişimi: uygulama henüz vakit yazmadıysa boş bildirim çıkarılmaz
            if (PrayerWidgetData.isTimeChange(intent.action) && !PrayerWidgetData.hasTimes(widgetData)) return

            // 2. adımda hazırladığımız o şık XML tasarımını belleğe alıyoruz
            val views = RemoteViews(context.packageName, R.layout.custom_notification)

            val now = Calendar.getInstance()
            // Gün dönmüşse yarının seti, yatsıdan sonra yarının imsakı
            val day = PrayerWidgetData.today(widgetData, now)

            views.setTextViewText(R.id.notif_location, widgetData.getString("location_text", ""))
            views.setTextViewText(R.id.notif_hijri_date, PrayerWidgetData.hijriText(widgetData, day))

            val currentTime = now.timeInMillis
            val nextPrayer = PrayerWidgetData.nextPrayer(widgetData, day, now)

            if (nextPrayer != null && nextPrayer.first > 0L) {
                val targetTime = nextPrayer.first
                val prayerName = nextPrayer.second

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

    // Widget alarmlarıyla aynı kurulum (PrayerWidgetData.setRefreshAlarm); sabit requestCode ile tek alarm
    private fun scheduleNextUpdate(context: Context, targetTime: Long) {
        try {
            val intent = Intent(context, NotificationUpdater::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            }
            val pendingIntent = PendingIntent.getBroadcast(context, 888, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            PrayerWidgetData.setRefreshAlarm(context, targetTime, pendingIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}