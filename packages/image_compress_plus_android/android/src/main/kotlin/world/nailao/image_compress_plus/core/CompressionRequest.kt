package world.nailao.image_compress_plus.core

data class CompressionRequest(
    val targetWidth: Int,
    val targetHeight: Int,
    val quality: Int,
    val rotate: Int,
    val autoCorrectionAngle: Boolean,
    val targetFormat: TargetFormat,
    val keepExif: Boolean,
    val numberOfRetries: Int = 1,
)

enum class TargetFormat(val formatIndex: Int) {
    JPEG(0),
    PNG(1),
    HEIC(2),
    WEBP(3),
    ;

    val fileExtension: String
        get() = when (this) {
            JPEG -> "jpg"
            PNG -> "png"
            HEIC -> "heic"
            WEBP -> "webp"
        }
}
