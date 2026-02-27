package com.pyintel.scouting_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.pyintel.scoutOps/lockTask"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "startLockTask") {
                startLockTask()
                result.success(null)
            } else if (call.method == "stopLockTask") {
                stopLockTask()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
