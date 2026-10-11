package com.mmdigital.vaktinde

import android.app.NotificationManager
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.view.KeyEvent
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.IOException
import kotlin.math.sqrt

/** "vaktinde/device" kanalı (MainActivity) */
object DeviceMethods {
    /**
     * Uygulama bağlamı (VaktindeApplication.onCreate): MainActivity kanala bağlam vermez; cihaz
     * durumu (deviceInfo) bununla okunur, ayar ekranı (openSettings) bununla açılır.
     */
    @Volatile
    var appContext: Context? = null

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // Android sürümü Dart'tan okunamıyor: "Sessiz modda da çal" sadece 8.0+ (API 26) gösterilir
            "sdkInt" -> result.success(Build.VERSION.SDK_INT)
            "geomagnetic" -> {
                val field = geomagnetic(call.arguments, System.currentTimeMillis())
                if (field == null) result.error("bad_args", "lat/lng (derece) gerekli", null) else result.success(field)
            }
            // Bildirim Kontrolü
            "deviceInfo" -> {
                val context = appContext ?: return result.error("no_context", null, null)
                result.success(deviceInfo(context))
            }
            "openSettings" -> {
                val context = appContext ?: return result.error("no_context", null, null)
                val target = (call.arguments as? Map<*, *>)?.get("target") as? String
                val opened = openSettings(context, target)
                if (opened == null) result.error("bad_args", "target: app, notifications, battery, dnd, sound", null)
                else result.success(opened)
            }
            // Firebase Analytics izinleri (Consent Mode v2) için reklam rızası kaydı
            "tcfConsent" -> {
                val context = appContext ?: return result.error("no_context", null, null)
                result.success(tcfConsent(context))
            }
            else -> result.notImplemented()
        }
    }

    /** Yedek dosyası en çok bu kadar okunur (Dart BackupService.maxBytes ile aynı) */
    const val MAX_DOCUMENT_BYTES = 1024 * 1024

    /**
     * Seçilen belgenin UTF-8 metni; [maxBytes]'tan büyükse null (tamamı okunmaz). Akış
     * açılamazsa/okunamazsa fırlatır (çağıran yakalar).
     */
    fun readDocument(resolver: ContentResolver, uri: Uri, maxBytes: Int): String? {
        val input = resolver.openInputStream(uri) ?: throw IOException("no input stream")
        return input.use { stream ->
            val out = ByteArrayOutputStream()
            val buffer = ByteArray(8192)
            while (true) {
                val read = stream.read(buffer)
                if (read < 0) break
                if (out.size() + read > maxBytes) return null
                out.write(buffer, 0, read)
            }
            String(out.toByteArray(), Charsets.UTF_8)
        }
    }

    /**
     * Reklam rızası (Google UMP, IAB TCF v2): UMP kararları uygulamanın varsayılan
     * SharedPreferences dosyasına yazar. gdprApplies: IABTCF_gdprApplies (1 GDPR geçerli,
     * 0 değil; yoksa null), purposeConsents: IABTCF_PurposeConsents ("1" ile başlıyorsa amaç 1
     * onaylı; yoksa null). Bazı CMP'ler sayıyı metin yazar: o da okunur. Hiçbir yol fırlatmaz.
     */
    fun tcfConsent(context: Context): Map<String, Any?> {
        val all = runCatching {
            context.getSharedPreferences(context.packageName + "_preferences", Context.MODE_PRIVATE).all
        }.getOrNull().orEmpty()
        val gdprApplies = when (val value = all["IABTCF_gdprApplies"]) {
            is Number -> value.toInt()
            is String -> value.trim().toIntOrNull()
            else -> null
        }
        return mapOf(
            "gdprApplies" to gdprApplies,
            "purposeConsents" to all["IABTCF_PurposeConsents"] as? String,
        )
    }

    /**
     * Ezanı susturabilecek cihaz durumu: üretici/marka (arka plan rehberi), pil optimizasyonu
     * (isIgnoringBatteryOptimizations; izin gerekmez), Rahatsız Etmeyin süzgeci
     * (INTERRUPTION_FILTER_*), bildirim ve alarm ses düzeyi, zil modu (RINGER_MODE_*).
     * Okunamayan değer null; hiçbir yol fırlatmaz.
     */
    fun deviceInfo(context: Context): Map<String, Any?> {
        val power = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val notifications = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "brand" to Build.BRAND,
            "sdkInt" to Build.VERSION.SDK_INT,
            "batteryOptimized" to runCatching { power?.isIgnoringBatteryOptimizations(context.packageName)?.not() }.getOrNull(),
            "interruptionFilter" to runCatching { notifications?.currentInterruptionFilter }.getOrNull(),
            "notificationVolume" to runCatching { audio?.getStreamVolume(AudioManager.STREAM_NOTIFICATION) }.getOrNull(),
            "alarmVolume" to runCatching { audio?.getStreamVolume(AudioManager.STREAM_ALARM) }.getOrNull(),
            "ringerMode" to runCatching { audio?.ringerMode }.getOrNull(),
        )
    }

    /**
     * Sistem ayar ekranı: app (uygulama bilgisi), notifications (uygulamanın bildirimleri, 8.0+),
     * battery (pil ayarı uygulama bilgisindedir: REQUEST_IGNORE_BATTERY_OPTIMIZATIONS izni yok,
     * uygulamaya özel genel bir pil ekranı da yok), dnd (Rahatsız Etmeyin), sound (ses). Ekran
     * yoksa (ActivityNotFoundException; üretici kaldırmış) sıradakine, en sonda uygulama
     * bilgisine düşülür. Açıldıysa true, hiçbiri açılamadıysa false, hedef tanınmazsa null.
     */
    fun openSettings(context: Context, target: String?): Boolean? {
        val details = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", context.packageName, null))
        val sound = Intent(Settings.ACTION_SOUND_SETTINGS)
        val candidates = when (target) {
            "app", "battery" -> listOf(details)
            "notifications" -> listOfNotNull(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                } else {
                    null
                },
                details,
            )
            // Settings.ACTION_ZEN_MODE_SETTINGS gizli (@hide) sabit: aynı eylem metniyle
            "dnd" -> listOf(Intent(ZEN_MODE_SETTINGS), sound, details)
            "sound" -> listOf(sound, details)
            else -> return null
        }
        for (intent in candidates) {
            try {
                context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return true
            } catch (e: RuntimeException) {
                // ActivityNotFoundException (ya da dışa kapalı ekran): sıradaki
            }
        }
        return false
    }

    private const val ZEN_MODE_SETTINGS = "android.settings.ZEN_MODE_SETTINGS"

    /**
     * Kıble: pusulanın manyetik kuzeyini gerçek kuzeye çeviren sapma (derece, doğu +) ve
     * beklenen alan şiddeti (µT; ölçülenle kıyaslanıp parazit sezilir). Cihazdaki dünya manyetik
     * modeli (WMM), deniz seviyesi. Argümanlar {"lat", "lng"} değilse ya da aralık dışıysa null.
     */
    fun geomagnetic(arguments: Any?, timeMs: Long): Map<String, Double>? {
        val args = arguments as? Map<*, *> ?: return null
        val lat = (args["lat"] as? Number)?.toDouble() ?: return null
        val lng = (args["lng"] as? Number)?.toDouble() ?: return null
        // NaN / sonsuz da aralık dışı
        if (lat !in -90.0..90.0 || lng !in -180.0..180.0) return null
        val field = GeomagneticField(lat.toFloat(), lng.toFloat(), 0f, timeMs)
        // fieldStrength nanotesla
        return mapOf("declination" to field.declination.toDouble(), "strength" to field.fieldStrength / 1000.0)
    }
}

