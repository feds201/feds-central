package com.feds201.match_record

import android.media.MediaMetadataRetriever
import android.os.Build
import android.os.StatFs
import android.os.storage.StorageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.RandomAccessFile

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.feds201.match_record/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getUsbDrives" -> result.success(getUsbDrives())
                    "getVideoMetadata" -> {
                        val filePath = call.argument<String>("filePath")
                        if (filePath == null) {
                            result.error("INVALID_ARG", "filePath is required", null)
                        } else {
                            result.success(getVideoMetadata(filePath))
                        }
                    }
                    "getFreeSpace" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("INVALID_ARG", "path is required", null)
                        } else {
                            result.success(getFreeSpace(path))
                        }
                    }
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

    private fun getVideoMetadata(filePath: String): Map<String, Any?> {
        val metadata = mutableMapOf<String, Any?>()
        val retriever = MediaMetadataRetriever()

        try {
            retriever.setDataSource(filePath)

            // Duration in milliseconds
            val durationMsStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            if (durationMsStr != null) {
                metadata["durationMs"] = durationMsStr.toLongOrNull()
            }

            // Creation date as ISO string
            val dateStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DATE)
            metadata["date"] = dateStr

            // Mimetype
            metadata["mimetype"] = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_MIMETYPE)

            // Dimensions
            val widthStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
            val heightStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
            metadata["width"] = widthStr?.toIntOrNull()
            metadata["height"] = heightStr?.toIntOrNull()

            // Rotation/orientation
            val rotationStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
            metadata["orientation"] = rotationStr?.toIntOrNull()

            // Frame rate (API 23+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val frStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_CAPTURE_FRAMERATE)
                metadata["framerate"] = frStr?.toDoubleOrNull()
            }
        } catch (e: Exception) {
            // Report the error to Dart so it can surface it in the UI
            metadata["extractionError"] = e.toString()
        } finally {
            try { retriever.release() } catch (_: Exception) {}
        }

        // ftyp brand: read from file header (4 bytes at offset 4 after finding "ftyp")
        metadata["ftypBrand"] = readFtypBrand(filePath)

        // File size
        try {
            metadata["fileSize"] = File(filePath).length()
        } catch (_: Exception) {}

        // DO NOT SUBMIT — uncomment to force null metadata for testing nullable fields
        // metadata.remove("date")
        // metadata.remove("durationMs")
        // metadata.remove("fileSize")

        return metadata
    }

    /// Read the ftyp major brand from an MP4/MOV file header.
    /// The ftyp box starts with [size][ftyp][major_brand]. We scan the first
    /// 32 bytes looking for the "ftyp" marker, then read the next 4 bytes.
    private fun readFtypBrand(filePath: String): String? {
        try {
            val raf = RandomAccessFile(filePath, "r")
            raf.use {
                val header = ByteArray(32)
                val bytesRead = raf.read(header)
                if (bytesRead < 12) return null

                // Find "ftyp" in the header
                for (i in 0 until bytesRead - 7) {
                    if (header[i] == 'f'.code.toByte() &&
                        header[i + 1] == 't'.code.toByte() &&
                        header[i + 2] == 'y'.code.toByte() &&
                        header[i + 3] == 'p'.code.toByte()) {
                        // Major brand is the next 4 bytes
                        return String(header, i + 4, 4, Charsets.US_ASCII)
                    }
                }
            }
        } catch (_: Exception) {}
        return null
    }

    private fun getFreeSpace(path: String): Long {
        return try {
            val stat = StatFs(path)
            stat.availableBytes
        } catch (_: Exception) {
            -1L
        }
    }
}
