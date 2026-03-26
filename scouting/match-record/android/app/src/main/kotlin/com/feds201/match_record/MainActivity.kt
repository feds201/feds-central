package com.feds201.match_record

import android.os.Build
import android.os.storage.StorageManager
import android.os.storage.StorageVolume
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val USB_CHANNEL = "com.feds201.match_record/usb_drive"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USB_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getUsbDrives" -> result.success(getUsbDrives())
                    else -> result.notImplemented()
                }
            }
    }

    private fun getUsbDrives(): List<Map<String, String>> {
        val storageManager = getSystemService(STORAGE_SERVICE) as StorageManager
        val drives = mutableListOf<Map<String, String>>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            for (volume in storageManager.storageVolumes) {
                if (!volume.isRemovable) continue
                val dir = volume.directory ?: continue
                drives.add(mapOf(
                    "path" to dir.absolutePath,
                    "label" to (volume.getDescription(this) ?: dir.name)
                ))
            }
        }

        return drives
    }
}
