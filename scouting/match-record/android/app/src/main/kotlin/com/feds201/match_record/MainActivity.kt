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

        // Custom MP4/MOV metadata tags (requires parsing moov/udta atoms)
        val customTags = readCustomMetadataTags(filePath)
        metadata["hasAppleQuicktimeCreationDate"] = customTags.containsKey("com.apple.quicktime.creationdate")
        metadata["samsungUtcOffset"] = customTags["com.samsung.android.utc_offset"]

        return metadata
    }

    /// Read custom metadata tags from MP4/MOV moov/udta/meta atoms.
    /// Looks for: com.apple.quicktime.creationdate, com.samsung.android.utc_offset.
    /// These are stored in the mdta-based metadata (ilst inside meta inside udta inside moov).
    /// Returns a map of tag name -> string value for any found tags.
    private fun readCustomMetadataTags(filePath: String): Map<String, String> {
        val tags = mutableMapOf<String, String>()
        val targetTags = setOf("com.apple.quicktime.creationdate", "com.samsung.android.utc_offset")

        try {
            val raf = RandomAccessFile(filePath, "r")
            raf.use {
                // Find moov box at top level
                val moovOffset = findBox(raf, 0, raf.length(), "moov") ?: return tags
                val moovSize = readBoxSize(raf, moovOffset)

                // Find udta inside moov
                val udtaOffset = findBox(raf, moovOffset + 8, moovOffset + moovSize, "udta") ?: return tags
                val udtaSize = readBoxSize(raf, udtaOffset)

                // Find meta inside udta
                val metaOffset = findBox(raf, udtaOffset + 8, udtaOffset + udtaSize, "meta") ?: return tags
                val metaSize = readBoxSize(raf, metaOffset)

                // meta box has a 4-byte version/flags field after the header
                val metaDataStart = metaOffset + 12

                // Find keys box inside meta
                val keysOffset = findBox(raf, metaDataStart, metaOffset + metaSize, "keys") ?: return tags
                val keysSize = readBoxSize(raf, keysOffset)

                // Parse keys: 4 bytes version/flags, 4 bytes entry_count, then entries
                raf.seek(keysOffset + 8) // skip box header
                raf.skipBytes(4) // version/flags
                val entryCount = raf.readInt()

                val keyNames = mutableListOf<String>()
                for (i in 0 until entryCount) {
                    val keySize = raf.readInt()
                    raf.skipBytes(4) // key namespace (4 bytes, e.g. "mdta")
                    val nameBytes = ByteArray(keySize - 8)
                    raf.readFully(nameBytes)
                    keyNames.add(String(nameBytes, Charsets.UTF_8))
                }

                // Find ilst inside meta
                val ilstOffset = findBox(raf, metaDataStart, metaOffset + metaSize, "ilst") ?: return tags
                val ilstSize = readBoxSize(raf, ilstOffset)

                // Parse ilst entries: each is a box with a 1-based key index as the box type
                var pos = ilstOffset + 8
                val ilstEnd = ilstOffset + ilstSize
                while (pos < ilstEnd) {
                    val itemSize = readBoxSize(raf, pos)
                    if (itemSize < 8) break

                    // The box type is a big-endian int representing the 1-based key index
                    raf.seek(pos + 4)
                    val keyIndex = raf.readInt() - 1 // convert to 0-based

                    if (keyIndex in keyNames.indices && keyNames[keyIndex] in targetTags) {
                        // Find data box inside this item
                        val dataOffset = findBox(raf, pos + 8, pos + itemSize, "data")
                        if (dataOffset != null) {
                            val dataSize = readBoxSize(raf, dataOffset)
                            // data box: 8 byte header + 4 byte type + 4 byte locale = 16 byte overhead
                            if (dataSize > 16) {
                                raf.seek(dataOffset + 16)
                                val valueBytes = ByteArray((dataSize - 16).toInt())
                                raf.readFully(valueBytes)
                                tags[keyNames[keyIndex]] = String(valueBytes, Charsets.UTF_8)
                            }
                        }
                    }

                    pos += itemSize
                }
            }
        } catch (_: Exception) {}
        return tags
    }

    /// Find a box with the given 4-char type within [start, end) range.
    /// Returns the offset of the box, or null if not found.
    private fun findBox(raf: RandomAccessFile, start: Long, end: Long, type: String): Long? {
        var pos = start
        val typeBytes = type.toByteArray(Charsets.US_ASCII)
        while (pos < end - 8) {
            val size = readBoxSize(raf, pos)
            if (size < 8) return null

            raf.seek(pos + 4)
            val boxType = ByteArray(4)
            raf.readFully(boxType)

            if (boxType.contentEquals(typeBytes)) return pos
            pos += size
        }
        return null
    }

    /// Read the 32-bit box size at the given offset.
    private fun readBoxSize(raf: RandomAccessFile, offset: Long): Long {
        raf.seek(offset)
        return raf.readInt().toLong() and 0xFFFFFFFFL
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
