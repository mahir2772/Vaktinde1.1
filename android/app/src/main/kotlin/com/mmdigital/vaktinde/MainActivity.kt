package com.mmdigital.vaktinde

import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.activity.SystemBarStyle
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: androidx ComponentActivity (enableEdgeToEdge); AppCompat teması gerekmez
class MainActivity : FlutterFragmentActivity() {
    // Kıble manyetometre akışı: sensör sadece Dart dinlerken ve ekran görünürken açık
    private var magnetic: MagneticStream? = null

    // Yedek dosyası seçimi ("pickBackupFile"): sonucu bekleyen Dart çağrısı. Seçici açıkken
    // süreç ölür/aktivite yeniden kurulursa sonuç sahipsiz gelir ve yok sayılır.
    private var pendingPick: MethodChannel.Result? = null
    private val documentPicker = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { picked ->
        onDocumentPicked(picked.resultCode, picked.data?.data)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Uçtan uca (Play önerisi; Android 15+ zaten böyle): içerik sistem çubuklarının altına
        // uzanır, boşluğu Flutter MediaQuery.padding bırakır. super'den sonra: pencere NormalTheme
        // ile kurulmuş olur (önce çağrılırsa LaunchTheme'in açılış görseli pencere arka planında
        // kalır), Flutter'ın yarı saydam durum çubuğu da şeffafla değişir.
        // 11 altı: Flutter her resume'da eski sistem bayraklarını sıfırlar (gezinme uçtan uca olmaz,
        // tuşlar beyaz) → gezinme çubuğu eskisi gibi siyah; varsayılan açık perdede tuşlar görünmezdi
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            enableEdgeToEdge(navigationBarStyle = SystemBarStyle.dark(Color.BLACK))
        } else {
            enableEdgeToEdge()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // sdkInt ("Sessiz modda da çal" 8.0+), geomagnetic (kıble: manyetik sapma + beklenen alan);
        // dosya seçici aktivite ister: burada
        MethodChannel(messenger, "vaktinde/device").setMethodCallHandler { call, result ->
            if (call.method == "pickBackupFile") pickDocument(result) else DeviceMethods.handle(call, result)
        }
        magnetic?.stop()
        val stream = MagneticStream(applicationContext)
        magnetic = stream
        EventChannel(messenger, "vaktinde/magnetic").setStreamHandler(stream)
    }

    // Activity kapanınca (onDestroy → motor ayrılır) sensör dinleyicisi bırakılır
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        magnetic?.stop()
        magnetic = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onStart() {
        super.onStart()
        magnetic?.resume()
    }

    override fun onStop() {
        magnetic?.pause()
        super.onStop()
    }

    /**
     * Ayarlar > "Yedeği geri yükle": sistem dosya seçicisi (SAF; izin gerekmez). Tür süzülmez:
     * paylaşılan .json çoğu zaman application/octet-stream ya da text/plain görünür. Sonuç
     * dosyanın UTF-8 metni (en çok [DeviceMethods.MAX_DOCUMENT_BYTES]), vazgeçilirse null.
     * Hatalar: busy (seçici zaten açık), no_picker, too_large, read_failed.
     */
    private fun pickDocument(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", null, null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("*/*")
        pendingPick = result
        try {
            documentPicker.launch(intent)
        } catch (e: RuntimeException) {
            // ActivityNotFoundException: seçicisi kaldırılmış cihaz
            pendingPick = null
            result.error("no_picker", e.message, null)
        }
    }

    private fun onDocumentPicked(resultCode: Int, uri: Uri?) {
        val result = pendingPick ?: return
        pendingPick = null
        if (resultCode != RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        val resolver = contentResolver
        // Bulut sağlayıcısı (Drive) dosyayı indirirken bekletebilir: ana iş parçacığı dışında
        Thread {
            val outcome = runCatching { DeviceMethods.readDocument(resolver, uri, DeviceMethods.MAX_DOCUMENT_BYTES) }
            runOnUiThread {
                outcome.fold(
                    onSuccess = { text ->
                        if (text == null) result.error("too_large", null, null) else result.success(text)
                    },
                    onFailure = { e -> result.error("read_failed", e.message, null) },
                )
            }
        }.start()
    }
}
