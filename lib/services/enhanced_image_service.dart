import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:house_note/core/utils/logger.dart';
import 'package:house_note/services/firebase_image_service.dart';

/// 강화된 이미지 서비스 - 로컬 + Firebase Storage 이중 저장
/// 
/// 주요 기능:
/// 1. 기존 ImageService의 모든 기능 포함
/// 2. Firebase Storage 자동 백업
/// 3. 오프라인 동기화
/// 4. 안전한 이미지 관리
class EnhancedImageService {
  static final ImagePicker _picker = ImagePicker();

  /// 이미지 데이터 구조
  static const String kLocalPathKey = 'localPath';
  static const String kFirebaseUrlKey = 'firebaseUrl';
  static const String kSyncStatusKey = 'syncStatus'; // 'synced', 'pending', 'failed'

  // 권한 확인 및 요청 (기존 코드 재사용)
  static Future<bool> checkAndRequestPermissions() async {
    try {
      AppLogger.d('🔐 Checking camera and storage permissions...');

      final cameraStatus = await Permission.camera.status;
      final photosStatus = await Permission.photos.status;
      final storageStatus = await Permission.storage.status;

      AppLogger.d('📋 Current permission status:');
      AppLogger.d('  Camera: $cameraStatus');
      AppLogger.d('  Photos: $photosStatus');
      AppLogger.d('  Storage: $storageStatus');

      bool cameraGranted = cameraStatus.isGranted;
      bool photosGranted = photosStatus.isGranted;
      bool storageGranted = storageStatus.isGranted;

      if (!cameraGranted) {
        AppLogger.d('📸 Requesting camera permission...');
        final result = await Permission.camera.request();
        cameraGranted = result.isGranted;
        AppLogger.d('📸 Camera permission result: $result');

        if (result.isPermanentlyDenied) {
          AppLogger.warning('❌ Camera permission permanently denied');
          return false;
        }
      }

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

      if (Platform.isAndroid && !storageGranted) {
        AppLogger.d('💾 Requesting storage permission (Android)...');
        final result = await Permission.storage.request();
        storageGranted = result.isGranted;
        AppLogger.d('💾 Storage permission result: $result');

        if (result.isPermanentlyDenied) {
          AppLogger.warning('❌ Storage permission permanently denied');
          return false;
        }
      } else if (Platform.isIOS) {
        storageGranted = true;
      }

      final allGranted = cameraGranted && photosGranted && storageGranted;
      AppLogger.d(allGranted
          ? '✅ All permissions granted!'
          : '❌ Some permissions denied');

      return allGranted;
    } catch (e) {
      AppLogger.error('❌ Error checking permissions', error: e);
      return false;
    }
  }

  /// 설정앱으로 이동
  static Future<bool> openSettings() async {
    try {
      AppLogger.d('⚙️ Opening app settings...');
      return await openAppSettings();
    } catch (e) {
      AppLogger.error('❌ Error opening app settings', error: e);
      return false;
    }
  }

  /// 카메라로 사진 촬영 (Firebase 백업 포함)
  /// 
  /// Returns 이미지 정보 맵 {localPath, firebaseUrl, syncStatus}
  static Future<Map<String, String?>> takePictureWithBackup() async {
    try {
      AppLogger.info('📸 Enhanced takePicture 시작');

      // 권한 확인
      final hasPermissions = await checkAndRequestPermissions();
      if (!hasPermissions) {
        AppLogger.warning('❌ Camera permissions denied');
        return {};
      }

      AppLogger.d('✅ Permissions OK, calling image picker...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) {
        AppLogger.d('❌ User cancelled camera or picker returned null');
        return {};
      }

      AppLogger.d('✅ Picture taken successfully: ${image.path}');

      // 앱 내부 저장소에 저장
      final String? localPath = await _saveImageToAppDirectory(image);
      if (localPath == null) {
        AppLogger.warning('❌ Failed to save image to app directory');
        return {};
      }

      // Firebase Storage에 백업 (백그라운드)
      AppLogger.info('☁️ Firebase Storage 백업 시작...');
      final Map<String, String?> syncResult = await FirebaseImageService.syncImage(localPath);
      
      final result = {
        kLocalPathKey: localPath,
        kFirebaseUrlKey: syncResult['firebaseUrl'],
        kSyncStatusKey: syncResult['firebaseUrl'] != null ? 'synced' : 'pending',
      };

      AppLogger.info('✅ Enhanced takePicture 완료: $result');
      return result;

    } catch (e) {
      AppLogger.error('❌ Error in Enhanced takePicture', error: e);
      return {};
    }
  }

