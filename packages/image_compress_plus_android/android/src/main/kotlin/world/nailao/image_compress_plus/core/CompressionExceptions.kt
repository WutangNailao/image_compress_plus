package world.nailao.image_compress_plus.core

open class CompressionException(
    val errorCode: String,
    override val message: String,
    val errorDetails: Any? = null,
    cause: Throwable? = null,
) : RuntimeException(message, cause)

class UnsupportedInputFormatException(details: Any? = null) : CompressionException(
    errorCode = "unsupported_input_format",
    message = "Unsupported input image format.",
    errorDetails = details,
)

class DecodeFailedException(details: Any? = null, cause: Throwable? = null) : CompressionException(
    errorCode = "decode_failed",
    message = "Failed to decode input image.",
    errorDetails = details,
    cause = cause,
)

class UnsupportedOutputFormatException(details: Any? = null) : CompressionException(
    errorCode = "unsupported_output_format",
    message = "Unsupported output image format.",
    errorDetails = details,
)

class EncodeFailedException(details: Any? = null, cause: Throwable? = null) : CompressionException(
    errorCode = "encode_failed",
    message = "Failed to encode output image.",
    errorDetails = details,
    cause = cause,
)

class FileReadFailedException(
    details: Any? = null,
    transient: Boolean = false,
    cause: Throwable? = null,
) : CompressionException(
    errorCode = if (transient) "transient_file_read_failed" else "file_read_failed",
    message = "Failed to read image file.",
    errorDetails = details,
    cause = cause,
)

class FileWriteFailedException(
    details: Any? = null,
    transient: Boolean = false,
    cause: Throwable? = null,
) : CompressionException(
    errorCode = if (transient) "transient_file_write_failed" else "file_write_failed",
    message = "Failed to write compressed image file.",
    errorDetails = details,
    cause = cause,
)

class InvalidRequestException(details: Any? = null) : CompressionException(
    errorCode = "invalid_request",
    message = "Invalid compression request.",
    errorDetails = details,
)

class MetadataPreservationFailedException(
    details: Any? = null,
    cause: Throwable? = null,
) : CompressionException(
    errorCode = "metadata_preservation_failed",
    message = "Failed to preserve image metadata.",
    errorDetails = details,
    cause = cause,
)
