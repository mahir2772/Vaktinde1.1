package com.mmdigital.vaktinde

import android.app.NotificationManager
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.Looper
import java.util.Calendar

/**
 * Vakti geçmiş sayaçların kendini onarması. Vakit anındaki yenileme alarmı bazı üreticilerin
 * güç yöneticilerinde (Honor vb.) geç gelir ya da hiç gelmez; RemoteViews Chronometer sıfırda
 * duramadığı için sayaç eksiye düşer ("İkindiye −17:08"). Her yüzey (4 widget türü + kalıcı
 * bildirim) çizdiği hedefi ve günü kaydeder; süreç başlayınca, ekran / kilit açılınca ve ekran
 * açıkken dakikada bir (TIME_TICK) hesaplanan hedefle karşılaştırılır, farklıysa sadece o yüzey
 * yeniden çizilir. Yenileme alarmları, updatePeriodMillis ve saat değişimi yayınları aynen kalır.
 * Application.onCreate'ten çağrılır: hiçbir yol fırlatmaz.
 */
object WidgetRefresher {
    private const val STATE_PREFS = "vaktinde_widget_state"
    private const val NOTIFICATION_ID = 888
    private val NOTIFICATION_SURFACE: String = NotificationUpdater::class.java.name

    // Kayıt anahtarı sağlayıcı sınıf adı; örnek sadece yeniden çizerken oluşturulur
    private val PROVIDERS: Map<Class<out AppWidgetProvider>, () -> AppWidgetProvider> = linkedMapOf(
        VaktindeWidgetSmallProvider::class.java to { VaktindeWidgetSmallProvider() },
        VaktindeWidgetSmall2Provider::class.java to { VaktindeWidgetSmall2Provider() },
        VaktindeWidgetLargeProvider::class.java to { VaktindeWidgetLargeProvider() },
        VaktindeWidgetRamadanProvider::class.java to { VaktindeWidgetRamadanProvider() },
    )

    /** Çizilen durum: hedef vakit (ms, veri yoksa 0) + gün (gece yarısı gün seti / hicri tarih de yenilenir) */
    data class Drawn(val target: Long, val day: String)

    private fun current(data: SharedPreferences, now: Calendar): Drawn {
        val next = PrayerWidgetData.nextPrayer(data, PrayerWidgetData.today(data, now), now)
        return Drawn(next?.time ?: 0L, PrayerWidgetData.dateKey(now))
    }

    /**
     * Sağlayıcının şu an çizmesi gereken durum. Ramazan widget'ının hedefi kendi değişim anı
     * (imsak, akşam ya da gece yarısı); bunlar sıradaki vaktin de değiştiği anlar olduğundan
     * Watcher'ın [current] karşılaştırması onu da kapsar.
     */
    private fun expected(providerClass: Class<*>, data: SharedPreferences, now: Calendar, current: Drawn): Drawn =
        if (providerClass == VaktindeWidgetRamadanProvider::class.java) {
            Drawn(VaktindeWidgetRamadanProvider.state(data, now).switchAt, current.day)
        } else {
            current
        }

