package world.nailao.image_compress_plus.core

sealed interface CompressionSource {
    data class Bytes(val value: ByteArray) : CompressionSource

    data class FilePath(val value: String) : CompressionSource
}
