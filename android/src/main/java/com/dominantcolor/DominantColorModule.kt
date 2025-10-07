package com.dominantcolor

import com.facebook.react.bridge.*
import com.facebook.react.module.annotations.ReactModule
import androidx.palette.graphics.Palette
import android.graphics.BitmapFactory
import android.graphics.Bitmap
import android.net.Uri
import android.util.Base64
import java.net.URL
import java.net.HttpURLConnection
import java.io.ByteArrayInputStream
import java.io.BufferedInputStream
import java.io.File

@ReactModule(name = DominantColorModule.NAME)
class DominantColorModule(reactContext: ReactApplicationContext) :
  NativeDominantColorSpec(reactContext) {

  override fun getName() = NAME

  @ReactMethod
  override fun getColorPalette(imagePath: String, promise: Promise) {
    if (imagePath.isEmpty()) {
      promise.resolve(null)
      return
    }

    Thread {
      try {
        val bmp = loadBitmap(imagePath)
        if (bmp == null) {
          promise.resolve(null)
          return@Thread
        }

        val palette = Palette.from(bmp).clearFilters().generate()

        fun toHex(color: Int): String {
          val r = (color shr 16) and 0xFF
          val g = (color shr 8) and 0xFF
          val b = color and 0xFF
          return String.format("#%02X%02X%02X", r, g, b)
        }

        val backgroundColor = palette.getDarkMutedColor(
          palette.getDominantColor(0xFF000000.toInt())
        )

        val primarySwatch = palette.vibrantSwatch
          ?: palette.lightVibrantSwatch
          ?: palette.mutedSwatch
          ?: palette.dominantSwatch

        val secondarySwatch = palette.mutedSwatch
          ?: palette.darkVibrantSwatch
          ?: palette.lightMutedSwatch
          ?: palette.dominantSwatch

        val detailSwatch = palette.darkVibrantSwatch
          ?: palette.lightMutedSwatch
          ?: palette.vibrantSwatch
          ?: palette.dominantSwatch

        val map = Arguments.createMap().apply {
          putString("platform", "android")
          putString("background", toHex(backgroundColor))
          putString("primary", toHex(primarySwatch?.rgb ?: backgroundColor))
          putString("secondary", toHex(secondarySwatch?.rgb ?: backgroundColor))
          putString("detail", toHex(detailSwatch?.rgb ?: backgroundColor))
        }

        promise.resolve(map)

      } catch (e: Exception) {
        promise.reject("error_extracting_palette", e.message, e)
      }
    }.start()
  }

  private fun loadBitmap(path: String): Bitmap? = try {
    when {
      path.startsWith("http://") || path.startsWith("https://") -> {
        val url = URL(path)
        val conn = (url.openConnection() as HttpURLConnection).apply {
          connectTimeout = 8000
          readTimeout = 8000
        }
        conn.inputStream.use { input -> BitmapFactory.decodeStream(BufferedInputStream(input)) }
      }
      path.startsWith("data:image") -> {
        val comma = path.indexOf(',')
        if (comma > 0) {
          val base64 = path.substring(comma + 1)
          val bytes = Base64.decode(base64, Base64.DEFAULT)
          ByteArrayInputStream(bytes).use { BitmapFactory.decodeStream(it) }
        } else null
      }
      path.startsWith("file://") || path.startsWith("content://") -> {
        val uri = Uri.parse(path)
        reactApplicationContext.contentResolver.openInputStream(uri)?.use {
          BitmapFactory.decodeStream(it)
        }
      }
      File(path).exists() -> BitmapFactory.decodeFile(path)
      else -> null
    }
  } catch (_: Throwable) {
    null
  }

  companion object {
    const val NAME = "DominantColor"
  }
}
