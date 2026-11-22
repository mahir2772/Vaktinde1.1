package com.mmdigital.vaktinde

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings

/**
 * "Namazdayım" otomatik sessiz modu (Android Rahatsız Etmeyin / DND erişimi).
 * Dart, önümüzdeki 5 günün sessiz pencerelerini [sync] ile verir; bu sınıf alarmları kurar,
 * başlangıçta telefonu yalnızca zaten DND değilse alarmlara izinli sessize alır
 * (INTERRUPTION_FILTER_ALARMS), süre bitince önceki süzgece geri döndürür.
 * Kullanıcı bu arada DND'yi elle değiştirdiyse dokunulmaz.
 */
object PrayerSilence {
    private const val PREFS = "VaktindePrayerSilence"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_WINDOWS = "windows" // "start:end,start:end"
    private const val KEY_COUNT = "scheduled_count"
    private const val KEY_ACTIVE = "active"
    private const val KEY_PREV_FILTER = "prev_filter"
    private const val KEY_ACTIVE_END = "active_end"

    const val ACTION_START = "com.mmdigital.vaktinde.ACTION_PRAYER_SILENCE_START"
    const val ACTION_END = "com.mmdigital.vaktinde.ACTION_PRAYER_SILENCE_END"
    const val EXTRA_END_MS = "end_ms"

    private const val START_REQ_BASE = 30000
    private const val END_REQ_BASE = 31000
    private const val MAX_WINDOWS = 40

    data class Window(val startMs: Long, val endMs: Long)

    fun hasPolicyAccess(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return false
        return runCatching { nm.isNotificationPolicyAccessGranted }.getOrDefault(false)
    }