    /**
     * Application.onCreate ([app] = Application): tek dinleyici + bir denetim (ana iş parçacığına
     * ertelenir, açılışı yavaşlatmaz)
     */
    fun register(app: Context) {
        try {
            val watcher = Watcher(app)
            try {
                val filter = IntentFilter().apply {
                    addAction(Intent.ACTION_TIME_TICK)
                    addAction(Intent.ACTION_SCREEN_ON)
                    addAction(Intent.ACTION_USER_PRESENT)
                }
                // Sistem yayınları dışa kapalı alıcıya da gelir; Android 13+ bayrak verilir
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    app.registerReceiver(watcher, filter, Context.RECEIVER_NOT_EXPORTED)
                } else {
                    app.registerReceiver(watcher, filter)
                }
            } catch (t: Throwable) {
                // Dinleyici olmasa da açılış denetimi yapılır
                t.printStackTrace()
            }
            Handler(Looper.getMainLooper()).post { watcher.check() }
        } catch (t: Throwable) {
            t.printStackTrace()
        }
    }

    /**
     * Kaydı [now] için hesaplanan durumdan farklı (ya da hiç olmayan) mevcut yüzeyleri yeniden
     * çizer: widget'ı olmayan türe ve açık olmayan bildirime dokunmaz. Hata olmadıysa true.
     */
    fun refreshStale(context: Context, now: Calendar = Calendar.getInstance()): Boolean = try {
        val data = context.getSharedPreferences(PrayerWidgetData.PREFS, Context.MODE_PRIVATE)
        redrawStale(context, data, current(data, now), now)
    } catch (t: Throwable) {
        t.printStackTrace()
        false
    }

    private fun redrawStale(context: Context, data: SharedPreferences, current: Drawn, now: Calendar): Boolean {
        var clean = true
        try {
            val state = context.getSharedPreferences(STATE_PREFS, Context.MODE_PRIVATE)
            for ((providerClass, create) in PROVIDERS) {
                try {
                    if (drawn(state, providerClass.name) == expected(providerClass, data, now, current)) continue
                    val manager = AppWidgetManager.getInstance(context) ?: continue
                    val ids = manager.getAppWidgetIds(ComponentName(context, providerClass))
                    if (ids != null && ids.isNotEmpty()) create().onUpdate(context, manager, ids)
                } catch (t: Throwable) {
                    clean = false
                    t.printStackTrace()
                }
            }
            // API 26 altında NotificationUpdater çizmez (servisin kendi bildirimi kalır); vakit
            // yazılmadıysa servisin yer tutucusu boş sayaçla ezilmez
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && PrayerWidgetData.hasTimes(data) &&
                drawn(state, NOTIFICATION_SURFACE) != current
            ) {
                try {
                    // 888 aynı zamanda ön plan servisinin bildirimi: açık değilse yeniden çıkarılmaz
                    if (isNotificationActive(context)) {
                        NotificationUpdater().onReceive(context, Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE))
                    }
                } catch (t: Throwable) {
                    clean = false
                    t.printStackTrace()
                }
            }
        } catch (t: Throwable) {
            clean = false
            t.printStackTrace()
        }
        return clean
    }

    /**
     * Widget türü çizildi (onUpdate sonu). Sadece türün tüm widget'ları çizildiyse kaydedilir:
     * yeni eklenen tek widget'ın çizimi bayat kalmış diğerlerini tazelenmiş saydırmaz.
     */
    fun markWidgetsDrawn(context: Context, providerClass: Class<*>, drawnIds: IntArray, target: Long, now: Calendar) {
        try {
            val manager = AppWidgetManager.getInstance(context) ?: return
            val all = manager.getAppWidgetIds(ComponentName(context, providerClass)) ?: return
            if (all.all { it in drawnIds }) save(context, providerClass.name, Drawn(target, PrayerWidgetData.dateKey(now)))
        } catch (t: Throwable) {
            t.printStackTrace()
        }
    }

    /** Kalıcı bildirim çizildi (NotificationUpdater) */
    fun markNotificationDrawn(context: Context, target: Long, now: Calendar) {
        try {
            save(context, NOTIFICATION_SURFACE, Drawn(target, PrayerWidgetData.dateKey(now)))
        } catch (t: Throwable) {
            t.printStackTrace()
        }
    }

    /** Yüzeyin son çizdiği durum; hiç çizilmediyse null. Yüzey: sağlayıcı ya da NotificationUpdater sınıf adı */
    fun drawn(context: Context, surface: String): Drawn? =
        drawn(context.getSharedPreferences(STATE_PREFS, Context.MODE_PRIVATE), surface)

    private fun drawn(state: SharedPreferences, surface: String): Drawn? {
        val day = state.getString("$surface.day", null) ?: return null
        return Drawn(state.getLong("$surface.target", 0L), day)
    }

    // Tek süreç (android:process yok): apply() aynı süreçte hemen görünür
    private fun save(context: Context, surface: String, drawn: Drawn) {
        context.getSharedPreferences(STATE_PREFS, Context.MODE_PRIVATE).edit()
            .putLong("$surface.target", drawn.target)
            .putString("$surface.day", drawn.day)
            .apply()
    }

    private fun isNotificationActive(context: Context): Boolean {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return false
        return manager.activeNotifications.any { it.id == NOTIFICATION_ID }
    }

    /**
     * TIME_TICK ekran açıkken dakikada bir gelir: hedef ve gün son temiz denetimdekiyle aynıysa
     * sistem çağrısı yapılmadan çıkılır (sadece vakit metinleri ayrıştırılıp karşılaştırılır).
     */
    private class Watcher(private val app: Context) : BroadcastReceiver() {
        private var lastClean: Drawn? = null

        override fun onReceive(context: Context, intent: Intent) = check()

        fun check() {
            try {
                val data = app.getSharedPreferences(PrayerWidgetData.PREFS, Context.MODE_PRIVATE)
                val now = Calendar.getInstance()
                val current = current(data, now)
                if (current == lastClean) return
                if (redrawStale(app, data, current, now)) lastClean = current
            } catch (t: Throwable) {
                t.printStackTrace()
            }
        }
    }
}