/**
 * "vaktinde/magnetic" akışı: manyetometrenin ölçtüğü alan büyüklüğü (µT) ve doğruluğu
 * (SensorManager 0..3, bilinmiyorsa -1); parazit / kalibrasyon uyarısı için. Olay
 * [büyüklük: Double, doğruluk: Int], saniyede en çok 5. Sensör yoksa bir kez "no_sensor".
 * Olaylar ana iş parçacığında (Handler'sız registerListener). Activity görünmezken sensör
 * bırakılır (ön plan servisi süreci arka planda da canlı tutar), dönünce yeniden açılır.
 */
class MagneticStream(private val context: Context) : EventChannel.StreamHandler, SensorEventListener {
    private var sink: EventChannel.EventSink? = null
    private var sensorManager: SensorManager? = null
    private var paused = false
    private var accuracy = UNKNOWN
    private var nextEmitAt = 0L

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        stop()
        val manager = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        if (manager?.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD) == null) {
            events.error("no_sensor", null, null)
            return
        }
        sink = events
        if (!paused && !listen(manager)) {
            sink = null
            events.error("no_sensor", null, null)
        }
    }

    override fun onCancel(arguments: Any?) = stop()

    /** Dinleyici ve akış bırakılır (onCancel, motor temizliği) */
    fun stop() {
        unregister()
        sink = null
    }

    /** Activity görünmez oldu (onStop): akış kalır, sensör kapanır */
    fun pause() {
        paused = true
        unregister()
    }

    /** Activity yeniden görünür (onStart): Dart hâlâ dinliyorsa sensör açılır */
    fun resume() {
        paused = false
        if (sink == null || sensorManager != null) return
        val manager = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager ?: return
        listen(manager)
    }

    private fun listen(manager: SensorManager): Boolean {
        val sensor = manager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD) ?: return false
        // Yeni kayıtta doğruluk yeniden bildirilir; eski değer taşınmaz
        accuracy = UNKNOWN
        nextEmitAt = 0L
        if (!manager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)) return false
        sensorManager = manager
        return true
    }

    private fun unregister() {
        sensorManager?.unregisterListener(this)
        sensorManager = null
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        this.accuracy = if (accuracy in 0..3) accuracy else UNKNOWN
    }

    override fun onSensorChanged(event: SensorEvent?) {
        val events = sink ?: return
        val values = event?.values ?: return
        if (values.size < 3) return
        val now = SystemClock.elapsedRealtime()
        if (now < nextEmitAt) return
        nextEmitAt = now + MIN_INTERVAL_MS
        val x = values[0].toDouble()
        val y = values[1].toDouble()
        val z = values[2].toDouble()
        events.success(listOf(sqrt(x * x + y * y + z * z), reportedAccuracy(event)))
    }

    // Çerçeve onAccuracyChanged'i sadece değer 0'dan farklılaşınca çağırır (başlangıç 0): ilk
    // olaylar UNRELIABLE (0) ise çağrı hiç gelmez, olayın kendi doğruluğu kullanılır
    private fun reportedAccuracy(event: SensorEvent): Int = when {
        accuracy != UNKNOWN -> accuracy
        event.accuracy in 0..3 -> event.accuracy
        else -> UNKNOWN
    }

    private companion object {
        const val UNKNOWN = -1
        const val MIN_INTERVAL_MS = 200L
    }
}

