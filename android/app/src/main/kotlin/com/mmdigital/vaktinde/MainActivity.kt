package com.mmdigital.vaktinde

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import androidx.activity.SystemBarStyle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: androidx ComponentActivity (enableEdgeToEdge); AppCompat teması gerekmez
class MainActivity : FlutterFragmentActivity() {
    // Kıble manyetometre akışı: sensör sadece Dart dinlerken ve ekran görünürken açık
    private var magnetic: MagneticStream? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Uçtan uca (Play önerisi; Android 15+ zaten böyle): içerik sistem çubuklarının altına
        // uzanır, boşluğu Flutter MediaQuery.padding bırakır. super'den önce: pencere burada
        // LaunchTheme ile kurulur, Flutter ardından (15 altı) durum çubuğuna yarı saydam rengini verir.
        // 11 altı: Flutter her resume'da eski sistem bayraklarını sıfırlar (gezinme uçtan uca olmaz,
        // tuşlar beyaz) → gezinme çubuğu eskisi gibi siyah; varsayılan açık perdede tuşlar görünmezdi
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            enableEdgeToEdge(navigationBarStyle = SystemBarStyle.dark(Color.BLACK))
        } else {
            enableEdgeToEdge()
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // sdkInt ("Sessiz modda da çal" 8.0+), geomagnetic (kıble: manyetik sapma + beklenen alan)
        MethodChannel(messenger, "vaktinde/device")
            .setMethodCallHandler { call, result -> DeviceMethods.handle(call, result) }
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
}
