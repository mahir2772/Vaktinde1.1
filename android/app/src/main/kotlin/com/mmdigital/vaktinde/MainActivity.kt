package com.mmdigital.vaktinde

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Kıble manyetometre akışı: sensör sadece Dart dinlerken ve ekran görünürken açık
    private var magnetic: MagneticStream? = null

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
