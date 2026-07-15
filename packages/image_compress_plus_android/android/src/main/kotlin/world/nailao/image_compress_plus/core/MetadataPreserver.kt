package world.nailao.image_compress_plus.core

import android.content.Context
import androidx.exifinterface.media.ExifInterface
import world.nailao.image_compress_plus.logger.log
import world.nailao.image_compress_plus.util.TmpFileUtil
import java.io.ByteArrayInputStream
import java.io.File

internal class MetadataPreserver {
    fun preserveToBytes(
        context: Context,
        source: CompressionSource,
        encodedBytes: ByteArray,
        request: CompressionRequest,
    ): ByteArray {
        try {
            val tmpFile = TmpFileUtil.createTmpFile(context, request.targetFormat.fileExtension)
            return try {
                tmpFile.writeBytes(encodedBytes)
                applyMetadataToFile(source, tmpFile, shouldPreserveOriginalOrientation(request))
                tmpFile.readBytes()
            } finally {
                tmpFile.delete()
            }
        } catch (error: CompressionException) {
            throw error
        } catch (error: Exception) {
            log("Metadata preservation failed: ${error.message}")
            throw MetadataPreservationFailedException(
                details = metadataFailureDetails(source, request),
                cause = error,
            )
        }
    }

    fun preserveToFile(
        source: CompressionSource,
        targetFile: File,
        request: CompressionRequest,
    ) {
        try {
            applyMetadataToFile(source, targetFile, shouldPreserveOriginalOrientation(request))
        } catch (error: CompressionException) {
            throw error
        } catch (error: Exception) {
            log("Metadata preservation failed for ${targetFile.absolutePath}: ${error.message}")
            throw MetadataPreservationFailedException(
                details = metadataFailureDetails(source, request, targetFile.absolutePath),
                cause = error,
            )
        }
    }

    private fun metadataFailureDetails(
        source: CompressionSource,
        request: CompressionRequest,
        targetPath: String? = null,
    ): String {
        val sourceDetails = when (source) {
            is CompressionSource.Bytes -> "source=bytes"
            is CompressionSource.FilePath -> "path=${source.value}"
        }
        val targetDetails = targetPath?.let { ", targetPath=$it" } ?: ""
        return "$sourceDetails, targetFormat=${request.targetFormat.fileExtension}$targetDetails"
    }

    private fun applyMetadataToFile(
        source: CompressionSource,
        targetFile: File,
        preserveOriginalOrientation: Boolean,
    ) {
        val sourceExif = createSourceExif(source)
        val targetExif = ExifInterface(targetFile.absolutePath)

        for (tag in safeTagsToCopy) {
            val value = sourceExif.getAttribute(tag)
            if (value != null) {
                targetExif.setAttribute(tag, value)
            } else {
                targetExif.setAttribute(tag, null)
            }
        }

        targetExif.setAttribute(
            ExifInterface.TAG_ORIENTATION,
            if (preserveOriginalOrientation) {
                sourceExif.getAttribute(ExifInterface.TAG_ORIENTATION)
                    ?: ExifInterface.ORIENTATION_NORMAL.toString()
            } else {
                ExifInterface.ORIENTATION_NORMAL.toString()
            },
        )
        targetExif.saveAttributes()
    }

    private fun createSourceExif(source: CompressionSource): ExifInterface {
        return when (source) {
            is CompressionSource.Bytes -> ExifInterface(ByteArrayInputStream(source.value))
            is CompressionSource.FilePath -> ExifInterface(source.value)
        }
    }

    private fun shouldPreserveOriginalOrientation(request: CompressionRequest): Boolean {
        return !request.autoCorrectionAngle && request.rotate % 360 == 0
    }

