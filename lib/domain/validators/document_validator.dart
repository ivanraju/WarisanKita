import 'package:file_picker/file_picker.dart';

/// Production-grade validator for artisan verification attachments,
/// including SSM business registration documents and Kraftangan Malaysia accreditation certificates.
class DocumentValidator {
  static const List<String> allowedExtensions = ['pdf', 'png', 'jpg', 'jpeg'];

  /// Minimum file size: 10 KB (to prevent empty or corrupt dummy files)
  static const int minFileSizeBytes = 10 * 1024;

  /// Maximum file size: 10 MB (to avoid memory crashes and Supabase timeouts)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  static const Set<String> _disallowedPlaceholderNames = {
    'dummy.pdf',
    'dummy.png',
    'dummy.jpg',
    'dummy.jpeg',
    'test.pdf',
    'test.png',
    'sample.pdf',
    'sample.png',
    'sample.jpg',
    'placeholder.pdf',
    'empty.pdf',
  };

  /// Validates document metadata (file name and size bounds).
  ///
  /// Returns `null` if the document is valid, or a descriptive error message if invalid.
  static String? validateMetadata({
    String? fileName,
    int? fileSizeBytes,
    required String documentTitle,
    bool isMandatory = true,
  }) {
    if (fileName == null) {
      if (isMandatory) {
        return '$documentTitle is required. Please attach a valid PDF or image.';
      }
      return null;
    }

    final rawName = fileName.trim();
    if (rawName.isEmpty) {
      return '$documentTitle has an invalid file name.';
    }

    final lowerName = rawName.toLowerCase();
    if (_disallowedPlaceholderNames.contains(lowerName) ||
        lowerName.startsWith('dummy') ||
        lowerName.startsWith('fake')) {
      return 'Please attach an authentic, official $documentTitle (dummy placeholders are disallowed).';
    }

    // Extract file extension
    String? ext;
    final dotIndex = rawName.lastIndexOf('.');
    if (dotIndex != -1) {
      ext = rawName.substring(dotIndex + 1).toLowerCase();
    }

    if (ext == null || !allowedExtensions.contains(ext)) {
      return '$documentTitle must be a PDF, PNG, JPG, or JPEG file.';
    }

    // Validate size bounds
    if (fileSizeBytes != null) {
      if (fileSizeBytes > 0 && fileSizeBytes < minFileSizeBytes) {
        final kb = (fileSizeBytes / 1024).toStringAsFixed(1);
        return '$documentTitle file is too small ($kb KB). Authentic documents must be at least 10 KB.';
      }

      if (fileSizeBytes > maxFileSizeBytes) {
        final mb = (fileSizeBytes / (1024 * 1024)).toStringAsFixed(1);
        return '$documentTitle file size ($mb MB) exceeds the 10 MB limit.';
      }
    }

    return null;
  }

  /// Validates a single document file attachment asynchronously.
  ///
  /// Returns `null` if the document is valid, or a descriptive error message if invalid.
  static Future<String?> validateDocument(
    PlatformFile? file, {
    required String documentTitle,
    bool isMandatory = true,
  }) async {
    if (file == null) {
      return validateMetadata(
        fileName: null,
        documentTitle: documentTitle,
        isMandatory: isMandatory,
      );
    }

    int? size;
    try {
      size = await file.length();
    } catch (_) {}

    return validateMetadata(
      fileName: file.name,
      fileSizeBytes: size,
      documentTitle: documentTitle,
      isMandatory: isMandatory,
    );
  }

  /// Formats byte size into a user-friendly string (e.g. "1.2 MB" or "450 KB").
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
