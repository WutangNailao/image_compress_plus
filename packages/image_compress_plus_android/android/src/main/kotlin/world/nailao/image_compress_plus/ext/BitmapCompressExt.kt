package world.nailao.image_compress_plus.ext

import android.graphics.Bitmap
import android.graphics.Matrix
import world.nailao.image_compress_plus.ImageCompressPlugin
import kotlin.math.max
import kotlin.math.min

private fun log(any: Any?) {
    if (ImageCompressPlugin.showLog) {
        println(any ?: "null")
    }
}

fun Bitmap.rotate(rotate: Int): Bitmap {
    return if (rotate % 360 != 0) {
        val matrix = Matrix()
        matrix.setRotate(rotate.toFloat())
        // 围绕原地进行旋转
        Bitmap.createBitmap(this, 0, 0, width, height, matrix, false)
    } else {
        this
    }
}

fun Bitmap.calcScale(minWidth: Int, minHeight: Int): Float {
    val w = width.toFloat()
    val h = height.toFloat()
    val scaleW = w / minWidth.toFloat()
    val scaleH = h / minHeight.toFloat()
    log("width scale = $scaleW")
    log("height scale = $scaleH")
    return max(1f, min(scaleW, scaleH))
}