/**
 * Zikirmatik "Ses tuşlarıyla say" ("vaktinde/volume_keys" akışı, MainActivity.dispatchKeyEvent).
 * Ses tuşları sadece Dart açıkça istediğinde ("vaktinde/device" setVolumeKeyCounting(true): Zikir
 * sekmesi görünür, ayar açık, uygulama ön planda) VE akış dinlenirken tüketilir: sistem ses düzeyi
 * değişmez, ses paneli açılmaz. Olay basış başına bir kez: ses açma +1, ses kısma -1 (Int); basılı
 * tutmanın tekrarları sayılmaz. Tüketilen basışın tekrarları ve bırakması (ACTION_UP; bırakılmasa
 * sistem "bip" çalar) da tüketilir; bayrak kapalıyken başlayan basışınkiler sisteme gider.
 * Takılı kalmaz: onStop ve motor değişince bayrak kapanır (Dart ön plana dönüşte yeniden açar),
 * Dart dinlemeyi bırakınca tuşlar sisteme döner. Ana iş parçacığında çağrılır.
 */
class VolumeKeyCounter : EventChannel.StreamHandler {
    private var enabled = false
    private var sink: EventChannel.EventSink? = null

    // Tüketilen basışın tuşları: tekrarları ve bırakması da tüketilir
    private val ownedKeys = mutableSetOf<Int>()

    /** Ses tuşları şu an sayaca gidiyor mu (bayrak açık ve Dart dinliyor) */
    val counting: Boolean get() = enabled && sink != null

    /** Dart'tan (setVolumeKeyCounting); basılı tuşun bırakması yine tüketilir */
    fun setEnabled(value: Boolean) {
        enabled = value
    }

    /** Activity görünmez oldu (onStop) ya da yeni motor: Dart yeniden açana kadar sayılmaz */
    fun reset() {
        enabled = false
        ownedKeys.clear()
    }

    /** Motor ayrıldı (cleanUpFlutterEngine): eski akış da bırakılır */
    fun detach() {
        reset()
        sink = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    /** true: olay tüketildi (görünüm ağacına ve sistemin ses ayarına gitmez) */
    fun onKeyEvent(event: KeyEvent): Boolean {
        val code = event.keyCode
        val delta = when (code) {
            KeyEvent.KEYCODE_VOLUME_UP -> 1
            KeyEvent.KEYCODE_VOLUME_DOWN -> -1
            else -> return false
        }
        return when (event.action) {
            KeyEvent.ACTION_DOWN -> {
                if (event.repeatCount > 0) return code in ownedKeys
                val events = sink
                if (!enabled || events == null) {
                    ownedKeys.remove(code)
                    return false
                }
                ownedKeys.add(code)
                events.success(delta)
                true
            }
            KeyEvent.ACTION_UP -> ownedKeys.remove(code)
            else -> false
        }
    }
}
