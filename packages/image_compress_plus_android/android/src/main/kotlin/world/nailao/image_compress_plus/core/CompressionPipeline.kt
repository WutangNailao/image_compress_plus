package world.nailao.image_compress_plus.core

import android.content.Context
import android.graphics.Bitmap
import world.nailao.image_compress_plus.exif.Exif
import world.nailao.image_compress_plus.ext.calcScale
import world.nailao.image_compress_plus.ext.rotate
import world.nailao.image_compress_plus.logger.log

class CompressionPipeline(
    private val context: Context,
    private val decoder: SystemImageDecoder = SystemImageDecoder(),
) {
    private val encoders: Map<TargetFormat, ImageEncoder> = mapOf(
        TargetFormat.JPEG to BitmapImageEncoder(Bitmap.CompressFormat.JPEG),
        TargetFormat.PNG to BitmapImageEncoder(Bitmap.CompressFormat.PNG),
        TargetFormat.WEBP to BitmapImageEncoder(Bitmap.CompressFormat.WEBP),
        TargetFormat.HEIC to HeifImageEncoder(),
    )

    fun compressToBytes(source: CompressionSource, request: CompressionRequest): ByteArray {
        return runWithRetries(request.numberOfRetries) { sampleSize ->
            val normalized = normalizeRequest(source, request)
            val decodedBitmap = decoder.decode(source, sampleSize)
            val transformedBitmap = transformBitmap(decodedBitmap, normalized)
            try {
                findEncoder(normalized.targetFormat).encodeToByteArray(
                    context,
                    transformedBitmap,
                    source,
                    normalized,
                )
            } finally {
                if (transformedBitmap !== decodedBitmap) {
                    transformedBitmap.recycle()
                }
                decodedBitmap.recycle()
            }
        }
    }

    fun compressToFile(
        source: CompressionSource,
        targetPath: String,
        request: CompressionRequest,
    ): String {
        return runWithRetries(request.numberOfRetries) { sampleSize ->
            val normalized = normalizeRequest(source, request)
            val decodedBitmap = decoder.decode(source, sampleSize)
            val transformedBitmap = transformBitmap(decodedBitmap, normalized)
            try {
                findEncoder(normalized.targetFormat).encodeToFile(
                    context,
                    transformedBitmap,
                    source,
                    normalized,
                    targetPath,
                )
            } finally {
                if (transformedBitmap !== decodedBitmap) {
                    transformedBitmap.recycle()
                }
                decodedBitmap.recycle()
            }
        }
    }

    private fun <T> runWithRetries(numberOfRetries: Int, work: (sampleSize: Int) -> T): T {
        var attempt = 0
        var sampleSize = 1
        var lastError: Throwable? = null
        while (attempt < numberOfRetries) {
            try {
                return work(sampleSize)
            } catch (error: OutOfMemoryError) {
                lastError = error
                sampleSize *= 2
                attempt += 1
            }
        }
        throw lastError ?: IllegalStateException("Failed to compress image.")
    }

    private fun normalizeRequest(
        source: CompressionSource,
        request: CompressionRequest,
    ): CompressionRequest {
        if (!request.autoCorrectionAngle) {
            return request
        }
        val exifRotate = when (source) {
            is CompressionSource.Bytes -> Exif.getRotationDegrees(source.value)
            is CompressionSource.FilePath -> Exif.getRotationDegrees(java.io.File(source.value))
        }
        if (exifRotate == 90 || exifRotate == 270) {
            return request.copy(
                targetWidth = request.targetHeight,
                targetHeight = request.targetWidth,
                rotate = request.rotate + exifRotate,
            )
        }
        return request.copy(rotate = request.rotate + exifRotate)
    }

    private fun transformBitmap(bitmap: Bitmap, request: CompressionRequest): Bitmap {
        val width = bitmap.width.toFloat()
        val height = bitmap.height.toFloat()
        log("src width = $width")
        log("src height = $height")
        val scale = bitmap.calcScale(request.targetWidth, request.targetHeight)
        log("scale = $scale")
        val destinationWidth = (width / scale).toInt()
        val destinationHeight = (height / scale).toInt()
        log("dst width = $destinationWidth")
        log("dst height = $destinationHeight")

        val scaledBitmap = if (
            destinationWidth == bitmap.width &&
            destinationHeight == bitmap.height
        ) {
            bitmap
        } else {
            Bitmap.createScaledBitmap(bitmap, destinationWidth, destinationHeight, true)
        }

        return if (request.rotate % 360 != 0) {
            val rotatedBitmap = scaledBitmap.rotate(request.rotate)
            if (scaledBitmap !== bitmap) {
                scaledBitmap.recycle()
            }
            rotatedBitmap
        } else {
            scaledBitmap
        }
    }

    private fun findEncoder(format: TargetFormat): ImageEncoder {
        return encoders[format] ?: throw UnsupportedOutputFormatException(details = format.name.lowercase())
    }
}
