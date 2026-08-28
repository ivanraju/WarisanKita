package com.example.warisan_kita

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "warisan_kita/google_maps",
        ).setMethodCallHandler { call, result ->
            if (call.method != "getApiKey") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            try {
                val applicationInfo = packageManager.getApplicationInfo(
                    packageName,
                    PackageManager.GET_META_DATA,
                )
                val apiKey = applicationInfo.metaData
                    ?.getString("com.google.android.geo.API_KEY")
                if (apiKey.isNullOrBlank()) {
                    result.error("MISSING_API_KEY", "Google Maps API key is not configured.", null)
                } else {
                    result.success(apiKey)
                }
            } catch (error: Exception) {
                result.error("API_KEY_READ_FAILED", error.message, null)
            }
        }
    }
}
