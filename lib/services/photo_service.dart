// lib/services/photo_service.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:exif/exif.dart';
import 'package:geolocator/geolocator.dart';

class PhotoService {
  static const int maxWidth = 1920;
  static const int maxHeight = 1080;
  static const int compressionQuality = 85;

  /// Get the app's photo storage directory
  static Future<Directory> getPhotoDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(path.join(appDir.path, 'photos'));
    
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    
    return photoDir;
  }

  /// Generate a unique filename for a photo
  static String generatePhotoFileName({
    required String propertyId,
    required String deviceType,
    String? barcode,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeDeviceType = deviceType.replaceAll(RegExp(r'[^\w\s-]'), '');
    final barcodeStr = barcode != null ? '_$barcode' : '';
    return '${propertyId}_${safeDeviceType}${barcodeStr}_$timestamp.jpg';
  }

  /// Save and compress a photo
  static Future<String> savePhoto({
    required File sourceFile,
    required String fileName,
    bool addGpsMetadata = true,
  }) async {
    try {
      // Read the image
      final bytes = await sourceFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if needed
      img.Image resized;
      if (image.width > maxWidth || image.height > maxHeight) {
        final aspectRatio = image.width / image.height;
        int newWidth;
        int newHeight;
        
        if (aspectRatio > maxWidth / maxHeight) {
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        } else {
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }
        
        resized = img.copyResize(image, width: newWidth, height: newHeight);
      } else {
        resized = image;
      }

      // Compress
      final compressed = img.encodeJpg(resized, quality: compressionQuality);

      // Save to app directory
      final photoDir = await getPhotoDirectory();
      final targetFile = File(path.join(photoDir.path, fileName));
      await targetFile.writeAsBytes(compressed);

      // Add GPS metadata if requested and permission granted
      if (addGpsMetadata) {
        await _addGpsMetadata(targetFile.path);
      }

      return targetFile.path;
    } catch (e) {
      throw Exception('Failed to save photo: $e');
    }
  }

  /// Add GPS metadata to photo
  static Future<void> _addGpsMetadata(String filePath) async {
    try {
      // Check location permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        return; // Skip GPS metadata if no permission
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      // Read existing EXIF data
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final data = await readExifFromBytes(bytes);

      // TODO: Write GPS data back to EXIF
      // The exif package doesn't support writing, so we'd need a different approach
      // For now, we could store GPS separately in the database
      
    } catch (e) {
      // Silently fail - GPS is optional
      print('Failed to add GPS metadata: $e');
    }
  }

  /// Delete a photo file
  static Future<void> deletePhoto(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Failed to delete photo: $e');
    }
  }

  /// Get photo file size in MB
  static Future<double> getPhotoSizeMB(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.length();
        return bytes / (1024 * 1024); // Convert to MB
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Check if photo file exists
  static Future<bool> photoExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get all photos in the photo directory
  static Future<List<FileSystemEntity>> getAllPhotos() async {
    try {
      final photoDir = await getPhotoDirectory();
      return photoDir.listSync()
          .where((entity) => entity.path.endsWith('.jpg') || entity.path.endsWith('.jpeg'))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Calculate total storage used by photos
  static Future<double> getTotalPhotoStorageMB() async {
    try {
      final photos = await getAllPhotos();
      double totalBytes = 0;
      
      for (final photo in photos) {
        if (photo is File) {
          totalBytes += await photo.length();
        }
      }
      
      return totalBytes / (1024 * 1024); // Convert to MB
    } catch (e) {
      return 0;
    }
  }

  /// Clean up old photos not referenced in database
  static Future<int> cleanupOrphanedPhotos(List<String> activePhotoPaths) async {
    try {
      final photos = await getAllPhotos();
      int deletedCount = 0;
      
      for (final photo in photos) {
        if (!activePhotoPaths.contains(photo.path)) {
          await photo.delete();
          deletedCount++;
        }
      }
      
      return deletedCount;
    } catch (e) {
      return 0;
    }
  }
}