  /// 갤러리에서 사진 선택 (Firebase 백업 포함)
  /// 
  /// Returns 이미지 정보 맵 {localPath, firebaseUrl, syncStatus}
  static Future<Map<String, String?>> pickImageFromGalleryWithBackup() async {
    try {
      AppLogger.info('🖼️ Enhanced pickImageFromGallery 시작');

      AppLogger.d('✅ Calling gallery picker...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) {
        AppLogger.d('❌ User cancelled gallery selection');
        return {};
      }

      AppLogger.d('✅ Image selected from gallery: ${image.path}');

      // 앱 내부 저장소에 복사
      final String? localPath = await _saveImageToAppDirectory(image);
      if (localPath == null) {
        AppLogger.warning('❌ Failed to save gallery image to app directory');
        return {};
      }

      // Firebase Storage에 백업
      AppLogger.info('☁️ Firebase Storage 백업 시작...');
      final Map<String, String?> syncResult = await FirebaseImageService.syncImage(localPath);
      
      final result = {
        kLocalPathKey: localPath,
        kFirebaseUrlKey: syncResult['firebaseUrl'],
        kSyncStatusKey: syncResult['firebaseUrl'] != null ? 'synced' : 'pending',
      };

      AppLogger.info('✅ Enhanced pickImageFromGallery 완료: $result');
      return result;

    } catch (e) {
      AppLogger.error('❌ Error in Enhanced pickImageFromGallery', error: e);
      return {};
    }
  }

  /// 갤러리에서 여러 사진 선택 (Firebase 백업 포함)
  /// 
  /// Returns 이미지 정보 맵 리스트
  static Future<List<Map<String, String?>>> pickMultipleImagesFromGalleryWithBackup() async {
    try {
      AppLogger.info('🖼️ Enhanced pickMultipleImagesFromGallery 시작');

      AppLogger.d('✅ Calling multiple gallery picker...');
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (images.isEmpty) {
        AppLogger.d('❌ User cancelled or no images selected');
        return [];
      }

      AppLogger.d('✅ ${images.length} images selected from gallery');

      List<Map<String, String?>> results = [];
      
      for (int i = 0; i < images.length; i++) {
        AppLogger.d('💾 Processing image ${i + 1}/${images.length}...');
        
        // 앱 내부 저장소에 복사
        final String? localPath = await _saveImageToAppDirectory(images[i]);
        if (localPath == null) {
          AppLogger.warning('❌ Failed to save image ${i + 1}');
          continue;
        }

        // Firebase Storage에 백업 (백그라운드)
        AppLogger.d('☁️ Firebase Storage 백업 ${i + 1}/${images.length}...');
        final Map<String, String?> syncResult = await FirebaseImageService.syncImage(localPath);
        
        results.add({
          kLocalPathKey: localPath,
          kFirebaseUrlKey: syncResult['firebaseUrl'],
          kSyncStatusKey: syncResult['firebaseUrl'] != null ? 'synced' : 'pending',
        });
      }

      AppLogger.info('✅ Enhanced pickMultipleImagesFromGallery 완료: ${results.length}/${images.length}개 성공');
      return results;

    } catch (e) {
      AppLogger.error('❌ Error in Enhanced pickMultipleImagesFromGallery', error: e);
      return [];
    }
  }

