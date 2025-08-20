package com.dominantcolor

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.Arguments
import android.graphics.BitmapFactory
import android.graphics.Bitmap
import androidx.palette.graphics.Palette
import android.net.Uri
import android.util.Base64
import java.net.URL
import java.net.HttpURLConnection
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.io.ByteArrayInputStream
import java.io.InputStream
import java.io.BufferedInputStream
import java.io.File

@ReactModule(name = DominantColorModule.NAME)
class DominantColorModule(reactContext: ReactApplicationContext) :
  NativeDominantColorSpec(reactContext) {

  override fun getName(): String {
    return NAME
  }

  override fun getColorPalette(imagePath: String): WritableMap? {
    val bmp = loadBitmap(imagePath) ?: return null
    val palette = Palette.from(bmp).clearFilters().generate()

    fun toHex(color: Int): String {
      val r = (color shr 16 and 0xFF)
      val g = (color shr 8 and 0xFF)
      val b = (color and 0xFF)
      return String.format("#%02X%02X%02X", r, g, b)
    }

    // Heuristic mapping similar to iOS background/primary/secondary/detail
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

    val map: WritableMap = Arguments.createMap()
    map.putString("platform", "android")
    map.putString("background", toHex(backgroundColor))
    map.putString("primary", toHex(primarySwatch?.rgb ?: backgroundColor))
    map.putString("secondary", toHex(secondarySwatch?.rgb ?: backgroundColor))
    map.putString("detail", toHex(detailSwatch?.rgb ?: backgroundColor))

    return map
  }

  private fun loadBitmap(path: String): Bitmap? {
    return try {
      when {
        path.startsWith("http://") || path.startsWith("https://") -> {
          val executor = Executors.newSingleThreadExecutor()
          try {
            val task = executor.submit(Callable {
              val url = URL(path)
              val conn = (url.openConnection() as HttpURLConnection).apply {
                connectTimeout = 8000
                readTimeout = 8000
              }
              conn.inputStream.use { input -> BitmapFactory.decodeStream(BufferedInputStream(input)) }
            })
            task.get(10, TimeUnit.SECONDS)
          } finally {
            executor.shutdownNow()
          }
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
          reactApplicationContext.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it) }
        }
        File(path).exists() -> {
          BitmapFactory.decodeFile(path)
        }
        else -> null
      }
    } catch (_: Throwable) {
      null
    }
  }

  companion object {
    const val NAME = "DominantColor"
  }
}
