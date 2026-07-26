package com.mycompany.farm

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterFragmentActivity() {
  private val channelName = "farm.qr_download_service"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
      when (call.method) {
        "downloadQr" -> {
          val bytes = call.argument<ByteArray>("bytes")
          val fileName = call.argument<String>("fileName")
          if (bytes == null || fileName == null) {
            result.error("INVALID_ARGUMENTS", "Missing bytes or fileName", null)
            return@setMethodCallHandler
          }

          try {
            val savedPath = saveQrImage(bytes, fileName)
            result.success(mapOf(
              "success" to true,
              "message" to "Saved to Downloads/Farm Africa",
              "fileUri" to savedPath,
              "destination" to "downloads",
            ))
          } catch (error: Exception) {
            result.success(mapOf(
              "success" to false,
              "message" to "Save failed: ${error.message}",
              "destination" to "unknown",
            ))
          }
        }
        else -> result.notImplemented()
      }
    }
  }

  private fun saveQrImage(bytes: ByteArray, fileName: String): String {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      val contentValues = ContentValues().apply {
        put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
        put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
        put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/Farm Africa")
        put(MediaStore.MediaColumns.IS_PENDING, 1)
      }

      val resolver = contentResolver
      val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
        ?: throw Exception("Unable to create MediaStore entry")

      resolver.openOutputStream(uri)?.use { stream ->
        stream.write(bytes)
      } ?: throw Exception("Unable to open output stream")

      contentValues.clear()
      contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
      resolver.update(uri, contentValues, null, null)

      return uri.toString()
    }

    if (Environment.getExternalStorageState() != Environment.MEDIA_MOUNTED) {
      throw Exception("Storage unavailable")
    }

    val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
    val targetDir = File(downloadsDir, "Farm Africa")
    if (!targetDir.exists()) {
      if (!targetDir.mkdirs()) {
        throw Exception("Unable to create download directory")
      }
    }

    val file = File(targetDir, fileName)
    file.outputStream().use { it.write(bytes) }
    MediaScannerConnection.scanFile(this, arrayOf(file.absolutePath), arrayOf("image/png"), null)
    return file.absolutePath
  }
}
