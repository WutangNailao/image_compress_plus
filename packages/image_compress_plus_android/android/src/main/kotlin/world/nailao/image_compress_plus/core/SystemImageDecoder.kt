package world.nailao.image_compress_plus.core

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.os.Build
import java.io.File
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.channels.ClosedByInterruptException

class SystemImageDecoder {
    fun decode(source: CompressionSource, sampleSize: Int): Bitmap {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            decodeWithImageDecoder(source, sampleSize)
        } else {
            decodeWithBitmapFactory(source, sampleSize)
        }
    }

    private fun decodeWithBitmapFactory(source: CompressionSource, sampleSize: Int): Bitmap {
        val options = BitmapFactory.Options().apply {
            inJustDecodeBounds = false
            inPreferredConfig = Bitmap.Config.RGB_565
            inSampleSize = sampleSize
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                @Suppress("DEPRECATION")
                inDither = true
            }
        }

        val bitmap = try {
            when (source) {
                is CompressionSource.Bytes -> BitmapFactory.decodeByteArray(
                    source.value,
                    0,
                    source.value.size,
                    options,
                )
                is CompressionSource.FilePath -> {
                    val file = File(source.value)
                    if (!file.exists()) {
                        throw FileReadFailedException(details = "path=${source.value}")
                    }
                    BitmapFactory.decodeFile(source.value, options)
                }
            }
        } catch (error: CompressionException) {
            throw error
        } catch (error: Exception) {
            throw decodeExceptionFor(source, error)
        }

        return bitmap ?: throw unsupportedInputFormat(source)
    }

    private fun decodeWithImageDecoder(source: CompressionSource, sampleSize: Int): Bitmap {
        val imageSource = when (source) {
            is CompressionSource.Bytes -> ImageDecoder.createSource(ByteBuffer.wrap(source.value))
            is CompressionSource.FilePath -> {
                val file = File(source.value)
                if (!file.exists()) {
                    throw FileReadFailedException(details = "path=${source.value}")
                }
                ImageDecoder.createSource(file)
            }
        }

        try {
            return ImageDecoder.decodeBitmap(imageSource) { decoder, _, _ ->
                decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
                if (sampleSize > 1) {
                    decoder.setTargetSampleSize(sampleSize)
                }
            }
        } catch (error: CompressionException) {
            throw error
        } catch (error: Exception) {
            throw decodeExceptionFor(source, error)
        }
    }

    private fun unsupportedInputFormat(source: CompressionSource): UnsupportedInputFormatException {
        return UnsupportedInputFormatException(
            details = when (source) {
                is CompressionSource.Bytes -> "source=bytes"
                is CompressionSource.FilePath -> "path=${source.value}"
            },
        )
    }

    private fun decodeExceptionFor(
        source: CompressionSource,
        error: Exception,
    ): CompressionException {
        val details = when (source) {
            is CompressionSource.Bytes -> "source=bytes"
            is CompressionSource.FilePath -> "path=${source.value}"
        }

        return when (error) {
            is ClosedByInterruptException -> FileReadFailedException(
                details = details,
                transient = true,
                cause = error,
            )
            is IOException -> FileReadFailedException(details = details, cause = error)
            is IllegalArgumentException -> UnsupportedInputFormatException(details = details)
            else -> DecodeFailedException(details = details, cause = error)
        }
    }
}
