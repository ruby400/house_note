import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:house_note/core/utils/logger.dart';

/// Firebase Storage를 이용한 이미지 백업 및 복구 서비스
/// 
/// 주요 기능:
/// 1. 사용자별 폴더 구조로 이미지 업로드
/// 2. 로컬 캐시 + 클라우드 백업 이중 저장
/// 3. 오프라인 동기화
/// 4. 자동 백업 및 복구
class FirebaseImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 사용자별 폴더 경로 생성
  static String _getUserStoragePath(String userId) {
    return 'users/$userId/images';
  }

  /// 익명 사용자용 폴더 경로 생성
  static String _getAnonymousStoragePath() {
    return 'anonymous/images';
  }

  /// 현재 사용자의 스토리지 경로 가져오기
  static String _getCurrentUserStoragePath() {
    final user = _auth.currentUser;
    if (user != null && !user.isAnonymous) {
      return _getUserStoragePath(user.uid);
    } else {
      return _getAnonymousStoragePath();
    }
  }

  /// 로컬 이미지를 Firebase Storage에 업로드
  /// 
  /// [localImagePath] 로컬 이미지 파일 경로
  /// Returns Firebase Storage 다운로드 URL
  static Future<String?> uploadImage(String localImagePath) async {
    try {
      AppLogger.info('🚀 Firebase Storage 이미지 업로드 시작: $localImagePath');

      final File localFile = File(localImagePath);
      if (!await localFile.exists()) {
        AppLogger.warning('❌ 로컬 이미지 파일이 존재하지 않음: $localImagePath');
        return null;
      }

      // 파일명 추출 (타임스탬프 기반)
      final String fileName = localImagePath.split('/').last;
      
      // Firebase Storage 경로 구성
      final String storagePath = '${_getCurrentUserStoragePath()}/$fileName';
      final Reference ref = _storage.ref().child(storagePath);

      AppLogger.d('📁 Firebase Storage 경로: $storagePath');

      // 메타데이터 설정
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalPath': localImagePath,
          'userId': _auth.currentUser?.uid ?? 'anonymous',
        },
      );

      // 파일 업로드
      final UploadTask uploadTask = ref.putFile(localFile, metadata);
      
      // 업로드 진행률 모니터링
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        AppLogger.d('📤 업로드 진행률: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // 업로드 완료 대기
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.info('✅ Firebase Storage 업로드 완료: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      AppLogger.error('❌ Firebase Storage 업로드 실패', error: e);
      return null;
    }
  }

  /// Firebase Storage에서 이미지 다운로드 (캐시 포함)
  /// 
  /// [downloadUrl] Firebase Storage 다운로드 URL
  /// [fileName] 저장할 파일명 (옵션)
  /// Returns 로컬 캐시 파일 경로
  static Future<String?> downloadImage(String downloadUrl, {String? fileName}) async {
    try {
      AppLogger.info('📥 Firebase Storage 이미지 다운로드 시작: $downloadUrl');

      // 파일명 추출 또는 생성
      fileName ??= 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 로컬 캐시 디렉토리 경로
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory cacheDir = Directory('${appDir.path}/images_cache');
      
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
        AppLogger.d('📁 이미지 캐시 디렉토리 생성: ${cacheDir.path}');
      }

      final String localPath = '${cacheDir.path}/$fileName';
      final File localFile = File(localPath);

      // 이미 로컬에 존재하면 그대로 반환
      if (await localFile.exists()) {
        AppLogger.d('✅ 로컬 캐시에서 이미지 발견: $localPath');
        return localPath;
      }

      // Firebase Storage에서 다운로드
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.writeToFile(localFile);

      AppLogger.info('✅ Firebase Storage 다운로드 완료: $localPath');
      return localPath;

    } catch (e) {
      AppLogger.error('❌ Firebase Storage 다운로드 실패', error: e);
      return null;
    }
  }

  /// 로컬 이미지와 Firebase Storage 동기화
  /// 
  /// [localImagePath] 로컬 이미지 경로
  /// Returns 동기화된 이미지 정보 (로컬 경로, Firebase URL)
  static Future<Map<String, String?>> syncImage(String localImagePath) async {
    try {
      AppLogger.info('🔄 이미지 동기화 시작: $localImagePath');

      // 1. 로컬 이미지 Firebase에 업로드
      final String? firebaseUrl = await uploadImage(localImagePath);
      
      if (firebaseUrl == null) {
        AppLogger.warning('❌ Firebase 업로드 실패, 로컬만 사용');
        return {
          'localPath': localImagePath,
          'firebaseUrl': null,
        };
      }

      // 2. 백업용 로컬 복사본도 유지
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory backupDir = Directory('${appDir.path}/images');
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      AppLogger.info('✅ 이미지 동기화 완료 - Local: $localImagePath, Firebase: $firebaseUrl');
      
      return {
        'localPath': localImagePath,
        'firebaseUrl': firebaseUrl,
      };

    } catch (e) {
      AppLogger.error('❌ 이미지 동기화 실패', error: e);
      return {
        'localPath': localImagePath,
        'firebaseUrl': null,
      };
    }
  }

  /// Firebase Storage에서 이미지 삭제
  /// 
  /// [downloadUrl] 삭제할 이미지의 Firebase Storage URL
  static Future<bool> deleteImage(String downloadUrl) async {
    try {
      AppLogger.info('🗑️ Firebase Storage 이미지 삭제: $downloadUrl');

      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();

      AppLogger.info('✅ Firebase Storage 이미지 삭제 완료');
      return true;

    } catch (e) {
      AppLogger.error('❌ Firebase Storage 이미지 삭제 실패', error: e);
      return false;
    }
  }

  /// 사용자의 모든 이미지 목록 가져오기
  /// 
  /// Returns Firebase Storage에 저장된 이미지 URL 목록
  static Future<List<String>> getUserImages() async {
    try {
      AppLogger.info('📋 사용자 이미지 목록 조회 시작');

      final String userPath = _getCurrentUserStoragePath();
      final Reference ref = _storage.ref().child(userPath);
      
      final ListResult result = await ref.listAll();
      
      List<String> imageUrls = [];
      for (final Reference item in result.items) {
        try {
          final String downloadUrl = await item.getDownloadURL();
          imageUrls.add(downloadUrl);
        } catch (e) {
          AppLogger.warning('⚠️ 이미지 URL 가져오기 실패: ${item.fullPath}');
        }
      }

      AppLogger.info('✅ 사용자 이미지 목록 조회 완료: ${imageUrls.length}개');
      return imageUrls;

    } catch (e) {
      AppLogger.error('❌ 사용자 이미지 목록 조회 실패', error: e);
      return [];
    }
  }

  /// 로컬 캐시 정리
  /// 
  /// [keepDays] 보관할 일수 (기본 30일)
  static Future<void> cleanupLocalCache({int keepDays = 30}) async {
    try {
      AppLogger.info('🧹 로컬 이미지 캐시 정리 시작 ($keepDays일 이상 된 파일)');

      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory cacheDir = Directory('${appDir.path}/images_cache');
      
      if (!await cacheDir.exists()) {
        AppLogger.d('📁 캐시 디렉토리가 존재하지 않음');
        return;
      }

      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
      final List<FileSystemEntity> files = cacheDir.listSync();
      
      int deletedCount = 0;
      for (final FileSystemEntity file in files) {
        if (file is File) {
          final FileStat stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            deletedCount++;
            AppLogger.d('🗑️ 오래된 캐시 파일 삭제: ${file.path}');
          }
        }
      }

      AppLogger.info('✅ 로컬 캐시 정리 완료: $deletedCount개 파일 삭제');

    } catch (e) {
      AppLogger.error('❌ 로컬 캐시 정리 실패', error: e);
    }
  }

  /// 오프라인 동기화 - 업로드되지 않은 로컬 이미지들을 Firebase에 업로드
  /// 
  /// [localImagePaths] 동기화할 로컬 이미지 경로 목록
  /// Returns 동기화 결과 맵 (성공한 이미지들의 Firebase URL)
  static Future<Map<String, String>> syncOfflineImages(List<String> localImagePaths) async {
    try {
      AppLogger.info('🔄 오프라인 이미지 동기화 시작: ${localImagePaths.length}개 파일');

      Map<String, String> syncResults = {};
      
      for (int i = 0; i < localImagePaths.length; i++) {
        final String localPath = localImagePaths[i];
        AppLogger.d('📤 동기화 진행 (${i + 1}/${localImagePaths.length}): $localPath');
        
        final String? firebaseUrl = await uploadImage(localPath);
        if (firebaseUrl != null) {
          syncResults[localPath] = firebaseUrl;
          AppLogger.d('✅ 동기화 성공: $localPath -> $firebaseUrl');
        } else {
          AppLogger.warning('❌ 동기화 실패: $localPath');
        }
        
        // 너무 빠른 업로드 방지 (API 제한 고려)
        if (i < localImagePaths.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      AppLogger.info('✅ 오프라인 동기화 완료: ${syncResults.length}/${localImagePaths.length}개 성공');
      return syncResults;

    } catch (e) {
      AppLogger.error('❌ 오프라인 동기화 실패', error: e);
      return {};
    }
  }

  /// Firebase Storage 연결 상태 확인
  static Future<bool> isConnected() async {
    try {
      // 간단한 메타데이터 조회로 연결 상태 확인
      await _storage.ref().child('test').getMetadata();
      return true;
    } catch (e) {
      // 연결 실패 또는 파일이 존재하지 않음 (둘 다 정상)
      return false;
    }
  }

  /// 이미지 메타데이터 조회
  /// 
  /// [downloadUrl] Firebase Storage URL
  /// Returns 이미지 메타데이터
  static Future<Map<String, dynamic>?> getImageMetadata(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      final FullMetadata metadata = await ref.getMetadata();
      
      return {
        'name': metadata.name,
        'bucket': metadata.bucket,
        'fullPath': metadata.fullPath,
        'size': metadata.size,
        'timeCreated': metadata.timeCreated?.toIso8601String(),
        'updated': metadata.updated?.toIso8601String(),
        'contentType': metadata.contentType,
        'customMetadata': metadata.customMetadata,
      };
    } catch (e) {
      AppLogger.error('❌ 이미지 메타데이터 조회 실패', error: e);
      return null;
    }
  }
}