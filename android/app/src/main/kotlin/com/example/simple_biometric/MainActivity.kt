package com.example.simple_biometric

import io.flutter.embedding.android.FlutterFragmentActivity
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import BiometricHandler

class MainActivity: FlutterFragmentActivity() {
  private val CHANNEL = "biometric_channel"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
      if (call.method == "authenticate") {
        authenticate()
        result.success(null)
      } else {
        result.notImplemented()
      }
    }
  }

  private fun authenticate() {
    val biometricHandler = BiometricHandler(this)
    biometricHandler.authenticate()
  }

}


