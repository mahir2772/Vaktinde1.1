package com.mmdigital.vaktinde

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Android sürümü Dart'tan okunamıyor: "Sessiz modda da çal" sadece 8.0+ (API 26) gösterilir
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vaktinde/device")
            .setMethodCallHandler { call, result ->
                if (call.method == "sdkInt") result.success(Build.VERSION.SDK_INT) else result.notImplemented()
            }
    }
}
