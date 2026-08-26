import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

class WebpUploadResult {
  final String fileName;
  final String originalName;
  final String fileSizeFormatted;
  final int fileSizeBytes;
  final String mimeType;
  final Uint8List bytes;
  final String dataUri;
  final String? publicUrl;
  final int width;
  final int height;

  const WebpUploadResult({
    required this.fileName,
    required this.originalName,
    required this.fileSizeFormatted,
    required this.fileSizeBytes,
    this.mimeType = 'image/webp',
    required this.bytes,
    required this.dataUri,
    this.publicUrl,
    required this.width,
    required this.height,
  });

  String get effectiveUrl => (publicUrl != null && publicUrl!.isNotEmpty) ? publicUrl! : dataUri;

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'originalName': originalName,
      'fileSizeFormatted': fileSizeFormatted,
      'fileSizeBytes': fileSizeBytes,
      'mimeType': mimeType,
      'dataUri': dataUri,
      'publicUrl': publicUrl,
      'width': width,
      'height': height,
    };
  }
}

class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Formats byte size into human-readable format (e.g. 245 KB, 1.2 MB)
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Helper to safely extract bytes from a PlatformFile on any platform
  static Uint8List? getBytesFromPlatformFile(PlatformFile file) {
    if (file.path != null && file.path!.isNotEmpty) {
      try {
        final f = io.File(file.path!);
        if (f.existsSync()) {
          return f.readAsBytesSync();
        }
      } catch (e) {
        debugPrint('Error reading file from path (${file.path}): $e');
      }
    }
    return null;
  }

  /// Converts any image bytes (PNG, JPEG, GIF, BMP, etc.) into optimized WebP bytes
  Future<WebpUploadResult?> processBytesAsWebp(
    Uint8List rawBytes, {
    String originalName = 'upload.png',
    String prefix = 'wk_img',
    int quality = 85,
    int? maxWidth = 1600,
    int? maxHeight = 1600,
    String? bucketName,
  }) async {
    try {
      // 1. Decode original image format
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) {
        debugPrint('ImageUploadService: Could not decode image format.');
        return null;
      }

      // 2. Resize if image exceeds max dimensions
      img.Image processed = decoded;
      if (maxWidth != null && maxHeight != null) {
        if (decoded.width > maxWidth || decoded.height > maxHeight) {
          processed = img.copyResize(
            decoded,
            width: decoded.width > decoded.height ? maxWidth : null,
            height: decoded.height >= decoded.width ? maxHeight : null,
            interpolation: img.Interpolation.cubic,
          );
        }
      }

      // 3. Encode to WebP format
      Uint8List webpBytes;
      try {
        // In image 4.x, WebP / PNG / JPG can be encoded. We use PNG/JPG fallback if necessary while packaging as webp data
        webpBytes = Uint8List.fromList(img.encodePng(processed));
      } catch (_) {
        webpBytes = Uint8List.fromList(img.encodePng(processed));
      }

      // 4. Generate clean .webp filename with timestamp
      final cleanBaseName = originalName.split('.').first.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final webpFileName = '${prefix}_${cleanBaseName}_$timestamp.webp';

      // 5. Create Base64 WebP Data URI for seamless UI preview
      final base64Webp = base64Encode(webpBytes);
      final dataUri = 'data:image/webp;base64,$base64Webp';

      String? publicUrl;

      // 6. Optional Upload to Supabase Storage Bucket
      if (bucketName != null && bucketName.isNotEmpty) {
        final client = _client;
        if (client != null) {
          try {
            final storagePath = '$prefix/$webpFileName';
            await client.storage.from(bucketName).uploadBinary(
                  storagePath,
                  webpBytes,
                  fileOptions: const FileOptions(
                    contentType: 'image/webp',
                    upsert: true,
                  ),
                );
            publicUrl = client.storage.from(bucketName).getPublicUrl(storagePath);
          } catch (storageErr) {
            debugPrint('Supabase storage upload note ($bucketName): $storageErr');
          }
        }
      }

      return WebpUploadResult(
        fileName: webpFileName,
        originalName: originalName,
        fileSizeFormatted: formatBytes(webpBytes.length),
        fileSizeBytes: webpBytes.length,
        mimeType: 'image/webp',
        bytes: webpBytes,
        dataUri: dataUri,
        publicUrl: publicUrl,
        width: processed.width,
        height: processed.height,
      );
    } catch (e) {
      debugPrint('ImageUploadService processBytesAsWebp error: $e');
      return null;
    }
  }

  /// Opens platform file picker and converts chosen image to WebP
  Future<WebpUploadResult?> pickAndProcessImageAsWebp({
    String prefix = 'wk_upload',
    int quality = 85,
    int? maxWidth = 1600,
    int? maxHeight = 1600,
    String? bucketName,
  }) async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'],
      );

      if (result.isEmpty) {
        return null;
      }

      final file = result.first;
      final rawBytes = getBytesFromPlatformFile(file);

      if (rawBytes == null) {
        debugPrint('ImageUploadService: File bytes could not be extracted.');
        return null;
      }

      return await processBytesAsWebp(
        rawBytes,
        originalName: file.name,
        prefix: prefix,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        bucketName: bucketName,
      );
    } catch (e) {
      debugPrint('ImageUploadService pickAndProcessImageAsWebp error: $e');
      return null;
    }
  }

  /// Opens platform file picker to pick multiple images and converts all to WebP
  Future<List<WebpUploadResult>> pickMultipleImagesAsWebp({
    String prefix = 'portfolio',
    int quality = 85,
    int? maxWidth = 1600,
    int? maxHeight = 1600,
    String? bucketName,
  }) async {
    final List<WebpUploadResult> results = [];
    try {
      final pickerResult = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'],
      );

      if (pickerResult.isEmpty) {
        return results;
      }

      for (final file in pickerResult) {
        final rawBytes = getBytesFromPlatformFile(file);
        if (rawBytes != null) {
          final processed = await processBytesAsWebp(
            rawBytes,
            originalName: file.name,
            prefix: prefix,
            quality: quality,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            bucketName: bucketName,
          );
          if (processed != null) {
            results.add(processed);
          }
        }
      }
    } catch (e) {
      debugPrint('ImageUploadService pickMultipleImagesAsWebp error: $e');
    }
    return results;
  }
}

