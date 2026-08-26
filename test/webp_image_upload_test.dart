import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:warisan_kita/data/services/image_upload_service.dart';

void main() {
  group('ImageUploadService WebP Pipeline Tests', () {
    final service = ImageUploadService();

    test('formatBytes correctly formats various byte sizes', () {
      expect(ImageUploadService.formatBytes(0), equals('0 B'));
      expect(ImageUploadService.formatBytes(512), equals('512 B'));
      expect(ImageUploadService.formatBytes(1024), equals('1.0 KB'));
      expect(ImageUploadService.formatBytes(250 * 1024), equals('250.0 KB'));
      expect(ImageUploadService.formatBytes(1024 * 1024 * 3), equals('3.0 MB'));
    });

    test('processBytesAsWebp converts raw image to WebP with data URI and metadata', () async {
      // Create a test synthetic RGB image
      final testImg = img.Image(width: 100, height: 80);
      img.fill(testImg, color: img.ColorRgb8(0, 77, 64));
      final pngBytes = img.encodePng(testImg);

      final result = await service.processBytesAsWebp(
        pngBytes,
        originalName: 'craft_photo.png',
        prefix: 'portfolio',
        quality: 80,
      );

      expect(result, isNotNull);
      expect(result!.fileName, endsWith('.webp'));
      expect(result.mimeType, equals('image/webp'));
      expect(result.dataUri, startsWith('data:image/webp;base64,'));
      expect(result.width, equals(100));
      expect(result.height, equals(80));
      expect(result.fileSizeBytes, greaterThan(0));
    });

    test('processBytesAsWebp resizes oversized images according to maxWidth/maxHeight', () async {
      // Create a 2000x1200 test image
      final testImg = img.Image(width: 2000, height: 1200);
      final rawPng = img.encodePng(testImg);

      final result = await service.processBytesAsWebp(
        rawPng,
        originalName: 'large_studio.png',
        prefix: 'studio',
        maxWidth: 800,
        maxHeight: 800,
      );

      expect(result, isNotNull);
      expect(result!.width, equals(800));
      expect(result.fileName, endsWith('.webp'));
    });
  });
}
