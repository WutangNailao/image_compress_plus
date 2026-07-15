package world.nailao.image_compress_plus.core

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Bitmap.CompressFormat
import android.os.Build
import androidx.heifwriter.HeifWriter
import world.nailao.image_compress_plus.util.TmpFileUtil
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.IOException
import java.nio.channels.ClosedByInterruptException

internal interface ImageEncoder {
    fun encodeToByteArray(
        context: Context,
        bitmap: Bitmap,
        source: CompressionSource,
        request: CompressionRequest,
    ): ByteArray

    fun encodeToFile(
        context: Context,
        bitmap: Bitmap,
        source: CompressionSource,
        request: CompressionRequest,
        targetPath: String,
    ): String
}

internal class BitmapImageEncoder(
    private val format: CompressFormat,
    private val metadataPreserver: MetadataPreserver = MetadataPreserver(),
) : ImageEncoder {
    override fun encodeToByteArray(
        context: Context,
        bitmap: Bitmap,
        source: CompressionSource,
        request: CompressionRequest,
    ): ByteArray {
        try {
            val outputStream = ByteArrayOutputStream()
            writeCompressedBitmap(bitmap, request, outputStream)
            val encoded = outputStream.toByteArray()
            return if (request.keepExif) {
                metadataPreserver.preserveToBytes(context, source, encoded, request)
            } else {
                encoded
            }
        } catch (error: CompressionException) {
            throw error
        } catch (error: Exception) {
            throw EncodeFailedException(details = "format=$format", cause = error)
        }
    }

    override fun encodeToFile(
        context: Context,
        bitmap: Bitmap,
        source: CompressionSource,
        request: CompressionRequest,
        targetPath: String,
    ): String {
        try {
            File(targetPath).outputStream().use { outputStream ->
                writeCompressedBitmap(bitmap, request, outputStream)
            }
            if (request.keepExif) {
                metadataPreserver.preserveToFile(source, File(targetPath), request)
            }
            return targetPath
        } catch (error: CompressionException) {
            throw error
        } catch (error: ClosedByInterruptException) {
            throw FileWriteFailedException(
                details = "path=$targetPath",
                transient = true,
                cause = error,
            )
        } catch (error: IOException) {
            throw FileWriteFailedException(
                details = "path=$targetPath",
                cause = error,
            )
        } catch (error: Exception) {
            throw FileWriteFailedException(
                details = "path=$targetPath",
                cause = error,
            )
        }
    }

    private fun writeCompressedBitmap(
        bitmap: Bitmap,
        request: CompressionRequest,
        outputStream: java.io.OutputStream,
    ) {
        val success = bitmap.compress(format, request.quality, outputStream)
        if (!success) {
            throw EncodeFailedException(details = "format=$format")
        }
    }
}

internal class HeifImageEncoder : ImageEncoder {
    private val metadataPreserver = MetadataPreserver()

    override fun encodeToByteArray(
        context: Context,
        bitmap: Bitmap,
        source: CompressionSource,
        request: CompressionRequest,
    ): ByteArray {
        val tmpFile = TmpFileUtil.createTmpFile(context)
        try {
            encodeBitmapToHeif(bitmap, tmpFile.absolutePath, request.quality)
            val encoded = tmpFile.readBytes()
            return if (request.keepExif) {
                metadataPreserver.preserveToBytes(context, source, encoded, request)
            } else {
                encoded
            }
        } catch (error: CompressionException) {
            throw error
        } catch (error: ClosedByInterruptException) {
            throw FileWriteFailedException(
                details = "format=heic",
                transient = true,
                cause = error,
            )
        } catch (error: IOException) {
            throw FileWriteFailedException(details = "format=heic", cause = error)
        } catch (error: Exception) {
            throw EncodeFailedException(details = "format=heic", cause = error)
        } finally {
            tmpFile.delete()
        }
    }

    override fun encodeToFile(
        context: Context,
        bitmap: Bitmap,
        source: CompressionSource,
        request: CompressionRequest,
        targetPath: String,
    ): String {
        try {
            encodeBitmapToHeif(bitmap, targetPath, request.quality)
            if (request.keepExif) {
                metadataPreserver.preserveToFile(source, File(targetPath), request)
            }
            return targetPath
        } catch (error: CompressionException) {
            throw error
        } catch (error: ClosedByInterruptException) {
            throw FileWriteFailedException(
                details = "path=$targetPath",
                transient = true,
                cause = error,
            )
        } catch (error: IOException) {
            throw FileWriteFailedException(details = "path=$targetPath", cause = error)
        } catch (error: Exception) {
            throw FileWriteFailedException(details = "path=$targetPath", cause = error)
        }
    }

    private fun encodeBitmapToHeif(bitmap: Bitmap, targetPath: String, quality: Int) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            throw UnsupportedOutputFormatException(details = "format=heic, minSdk=28")
        }
        val heifWriter = HeifWriter.Builder(
            targetPath,
            bitmap.width,
            bitmap.height,
            HeifWriter.INPUT_MODE_BITMAP,
        ).setQuality(quality).setMaxImages(1).build()
        try {
            heifWriter.start()
            heifWriter.addBitmap(bitmap)
            heifWriter.stop(5000)
        } catch (error: Exception) {
            throw EncodeFailedException(details = "format=heic", cause = error)
        } finally {
            heifWriter.close()
        }
    }
}