    fun openPolicyAccessSettings(context: Context): Boolean {
        val candidates = listOfNotNull(
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            } else {
                null
            },
            Intent("android.settings.ZEN_MODE_SETTINGS"),
            Intent(Settings.ACTION_SOUND_SETTINGS),
        )
        for (intent in candidates) {
            try {
                context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return true
            } catch (_: RuntimeException) {
                // Sıradaki ekran denenir
            }
        }
        return false
    }

    /** Dart'tan gelen planı kaydeder ve alarmları yeniden kurar */
    fun sync(context: Context, enabled: Boolean, windows: List<Window>) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val clean = windows
            .filter { it.endMs > it.startMs }
            .sortedBy { it.startMs }
            .take(MAX_WINDOWS)
        val serialized = clean.joinToString(",") { "${it.startMs}:${it.endMs}" }
        prefs.edit()
            .putBoolean(KEY_ENABLED, enabled)
            .putString(KEY_WINDOWS, if (enabled) serialized else "")
            .apply()

        if (!enabled) {
            cancelScheduled(context)
            restoreIfActive(context)
            return
        }
        scheduleFromPrefs(context)
    }

    /** Kayıtlı pencereleri (yeniden başlatma / saat değişimi sonrası da) kurar */
    fun scheduleFromPrefs(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        cancelScheduled(context)
        val enabled = prefs.getBoolean(KEY_ENABLED, false)
        val now = System.currentTimeMillis()
        if (!enabled || !hasPolicyAccess(context)) {
            if (prefs.getBoolean(KEY_ACTIVE, false) && now >= prefs.getLong(KEY_ACTIVE_END, 0L)) {
                restoreIfActive(context)
            }
            return
        }

        val windows = parseWindows(prefs.getString(KEY_WINDOWS, null))
            .filter { it.endMs > now }
            .take(MAX_WINDOWS)

        // Telefon bir pencere sürerken kapandıysa veya bitişi kaçırdıysa onar
        val activeNow = windows.firstOrNull { now in it.startMs until it.endMs }
        if (prefs.getBoolean(KEY_ACTIVE, false) && activeNow == null) {
            restoreIfActive(context)
        } else if (activeNow != null && !prefs.getBoolean(KEY_ACTIVE, false)) {
            activateSilence(context, activeNow.endMs)
        }

        var count = 0
        for ((index, window) in windows.withIndex()) {
            if (window.startMs > now) {
                scheduleAlarm(
                    context,
                    START_REQ_BASE + index,
                    ACTION_START,
                    window.startMs,
                    window.endMs,
                )
            }
            scheduleAlarm(
                context,
                END_REQ_BASE + index,
                ACTION_END,
                window.endMs,
                window.endMs,
            )
            count++
        }
        prefs.edit().putInt(KEY_COUNT, count).apply()
    }

    internal fun activateSilence(context: Context, endMs: Long) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || !hasPolicyAccess(context)) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ENABLED, false)) return
        if (endMs <= System.currentTimeMillis()) return

        runCatching {
            val alreadyActive = prefs.getBoolean(KEY_ACTIVE, false)
            if (alreadyActive) {
                val prevEnd = prefs.getLong(KEY_ACTIVE_END, 0L)
                if (endMs > prevEnd) {
                    prefs.edit().putLong(KEY_ACTIVE_END, endMs).apply()
                }
                return
            }
            val current = nm.currentInterruptionFilter
            // Kullanıcı zaten DND açtıysa dokunma
            if (current != NotificationManager.INTERRUPTION_FILTER_ALL) return
            prefs.edit()
                .putBoolean(KEY_ACTIVE, true)
                .putInt(KEY_PREV_FILTER, current)
                .putLong(KEY_ACTIVE_END, endMs)
                .apply()
            nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALARMS)
        }
    }

    internal fun handleEnd(context: Context, endMs: Long) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ACTIVE, false)) return
        val expectedEnd = prefs.getLong(KEY_ACTIVE_END, 0L)
        // Çakışan yeni pencere süreyi uzattıysa erken kapatma
        if (expectedEnd > endMs + 1000L && System.currentTimeMillis() < expectedEnd - 1000L) {
            return
        }
        restoreIfActive(context)
    }

    internal fun restoreIfActive(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ACTIVE, false)) return
        val prev = prefs.getInt(KEY_PREV_FILTER, NotificationManager.INTERRUPTION_FILTER_ALL)
        prefs.edit()
            .putBoolean(KEY_ACTIVE, false)
            .remove(KEY_ACTIVE_END)
            .apply()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || !hasPolicyAccess(context)) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return
        runCatching {
            // Kullanıcı DND'yi elle başka bir moda aldıysa bozma
            if (nm.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_ALARMS) {
                nm.setInterruptionFilter(prev)
            }
        }
    }

    private fun scheduleAlarm(
        context: Context,
        requestCode: Int,
        action: String,
        triggerAtMs: Long,
        endMs: Long,
    ) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(context, PrayerSilenceReceiver::class.java).apply {
            this.action = action
            putExtra(EXTRA_END_MS, endMs)
        }
        val pi = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        runCatching {
            val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()
            if (canExact && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
            } else {
                am.setExact(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
            }
        }
    }

    private fun cancelScheduled(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val previousCount = prefs.getInt(KEY_COUNT, 0).coerceIn(0, MAX_WINDOWS)
        for (i in 0 until previousCount) {
            cancelOne(context, am, START_REQ_BASE + i, ACTION_START)
            cancelOne(context, am, END_REQ_BASE + i, ACTION_END)
        }
        prefs.edit().putInt(KEY_COUNT, 0).apply()
    }

    private fun cancelOne(context: Context, am: AlarmManager, requestCode: Int, action: String) {
        val intent = Intent(context, PrayerSilenceReceiver::class.java).apply {
            this.action = action
        }
        val pi = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        ) ?: return
        am.cancel(pi)
        pi.cancel()
    }

    private fun parseWindows(raw: String?): List<Window> {
        if (raw.isNullOrBlank()) return emptyList()
        return raw.split(",").mapNotNull { entry ->
            val parts = entry.split(":")
            if (parts.size != 2) return@mapNotNull null
            val start = parts[0].toLongOrNull() ?: return@mapNotNull null
            val end = parts[1].toLongOrNull() ?: return@mapNotNull null
            if (end > start) Window(start, end) else null
        }
    }
}

class PrayerSilenceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val endMs = intent?.getLongExtra(PrayerSilence.EXTRA_END_MS, 0L) ?: 0L
        when (intent?.action) {
            PrayerSilence.ACTION_START -> PrayerSilence.activateSilence(context, endMs)
            PrayerSilence.ACTION_END -> PrayerSilence.handleEnd(context, endMs)
        }
    }
}

class PrayerSilenceBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            -> PrayerSilence.scheduleFromPrefs(context)
        }
    }
}