  /// 앱 내부 디렉토리에 이미지 저장 (기존 코드 재사용)
  static Future<String?> _saveImageToAppDirectory(XFile image) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory('${appDir.path}/images');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
        AppLogger.d('Created images directory: ${imagesDir.path}');
      }

      final String fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
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

  /// 이미지 복구 - Firebase에서 로컬로 다운로드
  /// 
  /// [firebaseUrl] Firebase Storage URL
  /// [fileName] 로컬에 저장할 파일명 (옵션)
  /// Returns 복구된 로컬 이미지 경로
  static Future<String?> recoverImageFromFirebase(String firebaseUrl, {String? fileName}) async {
    try {
      AppLogger.info('🔄 Firebase에서 이미지 복구 시작: $firebaseUrl');
      
      final String? localPath = await FirebaseImageService.downloadImage(firebaseUrl, fileName: fileName);
      
      if (localPath != null) {
        AppLogger.info('✅ 이미지 복구 완료: $localPath');
      } else {
        AppLogger.warning('❌ 이미지 복구 실패');
      }
      
      return localPath;
    } catch (e) {
      AppLogger.error('❌ 이미지 복구 중 오류 발생', error: e);
      return null;
    }
  }

  /// 동기화되지 않은 로컬 이미지들을 Firebase에 업로드
  /// 
  /// [localImagePaths] 로컬 이미지 경로 목록
  /// Returns 동기화 결과
  static Future<Map<String, String>> syncPendingImages(List<String> localImagePaths) async {
    try {
      AppLogger.info('🔄 미동기화 이미지 업로드 시작: ${localImagePaths.length}개');
      
      final Map<String, String> results = await FirebaseImageService.syncOfflineImages(localImagePaths);
      
      AppLogger.info('✅ 미동기화 이미지 업로드 완료: ${results.length}/${localImagePaths.length}개 성공');
      return results;
    } catch (e) {
      AppLogger.error('❌ 미동기화 이미지 업로드 실패', error: e);
      return {};
    }
  }

  /// 이미지 삭제 (로컬 + Firebase)
  /// 
  /// [localPath] 로컬 이미지 경로
  /// [firebaseUrl] Firebase Storage URL (옵션)
  static Future<bool> deleteImageCompletely({
    required String localPath,
    String? firebaseUrl,
  }) async {
    try {
      AppLogger.info('🗑️ 이미지 완전 삭제 시작 - Local: $localPath, Firebase: $firebaseUrl');

      bool localDeleted = false;
      bool firebaseDeleted = true; // Firebase URL이 없으면 성공으로 간주

      // 로컬 파일 삭제
      try {
        final File localFile = File(localPath);
        if (await localFile.exists()) {
          await localFile.delete();
          localDeleted = true;
          AppLogger.d('✅ 로컬 파일 삭제 완료');
        } else {
          localDeleted = true; // 파일이 없으면 성공으로 간주
          AppLogger.d('ℹ️ 로컬 파일이 이미 존재하지 않음');
        }
      } catch (e) {
        AppLogger.warning('❌ 로컬 파일 삭제 실패: $e');
      }

      // Firebase Storage에서 삭제
      if (firebaseUrl != null) {
        try {
          firebaseDeleted = await FirebaseImageService.deleteImage(firebaseUrl);
          if (firebaseDeleted) {
            AppLogger.d('✅ Firebase Storage 삭제 완료');
          } else {
            AppLogger.warning('❌ Firebase Storage 삭제 실패');
          }
        } catch (e) {
          AppLogger.warning('❌ Firebase Storage 삭제 중 오류: $e');
          firebaseDeleted = false;
        }
      }

      final success = localDeleted && firebaseDeleted;
      AppLogger.info(success ? '✅ 이미지 완전 삭제 성공' : '❌ 이미지 삭제 일부 실패');
      
      return success;
    } catch (e) {
      AppLogger.error('❌ 이미지 삭제 중 오류 발생', error: e);
      return false;
    }
  }

  /// 이미지 존재 확인 (로컬 우선, Firebase 대체)
  /// 
  /// [localPath] 로컬 이미지 경로
  /// [firebaseUrl] Firebase Storage URL (옵션)
  /// Returns 이미지 접근 가능 여부
  static Future<bool> imageExists({
    required String localPath,
    String? firebaseUrl,
  }) async {
    try {
      // 로컬 파일 존재 확인
      if (await File(localPath).exists()) {
        return true;
      }

      // Firebase Storage 존재 확인
      if (firebaseUrl != null) {
        try {
          final metadata = await FirebaseImageService.getImageMetadata(firebaseUrl);
          return metadata != null;
        } catch (e) {
          AppLogger.d('Firebase 이미지 확인 실패: $e');
        }
      }

      return false;
    } catch (e) {
      AppLogger.error('이미지 존재 확인 중 오류', error: e);
      return false;
    }
  }

  /// 앱 내 모든 이미지 정리
  static Future<void> cleanupAllImages() async {
    try {
      AppLogger.info('🧹 모든 이미지 정리 시작');

      final Directory appDir = await getApplicationDocumentsDirectory();
      
      // 로컬 이미지 디렉토리 정리
      final Directory imagesDir = Directory('${appDir.path}/images');
      if (await imagesDir.exists()) {
        final List<FileSystemEntity> files = imagesDir.listSync();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
        AppLogger.d('로컬 이미지 ${files.length}개 삭제 완료');
      }

      // 캐시 이미지 디렉토리 정리
      await FirebaseImageService.cleanupLocalCache(keepDays: 0);

      AppLogger.info('✅ 모든 이미지 정리 완료');
    } catch (e) {
      AppLogger.error('❌ 이미지 정리 중 오류 발생', error: e);
    }
  }

  /// Firebase Storage 연결 상태 확인
  static Future<bool> isFirebaseConnected() async {
    return await FirebaseImageService.isConnected();
  }

  /// 사용자의 모든 Firebase 이미지 목록 가져오기
  static Future<List<String>> getUserFirebaseImages() async {
    return await FirebaseImageService.getUserImages();
  }

  /// 이미지 메타데이터 조회
  static Future<Map<String, dynamic>?> getImageMetadata(String firebaseUrl) async {
    return await FirebaseImageService.getImageMetadata(firebaseUrl);
  }

  // ===== 기존 ImageService 호환성 메서드들 =====

  /// 기존 takePicture 메서드 (호환성 유지)
  /// 
  /// Returns 로컬 이미지 경로만 반환 (기존 코드와의 호환성)
  static Future<String?> takePicture() async {
    final result = await takePictureWithBackup();
    return result[kLocalPathKey];
  }

  /// 기존 pickImageFromGallery 메서드 (호환성 유지)
  static Future<String?> pickImageFromGallery() async {
    final result = await pickImageFromGalleryWithBackup();
    return result[kLocalPathKey];
  }

  /// 기존 pickMultipleImagesFromGallery 메서드 (호환성 유지)
  static Future<List<String>> pickMultipleImagesFromGallery() async {
    final results = await pickMultipleImagesFromGalleryWithBackup();
    return results.map((r) => r[kLocalPathKey] ?? '').where((path) => path.isNotEmpty).toList();
  }

  /// 기존 deleteImage 메서드 (호환성 유지)
  static Future<bool> deleteImage(String imagePath) async {
    return await deleteImageCompletely(localPath: imagePath);
  }

  /// 기존 imageExists 메서드 (호환성 유지)
  static Future<bool> imageExistsLegacy(String imagePath) async {
    return await File(imagePath).exists();
  }

  /// 기존 fixImagePath 메서드 (호환성 유지)
  static Future<String?> fixImagePath(String oldPath) async {
    try {
      if (await File(oldPath).exists()) {
        return oldPath;
      }

      final fileName = oldPath.split('/').last;
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory('${appDir.path}/images');
      final String newPath = '${imagesDir.path}/$fileName';
      
      if (await File(newPath).exists()) {
        AppLogger.d('Fixed image path: $oldPath -> $newPath');
        return newPath;
      }
      
      AppLogger.warning('Image not found: $fileName');
      return null;
    } catch (e) {
      AppLogger.error('Error fixing image path', error: e);
      return null;
    }
  }

  /// 기존 getImageSize 메서드 (호환성 유지)
  static Future<Size?> getImageSize(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        return const Size(1920, 1080);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting image size', error: e);
      return null;
    }
  }

  /// 기존 cleanupImages 메서드 (호환성 유지)
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