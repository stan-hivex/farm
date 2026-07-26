package com.mycompany.farm

import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.IOException

class QrDownloadService: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "farm.qr_download_service")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "downloadQr" -> {
        val bytes = call.argument<ByteArray>("bytes")
        val fileName = call.argument<String>("fileName")
        if (bytes == null || fileName == null) {
          result.error("INVALID_ARGUMENTS", "Missing bytes or fileName", null)
          return
        }
        try {
          val savedUri = saveQrImage(bytes, fileName)
          result.success(mapOf(
            "success" to true,
            "message" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
              "Saved to Downloads/Farm Africa"
            } else {
              "Saved to Downloads/Farm Africa"
            },
            "fileUri" to savedUri,
            "destination" to "downloads"
          ))
        } catch (error: IOException) {
          result.success(mapOf(
            "success" to false,
            "message" to "Save failed: ${error.message}",
            "destination" to "unknown"
          ))
        }
      }
      else -> result.notImplemented()
    }
  }

  @Throws(IOException::class)
  private fun saveQrImage(bytes: ByteArray, fileName: String): String {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      val contentValues = ContentValues().apply {
        put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
        put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
        put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/Farm Africa")
        put(MediaStore.MediaColumns.IS_PENDING, 1)
      }

      val resolver = context.contentResolver
      val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
        ?: throw IOException("Unable to create MediaStore entry")

      resolver.openOutputStream(uri)?.use { stream ->
        stream.write(bytes)
      } ?: throw IOException("Unable to open output stream")

      contentValues.clear()
      contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
      resolver.update(uri, contentValues, null, null)

      scanFile(uri.toString())
      return uri.toString()
    }

    val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
    val targetDir = File(downloadsDir, "Farm Africa")
    if (!targetDir.exists()) {
      targetDir.mkdirs()
    }

    val file = File(targetDir, fileName)
    file.outputStream().use { it.write(bytes) }
    scanFile(file.absolutePath)
    return file.absolutePath
  }

  private fun scanFile(path: String) {
    MediaScannerConnection.scanFile(context, arrayOf(path), null, null)
  }
}
