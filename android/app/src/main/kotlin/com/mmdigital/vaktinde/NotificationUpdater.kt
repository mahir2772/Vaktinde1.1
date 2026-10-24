package com.mmdigital.vaktinde

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Typeface
import android.os.Build
import android.os.SystemClock
import android.text.SpannableString
import android.text.Spanned
import android.text.style.StyleSpan
import android.view.View
import android.widget.RemoteViews
import java.util.Calendar

class NotificationUpdater : BroadcastReceiver() {

    companion object {
        /** Vakitten sonra bildirimin kaldırılmasına kadar pay: zamanında gelen alarm önce yeniler */
        const val TIMEOUT_GRACE_MS = 5_000L

        /** Güncellemeden sonra ikinci çizim: sistem ilk anlarda bildirimi çizemeyip düşürürse geri gelir */
        private const val AFTER_UPDATE_REDRAW_MS = 60_000L

        // Altı vakit sütunu (0 imsak … 5 yatsı): ad ve saat
        private val LABEL_IDS = intArrayOf(
            R.id.notif_label_0, R.id.notif_label_1, R.id.notif_label_2,
            R.id.notif_label_3, R.id.notif_label_4, R.id.notif_label_5,
        )
        private val TIME_IDS = intArrayOf(
            R.id.notif_time_0, R.id.notif_time_1, R.id.notif_time_2,
            R.id.notif_time_3, R.id.notif_time_4, R.id.notif_time_5,
        )

        /** Sıradaki vaktin adı ve saati kalın (yazı stili sistemin; RemoteViews yazı tipi alamaz) */
        private fun emphasized(text: CharSequence, bold: Boolean): CharSequence =
            if (!bold || text.isEmpty()) text
            else SpannableString(text).apply {
                setSpan(StyleSpan(Typeface.BOLD), 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            }
    }

    override fun onReceive(context: Context, intent: Intent) {
        // Notification.Builder(context, kanal) API 26+ ister (7.x'te kalıcı bildirim yok)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        PrayerWidgetData.noteRefreshDelay(context, intent)
        try {
            // Dart'ın sisteme kaydettiği verileri okuyoruz
            val widgetData = context.getSharedPreferences(PrayerWidgetData.PREFS, Context.MODE_PRIVATE)

            // Kalıcı bildirim kapalı (Ayarlar): çizilmez; kalmış bildirim ve yenileme alarmı kaldırılır
            if (!PrayerWidgetData.persistentNotificationEnabled(widgetData)) {
                remove(context)
                return
            }

            // Uygulama henüz vakit yazmadıysa boş bildirim çıkarılmaz
            if (!PrayerWidgetData.hasTimes(widgetData)) return

            val views = RemoteViews(context.packageName, R.layout.custom_notification)

            val now = Calendar.getInstance()
            // Gün dönmüşse yarının seti, yatsıdan sonra yarının imsakı
            val day = PrayerWidgetData.today(widgetData, now)

            // Konum · hicri tarih (biri yoksa diğeri)
            val place = listOf(widgetData.getString("location_text", "") ?: "", PrayerWidgetData.hijriText(widgetData, day))
                .filter { it.isNotBlank() }
            views.setTextViewText(R.id.notif_location, place.joinToString(" · "))

            val currentTime = now.timeInMillis
            val nextPrayer = PrayerWidgetData.nextPrayer(widgetData, day, now)

            // Günün altı vakti; sıradaki kalın. Yatsıdan sonra sıradaki yarının imsakı: o sütunda onun saati
            val nextIndex = if (nextPrayer != null && nextPrayer.time > 0L) nextPrayer.index else -1
            val texts = day.texts.toMutableList()
            if (nextIndex == 0 && PrayerWidgetData.timeMs(day.times[0], 0, now) <= currentTime) {
                texts[0] = day.nextImsakText
            }
            for (i in 0 until minOf(texts.size, TIME_IDS.size)) {
                views.setTextViewText(LABEL_IDS[i], emphasized(PrayerWidgetData.label(widgetData, i), i == nextIndex))
                views.setTextViewText(TIME_IDS[i], emphasized(PrayerWidgetData.styledTime(texts[i]), i == nextIndex))
            }

            if (nextPrayer != null && nextPrayer.time > 0L) {
                val targetTime = nextPrayer.time

                // "İkindiye" (title_<vakit>; yoksa title_text / vakit adı)
                views.setTextViewText(R.id.notif_next_prayer_name, PrayerWidgetData.title(widgetData, nextPrayer))

                // Native Sayacı (Chronometer) başlatıyoruz
                val baseTime = SystemClock.elapsedRealtime() + (targetTime - currentTime)
                views.setChronometer(R.id.notif_countdown, baseTime, null, true)

                // Vakit gelince bildirim kendini yeniler (uygulama açılmasa da sayaç eksiye düşmez)
                scheduleNextUpdate(context, targetTime)
            } else {
                // Sıradaki vakit yok (geçersiz veri): yer tutucu ad ya da donmuş "00:00" gösterilmez
                views.setTextViewText(R.id.notif_next_prayer_name, "")
                views.setChronometer(R.id.notif_countdown, SystemClock.elapsedRealtime(), null, false)
                views.setViewVisibility(R.id.notif_countdown, View.GONE)
            }

            // Bildirime tıklanınca uygulamayı açacak intent
            val launchIntent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(context, 0, launchIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            val builder = android.app.Notification.Builder(context, "vaktinde_sticky_channel")
                .setSmallIcon(R.mipmap.launcher_icon)
                .setStyle(android.app.Notification.DecoratedCustomViewStyle())
                .setCustomContentView(views)
                // Açınca da aynı görünüm (kapalı hâl yükseklik sınırında kırpılırsa hepsi açıkta görünür)
                .setCustomBigContentView(views)
                .setShowWhen(false)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setContentIntent(pendingIntent)
            // Yenileme alarmı gelmezse (üretici güç yöneticisi geciktirdi) sayaç eksiye düşmesin: sistem
            // bildirimi vakitten hemen sonra kaldırır, ilk yenilemede (alarm, WidgetHealJobService, açılış)
            // geri gelir
            if (nextPrayer != null && nextPrayer.time > currentTime) {
                builder.setTimeoutAfter(nextPrayer.time - currentTime + TIMEOUT_GRACE_MS)
            }

            notificationManager.notify(888, builder.build())
            // Alarm gelmezse WidgetRefresher bu kayda bakıp yeniden çizer (888 açıksa)
            WidgetRefresher.markNotificationDrawn(context, nextPrayer?.time ?: 0L, now)
            if (intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
                scheduleNextUpdate(context, currentTime + AFTER_UPDATE_REDRAW_MS)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun updateIntent(context: Context, targetTime: Long = 0L): Intent =
        Intent(context, NotificationUpdater::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            if (targetTime > 0L) putExtra(PrayerWidgetData.EXTRA_TARGET, targetTime)
        }

    // Widget alarmlarıyla aynı kurulum (PrayerWidgetData.setRefreshAlarm); sabit requestCode ile tek alarm
    private fun scheduleNextUpdate(context: Context, targetTime: Long) {
        try {
            val pendingIntent = PendingIntent.getBroadcast(context, 888, updateIntent(context, targetTime), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            PrayerWidgetData.setRefreshAlarm(context, targetTime, pendingIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // Bildirim ve yenileme alarmı kaldırılır
    private fun remove(context: Context) {
        try {
            (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(888)
            val pendingIntent = PendingIntent.getBroadcast(
                context, 888, updateIntent(context), PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            ) ?: return
            (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pendingIntent)
            pendingIntent.cancel()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}