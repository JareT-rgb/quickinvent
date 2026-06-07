package com.example.quickinvent

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.KeyEvent

class MainActivity : FlutterActivity() {
    private val CHANNEL = "quickinvent/keys"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
            val keyCode = event.keyCode
            
            // Send to Flutter
            methodChannel?.invokeMethod("onKeyDown", mapOf("keyCode" to keyCode))
            
            // Consume volume keys to prevent system volume popup when using as trigger
            if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
                return true
            }
        }
        return super.dispatchKeyEvent(event)
    }
}
