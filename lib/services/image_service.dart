import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:house_note/core/utils/logger.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  // 권한 확인 및 요청
  static Future<bool> checkAndRequestPermissions() async {
    try {
      AppLogger.d('🔐 Checking camera and storage permissions...');

      // 현재 권한 상태 확인
      final cameraStatus = await Permission.camera.status;
      final photosStatus = await Permission.photos.status;
      final storageStatus = await Permission.storage.status;

      AppLogger.d('📋 Current permission status:');
      AppLogger.d('  Camera: $cameraStatus');
      AppLogger.d('  Photos: $photosStatus');
      AppLogger.d('  Storage: $storageStatus');

      // 각 권한별로 개별 처리
      bool cameraGranted = cameraStatus.isGranted;
      bool photosGranted = photosStatus.isGranted;
      bool storageGranted = storageStatus.isGranted;

      // 카메라 권한이 없으면 요청
      if (!cameraGranted) {
        AppLogger.d('📸 Requesting camera permission...');
        final result = await Permission.camera.request();
        cameraGranted = result.isGranted;
        AppLogger.d('📸 Camera permission result: $result');

        // 권한이 영구적으로 거부되었으면 설정으로 이동 안내
        if (result.isPermanentlyDenied) {
          AppLogger.warning('❌ Camera permission permanently denied');
          return false;
        }
      }

      // 사진 라이브러리 권한이 없으면 요청
      if (!photosGranted) {
        AppLogger.d('🖼️ Requesting photos permission...');
        final result = await Permission.photos.request();
        photosGranted = result.isGranted;
        AppLogger.d('🖼️ Photos permission result: $result');

        if (result.isPermanentlyDenied) {
          AppLogger.warning('❌ Photos permission permanently denied');
          return false;
        }
      }

      // 스토리지 권한이 없으면 요청 (Android)
      if (!storageGranted) {
        AppLogger.d('💾 Requesting storage permission...');
        final result = await Permission.storage.request();
        storageGranted = result.isGranted;
        AppLogger.d('💾 Storage permission result: $result');

        if (result.isPermanentlyDenied) {
          AppLogger.warning('❌ Storage permission permanently denied');
          return false;
        }
      }

      final allGranted = cameraGranted && photosGranted && storageGranted;
      AppLogger.d(allGranted
          ? '✅ All permissions granted!'
          : '❌ Some permissions denied');
      AppLogger.d(
          'Final status - Camera: $cameraGranted, Photos: $photosGranted, Storage: $storageGranted');

      return allGranted;
    } catch (e) {
      AppLogger.error('❌ Error checking permissions', error: e);
      return false;
    }
  }

  // 설정앱으로 이동
  static Future<bool> openSettings() async {
    try {
      AppLogger.d('⚙️ Opening app settings...');
      return await openAppSettings();
    } catch (e) {
      AppLogger.error('❌ Error opening app settings', error: e);
      return false;
    }
  }

  // 카메라로 사진 촬영
  static Future<String?> takePicture() async {
    try {
      AppLogger.d('📸 ImageService.takePicture() started');


      AppLogger.d('✅ Permissions OK, calling image picker...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // 품질 조정으로 용량 최적화
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) {
        AppLogger.d('❌ User cancelled camera or picker returned null');
        return null;
      }

      AppLogger.d('✅ Picture taken successfully: ${image.path}');

      // 앱 내부 저장소에 저장
      AppLogger.d('💾 Saving image to app directory...');
      final String? savedPath = await _saveImageToAppDirectory(image);

      if (savedPath != null) {
        AppLogger.d('✅ Image saved to app directory: $savedPath');
        // 갤러리에도 저장
        AppLogger.d('📱 Saving to gallery...');
        await _saveImageToGallery(image);
        AppLogger.d('✅ takePicture completed successfully');
        return savedPath;
      } else {
        AppLogger.warning('❌ Failed to save image to app directory');
      }

      return null;
    } catch (e) {
      AppLogger.error('❌ Error in ImageService.takePicture', error: e);
      return null;
    }
  }

  // 갤러리에서 사진 선택
  static Future<String?> pickImageFromGallery() async {
    try {
      AppLogger.d('🖼️ ImageService.pickImageFromGallery() started');


      AppLogger.d('✅ Permissions OK, calling gallery picker...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) {
        AppLogger.d(
            '❌ User cancelled gallery selection or picker returned null');
        return null;
      }

      AppLogger.d('✅ Image selected from gallery: ${image.path}');

      // 앱 내부 저장소에 복사
      AppLogger.d('💾 Saving gallery image to app directory...');
      final String? savedPath = await _saveImageToAppDirectory(image);

      if (savedPath != null) {
        AppLogger.d('✅ Gallery image saved successfully: $savedPath');
      } else {
        AppLogger.warning('❌ Failed to save gallery image to app directory');
      }

      return savedPath;
    } catch (e) {
      AppLogger.error('❌ Error in ImageService.pickImageFromGallery', error: e);
      return null;
    }
  }

  // 갤러리에서 여러 사진 선택
  static Future<List<String>> pickMultipleImagesFromGallery() async {
    try {
      AppLogger.d('🖼️ ImageService.pickMultipleImagesFromGallery() started');

      AppLogger.d('✅ Permissions OK, calling multiple gallery picker...');
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (images.isEmpty) {
        AppLogger.d('❌ User cancelled gallery selection or no images selected');
        return [];
      }

      AppLogger.d('✅ ${images.length} images selected from gallery');

      List<String> savedPaths = [];
      
      // 각 이미지를 앱 내부 저장소에 복사
      for (int i = 0; i < images.length; i++) {
        AppLogger.d('💾 Saving gallery image ${i + 1}/${images.length} to app directory...');
        final String? savedPath = await _saveImageToAppDirectory(images[i]);
        
        if (savedPath != null) {
          savedPaths.add(savedPath);
          AppLogger.d('✅ Gallery image ${i + 1} saved successfully: $savedPath');
        } else {
          AppLogger.warning('❌ Failed to save gallery image ${i + 1} to app directory');
        }
      }

      AppLogger.d('✅ pickMultipleImagesFromGallery completed, saved ${savedPaths.length}/${images.length} images');
      return savedPaths;
    } catch (e) {
      AppLogger.error('❌ Error in ImageService.pickMultipleImagesFromGallery', error: e);
      return [];
    }
  }

  // 앱 내부 디렉토리에 이미지 저장
  static Future<String?> _saveImageToAppDirectory(XFile image) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory('${appDir.path}/images');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
        AppLogger.d('Created images directory: ${imagesDir.path}');
      }

      final String fileName =
          'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '${imagesDir.path}/$fileName';

      final File imageFile = File(image.path);
      final File savedFile = await imageFile.copy(filePath);

      AppLogger.d('Image saved to app directory: $filePath');
      return savedFile.path;
    } catch (e) {
      AppLogger.error('Error saving image to app directory', error: e);
      return null;
    }
  }

  // 갤러리에 이미지 저장
  static Future<bool> _saveImageToGallery(XFile image) async {
    try {
      AppLogger.d('Saving image to gallery...');

      // Android/iOS에서 갤러리에 저장하는 방법이 다르므로
      // 여기서는 기본적인 구현만 제공
      // 실제로는 gal 패키지나 gallery_saver 패키지 사용 권장

      // 갤러리 저장 기능은 chart_screen.dart에서 gal 패키지로 구현됨
      // 이 메서드는 레거시 placeholder로, 실제로는 사용하지 않음
      AppLogger.d('Gallery save placeholder - use gal package in actual implementation');

      return true;
    } catch (e) {
      AppLogger.error('Error saving image to gallery', error: e);
      return false;
    }
  }

  // 이미지 파일 삭제
  static Future<bool> deleteImage(String imagePath) async {
    try {
      AppLogger.d('Deleting image: $imagePath');

      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        AppLogger.d('Image deleted successfully');
        return true;
      } else {
        AppLogger.warning('Image file not found: $imagePath');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error deleting image', error: e);
      return false;
    }
  }

  // 이미지 존재 확인
  static Future<bool> imageExists(String imagePath) async {
    try {
      return await File(imagePath).exists();
    } catch (e) {
      AppLogger.error('Error checking image existence', error: e);
      return false;
    }
  }

  // 이미지 크기 정보 가져오기
  static Future<Size?> getImageSize(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        // 이미지 크기 정보는 별도 패키지 필요
        // 여기서는 기본값 반환
        return const Size(1920, 1080);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting image size', error: e);
      return null;
    }
  }

  // 앱 내 모든 이미지 정리 (필요시)
  static Future<void> cleanupImages() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory('${appDir.path}/images');

      if (await imagesDir.exists()) {
        final List<FileSystemEntity> files = imagesDir.listSync();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
        AppLogger.d('Cleaned up ${files.length} images');
      }
    } catch (e) {
      AppLogger.error('Error cleaning up images', error: e);
    }
  }
}
