package world.nailao.image_compress_plus

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import java.io.IOException
import java.nio.channels.ClosedByInterruptException
import world.nailao.image_compress_plus.core.CompressionPipeline
import world.nailao.image_compress_plus.core.CompressionException
import world.nailao.image_compress_plus.core.CompressionRequest
import world.nailao.image_compress_plus.core.CompressionSource
import world.nailao.image_compress_plus.core.InvalidRequestException
import world.nailao.image_compress_plus.core.ResultHandler
import world.nailao.image_compress_plus.core.TargetFormat
import world.nailao.image_compress_plus.core.UnsupportedOutputFormatException

class ImageCompressPlugin : FlutterPlugin, ImageCompressPlusHostApi {
    private lateinit var context: Context
    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var pipeline: CompressionPipeline

    companion object {
        var showLog = false
    }

    override fun compressWithList(
        image: ByteArray,
        targetWidth: Long,
        targetHeight: Long,
        quality: Long,
        rotate: Long,
        autoCorrectionAngle: Boolean,
        targetFormat: HostFormat,
        keepExif: Boolean,
        callback: (Result<ByteArray>) -> Unit
    ) {
        ResultHandler.threadPool.execute {
            val result = runCatching {
                pipeline.compressToBytes(
                    CompressionSource.Bytes(image),
                    makeRequest(
                        targetWidth = targetWidth,
                        targetHeight = targetHeight,
                        quality = quality,
                        rotate = rotate,
                        autoCorrectionAngle = autoCorrectionAngle,
                        targetFormat = targetFormat,
                        keepExif = keepExif,
                        numberOfRetries = 1,
                    ),
                )
            }.mapError()
            postResult(callback, result)
        }
    }

    override fun compressWithFile(
        path: String,
        targetWidth: Long,
        targetHeight: Long,
        quality: Long,
        rotate: Long,
        autoCorrectionAngle: Boolean,
        targetFormat: HostFormat,
        keepExif: Boolean,
        numberOfRetries: Long,
        callback: (Result<ByteArray?>) -> Unit
    ) {
        ResultHandler.threadPool.execute {
            val result = runCatching {
                pipeline.compressToBytes(
                    CompressionSource.FilePath(path),
                    makeRequest(
                        targetWidth = targetWidth,
                        targetHeight = targetHeight,
                        quality = quality,
                        rotate = rotate,
                        autoCorrectionAngle = autoCorrectionAngle,
                        targetFormat = targetFormat,
                        keepExif = keepExif,
                        numberOfRetries = numberOfRetries.toInt(),
                    ),
                )
            }.mapError().map { it as ByteArray? }
            postResult(callback, result)
        }
    }

    override fun compressWithFileAndGetFile(
        path: String,
        targetWidth: Long,
        targetHeight: Long,
        quality: Long,
        targetPath: String,
        rotate: Long,
        autoCorrectionAngle: Boolean,
        targetFormat: HostFormat,
        keepExif: Boolean,
        numberOfRetries: Long,
        callback: (Result<String?>) -> Unit
    ) {
        ResultHandler.threadPool.execute {
            val result = runCatching {
                pipeline.compressToFile(
                    CompressionSource.FilePath(path),
                    targetPath,
                    makeRequest(
                        targetWidth = targetWidth,
                        targetHeight = targetHeight,
                        quality = quality,
                        rotate = rotate,
                        autoCorrectionAngle = autoCorrectionAngle,
                        targetFormat = targetFormat,
                        keepExif = keepExif,
                        numberOfRetries = numberOfRetries.toInt(),
                    ),
                )
            }.mapError().map { it as String? }
            postResult(callback, result)
        }
    }

    override fun showLog(value: Boolean, callback: (Result<Unit>) -> Unit) {
        showLog = value
        postResult(callback, Result.success(Unit))
    }

    private fun <T> postResult(callback: (Result<T>) -> Unit, result: Result<T>) {
        mainHandler.post { callback(result) }
    }

    private fun makeRequest(
        targetWidth: Long,
        targetHeight: Long,
        quality: Long,
        rotate: Long,
        autoCorrectionAngle: Boolean,
        targetFormat: HostFormat,
        keepExif: Boolean,
        numberOfRetries: Int,
    ): CompressionRequest {
        validateRange("targetWidth", targetWidth, min = 1)
        validateRange("targetHeight", targetHeight, min = 1)
        validateRange("quality", quality, min = 0, max = 100)
        validateRange("numberOfRetries", numberOfRetries.toLong(), min = 1)

        val convertedFormat = convertHostFormat(targetFormat)
        if (convertedFormat == TargetFormat.HEIC && Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            throw UnsupportedOutputFormatException(
                details = "format=heic, minSdk=28, sdkInt=${Build.VERSION.SDK_INT}",
            )
        }

        return CompressionRequest(
            targetWidth = targetWidth.toInt(),
            targetHeight = targetHeight.toInt(),
            quality = quality.toInt(),
            rotate = rotate.toInt(),
            autoCorrectionAngle = autoCorrectionAngle,
            targetFormat = convertedFormat,
            keepExif = keepExif,
            numberOfRetries = numberOfRetries,
        )
    }

    private fun convertHostFormat(format: HostFormat): TargetFormat {
        return when (format) {
            HostFormat.JPEG -> TargetFormat.JPEG
            HostFormat.PNG -> TargetFormat.PNG
            HostFormat.HEIC -> TargetFormat.HEIC
            HostFormat.WEBP -> TargetFormat.WEBP
        }
    }

    private fun validateRange(
        field: String,
        value: Long,
        min: Long? = null,
        max: Long? = null,
    ) {
        if (value < Int.MIN_VALUE || value > Int.MAX_VALUE) {
            throw InvalidRequestException(details = "$field=$value is out of Int range")
        }
        if (min != null && value < min) {
            throw InvalidRequestException(details = "$field=$value must be >= $min")
        }
        if (max != null && value > max) {
            throw InvalidRequestException(details = "$field=$value must be <= $max")
        }
    }

    private fun <T> Result<T>.mapError(): Result<T> {
        return fold(
            onSuccess = { Result.success(it) },
            onFailure = { error ->
                if (showLog) {
                    error.printStackTrace()
                }
                Result.failure(toFlutterError(error))
            },
        )
    }

    private fun toFlutterError(error: Throwable): FlutterError {
        return when (error) {
            is FlutterError -> error
            is CompressionException -> FlutterError(
                error.errorCode,
                error.message,
                error.errorDetails,
            )
            is ClosedByInterruptException -> FlutterError(
                "transient_file_read_failed",
                "Failed to read image file.",
                error.message,
            )
            is IOException -> FlutterError("file_read_failed", "Failed to read image file.", error.message)
            else -> FlutterError("compress_failed", error.message, null)
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        pipeline = CompressionPipeline(context)
        ImageCompressPlusHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        ImageCompressPlusHostApi.setUp(binding.binaryMessenger, null)
    }
}
