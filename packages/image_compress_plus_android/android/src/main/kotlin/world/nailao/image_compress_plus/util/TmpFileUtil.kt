package world.nailao.image_compress_plus.util

import android.content.Context
import java.io.File
import java.util.*

object TmpFileUtil {
    fun createTmpFile(context: Context, extension: String = ""): File {
        val string = UUID.randomUUID().toString()
        val suffix = if (extension.isEmpty()) "" else ".$extension"
        return File(context.cacheDir, string + suffix)
    }
}
