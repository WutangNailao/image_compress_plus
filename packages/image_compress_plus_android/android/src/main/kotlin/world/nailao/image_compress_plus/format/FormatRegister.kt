package world.nailao.image_compress_plus.format

import android.util.SparseArray
import world.nailao.image_compress_plus.handle.FormatHandler

object FormatRegister {
    private val formatMap = SparseArray<FormatHandler>()

    fun registerFormat(handler: FormatHandler) {
        formatMap.append(handler.type, handler)
    }

    fun findFormat(formatIndex: Int): FormatHandler? {
        return formatMap.get(formatIndex)
    }

}