    companion object {
        // Mirrors the iOS strategy more closely: preserve broadly useful metadata,
        // but avoid stale thumbnails and vendor/private payloads that no longer
        // match the transformed image after resize/rotate/re-encode.
        private val safeTagsToCopy = listOf(
            "ApertureValue",
            "Artist",
            "BitsPerSample",
            "BodySerialNumber",
            "BrightnessValue",
            "CFAPattern",
            "ColorSpace",
            "ComponentsConfiguration",
            "Compression",
            "Contrast",
            "Copyright",
            "DateTime",
            "DateTimeDigitized",
            "DateTimeOriginal",
            "DefaultCropSize",
            "DeviceSettingDescription",
            "DigitalZoomRatio",
            "ExifVersion",
            "ExposureBiasValue",
            "ExposureIndex",
            "ExposureMode",
            "ExposureProgram",
            "ExposureTime",
            "FileSource",
            "Flash",
            "FlashpixVersion",
            "FlashEnergy",
            "FocalLength",
            "FocalLengthIn35mmFilm",
            "FocalPlaneResolutionUnit",
            "FocalPlaneXResolution",
            "FocalPlaneYResolution",
            "FNumber",
            "GainControl",
            "Gamma",
            "GPSAltitude",
            "GPSAltitudeRef",
            "GPSAreaInformation",
            "GPSDateStamp",
            "GPSDestBearing",
            "GPSDestBearingRef",
            "GPSDestDistance",
            "GPSDestDistanceRef",
            "GPSDestLatitude",
            "GPSDestLatitudeRef",
            "GPSDestLongitude",
            "GPSDestLongitudeRef",
            "GPSDifferential",
            "GPSDOP",
            "GPSHPositioningError",
            "GPSImgDirection",
            "GPSImgDirectionRef",
            "GPSLatitude",
            "GPSLatitudeRef",
            "GPSLongitude",
            "GPSLongitudeRef",
            "GPSMapDatum",
            "GPSMeasureMode",
            "GPSProcessingMethod",
            "GPSSatellites",
            "GPSSpeed",
            "GPSSpeedRef",
            "GPSStatus",
            "GPSTimeStamp",
            "GPSTrack",
            "GPSTrackRef",
            "GPSVersionID",
            "ImageDescription",
            "ImageUniqueID",
            "InteroperabilityIndex",
            "ISOSpeed",
            "ISOSpeedLatitudeyyy",
            "ISOSpeedLatitudezzz",
            "ISOSpeedRatings",
            "LensMake",
            "LensModel",
            "LensSerialNumber",
            "LensSpecification",
            "LightSource",
            "Make",
            "MaxApertureValue",
            "MeteringMode",
            "Model",
            "OECF",
            "OffsetTime",
            "OffsetTimeDigitized",
            "OffsetTimeOriginal",
            "PhotographicSensitivity",
            "PhotometricInterpretation",
            "PlanarConfiguration",
            "PrimaryChromaticities",
            "RecommendedExposureIndex",
            "ReferenceBlackWhite",
            "RelatedSoundFile",
            "ResolutionUnit",
            "RowsPerStrip",
            "RW2ISO",
            "RW2JpgFromRaw",
            "RW2SensorBottomBorder",
            "RW2SensorLeftBorder",
            "RW2SensorRightBorder",
            "RW2SensorTopBorder",
            "SamplesPerPixel",
            "Saturation",
            "SceneCaptureType",
            "SceneType",
            "SensingMethod",
            "SensitivityType",
            "Sharpness",
            "ShutterSpeedValue",
            "Software",
            "SpatialFrequencyResponse",
            "SpectralSensitivity",
            "StandardOutputSensitivity",
            "StripByteCounts",
            "StripOffsets",
            "SubfileType",
            "SubjectArea",
            "SubjectDistance",
            "SubjectDistanceRange",
            "SubjectLocation",
            "SubSecTime",
            "SubSecTimeDigitized",
            "SubSecTimeOriginal",
            "TransferFunction",
            "UserComment",
            "WhiteBalance",
            "WhitePoint",
            "Xmp",
            "XResolution",
            "YCbCrCoefficients",
            "YCbCrPositioning",
            "YCbCrSubSampling",
            "YResolution",
        )
    }
}
