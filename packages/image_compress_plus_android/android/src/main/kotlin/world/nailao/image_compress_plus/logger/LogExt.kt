package world.nailao.image_compress_plus.logger

import android.util.Log
import world.nailao.image_compress_plus.ImageCompressPlugin

fun log(any: Any?) {
  if (ImageCompressPlugin.showLog) {
    Log.i("image_compress_plus", any?.toString() ?: "null")
  }
}
