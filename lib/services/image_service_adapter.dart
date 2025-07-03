import 'package:house_note/services/enhanced_image_service.dart';
import 'package:house_note/services/image_sync_service.dart';
import 'package:house_note/data/models/property_chart_model.dart';
import 'package:house_note/data/models/enhanced_image_data.dart';
import 'package:house_note/data/models/property_data_extensions.dart';
import 'package:house_note/core/utils/logger.dart';

/// 기존 ImageService와 새로운 EnhancedImageService 간의 어댑터
/// 
/// 기존 코드를 수정하지 않고도 새로운 Firebase Storage 기능을 사용할 수 있게 해줍니다.
/// 
/// 사용법:
/// ```dart
/// // 기존 방식 (계속 작동)
/// final imagePath = await ImageServiceAdapter.takePicture();
/// 
/// // 새로운 방식 (Firebase 백업 포함)
/// final imageData = await ImageServiceAdapter.takePictureWithBackup();
/// ```
class ImageServiceAdapter {
  
  /// 이미지 동기화 서비스 인스턴스
  static final ImageSyncService _syncService = ImageSyncService();

  // ===== 기존 API 호환성 메서드들 =====

  /// 카메라로 사진 촬영 (기존 API)
  static Future<String?> takePicture() async {
    return await EnhancedImageService.takePicture();
  }

  /// 갤러리에서 사진 선택 (기존 API)
  static Future<String?> pickImageFromGallery() async {
    return await EnhancedImageService.pickImageFromGallery();
  }

  /// 갤러리에서 여러 사진 선택 (기존 API)
  static Future<List<String>> pickMultipleImagesFromGallery() async {
    return await EnhancedImageService.pickMultipleImagesFromGallery();
  }

  /// 이미지 삭제 (기존 API)
  static Future<bool> deleteImage(String imagePath) async {
    return await EnhancedImageService.deleteImage(imagePath);
  }

  /// 이미지 존재 확인 (기존 API)
  static Future<bool> imageExists(String imagePath) async {
    return await EnhancedImageService.imageExistsLegacy(imagePath);
  }

  /// 이미지 경로 복구 (기존 API)
  static Future<String?> fixImagePath(String oldPath) async {
    return await EnhancedImageService.fixImagePath(oldPath);
  }

  /// 권한 확인 및 요청 (기존 API)
  static Future<bool> checkAndRequestPermissions() async {
    return await EnhancedImageService.checkAndRequestPermissions();
  }

  /// 설정 앱으로 이동 (기존 API)
  static Future<bool> openSettings() async {
    return await EnhancedImageService.openSettings();
  }

  /// 모든 이미지 정리 (기존 API)
  static Future<void> cleanupImages() async {
    return await EnhancedImageService.cleanupImages();
  }

  // ===== 새로운 Firebase 백업 API =====

  /// 카메라로 사진 촬영 (Firebase 백업 포함)
  static Future<Map<String, String?>> takePictureWithBackup() async {
    return await EnhancedImageService.takePictureWithBackup();
  }

  /// 갤러리에서 사진 선택 (Firebase 백업 포함)
  static Future<Map<String, String?>> pickImageFromGalleryWithBackup() async {
    return await EnhancedImageService.pickImageFromGalleryWithBackup();
  }

  /// 갤러리에서 여러 사진 선택 (Firebase 백업 포함)
  static Future<List<Map<String, String?>>> pickMultipleImagesFromGalleryWithBackup() async {
    return await EnhancedImageService.pickMultipleImagesFromGalleryWithBackup();
  }

  /// 이미지 완전 삭제 (로컬 + Firebase)
  static Future<bool> deleteImageCompletely({
    required String localPath,
    String? firebaseUrl,
  }) async {
    return await EnhancedImageService.deleteImageCompletely(
      localPath: localPath,
      firebaseUrl: firebaseUrl,
    );
  }

  /// Firebase에서 이미지 복구
  static Future<String?> recoverImageFromFirebase(String firebaseUrl, {String? fileName}) async {
    return await EnhancedImageService.recoverImageFromFirebase(firebaseUrl, fileName: fileName);
  }

  // ===== PropertyData 통합 메서드들 =====

  /// PropertyData에 이미지 추가 (Firebase 백업 포함)
  /// 
  /// [propertyData] 대상 PropertyData
  /// [cellId] 셀 식별자 (예: 'address', 'memo')
  /// [useCamera] true: 카메라 촬영, false: 갤러리 선택
  /// Returns 업데이트된 PropertyData와 추가된 이미지 정보
  static Future<Map<String, dynamic>> addImageToProperty({
    required PropertyData propertyData,
    required String cellId,
    bool useCamera = false,
  }) async {
    try {
      AppLogger.info('PropertyData에 이미지 추가: ${propertyData.id}, cellId: $cellId');

      // 1. 이미지 선택/촬영
      Map<String, String?> imageResult;
      if (useCamera) {
        imageResult = await takePictureWithBackup();
      } else {
        imageResult = await pickImageFromGalleryWithBackup();
      }

      if (imageResult.isEmpty || imageResult[EnhancedImageService.kLocalPathKey] == null) {
        AppLogger.d('이미지 선택/촬영 취소됨');
        return {
          'success': false,
          'propertyData': propertyData,
          'message': '이미지 선택/촬영이 취소되었습니다',
        };
      }

      // 2. EnhancedImageData 생성
      final localPath = imageResult[EnhancedImageService.kLocalPathKey]!;
      final firebaseUrl = imageResult[EnhancedImageService.kFirebaseUrlKey];
      final syncStatus = imageResult[EnhancedImageService.kSyncStatusKey] ?? 'local_only';

      final enhancedImage = EnhancedImageData(
        localPath: localPath,
        firebaseUrl: firebaseUrl,
        syncStatus: syncStatus,
        uploadedAt: DateTime.now(),
        lastSyncAt: syncStatus == 'synced' ? DateTime.now() : null,
      );

      // 3. PropertyData에 이미지 추가
      final updatedPropertyData = propertyData.addEnhancedImage(cellId, enhancedImage);

      AppLogger.info('이미지 추가 완료: $localPath (sync: $syncStatus)');

      return {
        'success': true,
        'propertyData': updatedPropertyData,
        'imageData': enhancedImage,
        'localPath': localPath,
        'firebaseUrl': firebaseUrl,
        'syncStatus': syncStatus,
      };

    } catch (e) {
      AppLogger.error('PropertyData 이미지 추가 실패', error: e);
      return {
        'success': false,
        'propertyData': propertyData,
        'error': e.toString(),
      };
    }
  }

  /// PropertyData에서 이미지 제거 (로컬 + Firebase)
  /// 
  /// [propertyData] 대상 PropertyData
  /// [cellId] 셀 식별자
  /// [localPath] 제거할 이미지의 로컬 경로
  /// Returns 업데이트된 PropertyData
  static Future<PropertyData> removeImageFromProperty({
    required PropertyData propertyData,
    required String cellId,
    required String localPath,
  }) async {
    try {
      AppLogger.info('PropertyData에서 이미지 제거: ${propertyData.id}, cellId: $cellId, path: $localPath');

      // 1. 해당 셀의 이미지들 가져오기
      final images = propertyData.getEnhancedImages(cellId);
      final targetImage = images.firstWhere(
        (img) => img.localPath == localPath,
        orElse: () => EnhancedImageData.localOnly(localPath: localPath),
      );

      // 2. 실제 파일 삭제 (로컬 + Firebase)
      await deleteImageCompletely(
        localPath: localPath,
        firebaseUrl: targetImage.firebaseUrl,
      );

      // 3. PropertyData에서 이미지 제거
      final updatedPropertyData = propertyData.removeEnhancedImage(cellId, localPath);

      AppLogger.info('이미지 제거 완료: $localPath');
      return updatedPropertyData;

    } catch (e) {
      AppLogger.error('PropertyData 이미지 제거 실패', error: e);
      return propertyData;
    }
  }

  /// PropertyData의 모든 이미지 동기화
  /// 
  /// [propertyData] 동기화할 PropertyData
  /// Returns 동기화된 PropertyData
  static Future<PropertyData> syncPropertyImages(PropertyData propertyData) async {
    return await _syncService.syncPropertyImages(propertyData);
  }

  /// 차트의 모든 이미지 동기화
  /// 
  /// [chart] 동기화할 PropertyChartModel
  /// Returns 동기화된 PropertyChartModel
  static Future<PropertyChartModel> syncChartImages(PropertyChartModel chart) async {
    return await _syncService.syncChartImages(chart);
  }

  /// 여러 차트 일괄 동기화
  /// 
  /// [charts] 동기화할 차트 목록
  /// Returns 동기화된 차트 목록
  static Future<List<PropertyChartModel>> syncMultipleCharts(List<PropertyChartModel> charts) async {
    return await _syncService.syncMultipleCharts(charts);
  }

  /// 실패한 이미지들 재동기화
  /// 
  /// [chart] 재동기화할 차트
  /// Returns 재동기화된 차트
  static Future<PropertyChartModel> retrySyncFailedImages(PropertyChartModel chart) async {
    return await _syncService.retrySyncFailedImages(chart);
  }

  // ===== 유틸리티 메서드들 =====

  /// 동기화 상태 스트림
  static Stream<ImageSyncStatus> get syncStatusStream => _syncService.syncStatusStream;

  /// 동기화 취소
  static void cancelSync() => _syncService.cancelSync();

  /// Firebase Storage 연결 상태 확인
  static Future<bool> isFirebaseConnected() async {
    return await EnhancedImageService.isFirebaseConnected();
  }

  /// 동기화 통계 정보
  static Future<Map<String, dynamic>> getSyncStats(List<PropertyChartModel> charts) async {
    return await _syncService.getSyncStats(charts);
  }

  /// 사용자의 Firebase 이미지 목록
  static Future<List<String>> getUserFirebaseImages() async {
    return await EnhancedImageService.getUserFirebaseImages();
  }

  /// 이미지 메타데이터 조회
  static Future<Map<String, dynamic>?> getImageMetadata(String firebaseUrl) async {
    return await EnhancedImageService.getImageMetadata(firebaseUrl);
  }

  /// PropertyData를 새로운 이미지 시스템으로 마이그레이션
  static PropertyData migratePropertyData(PropertyData propertyData) {
    return propertyData.migrateToEnhancedImages();
  }

  /// PropertyChartModel을 새로운 이미지 시스템으로 마이그레이션
  static PropertyChartModel migrateChart(PropertyChartModel chart) {
    return chart.migrateToEnhancedImages();
  }

  /// 모든 차트를 새로운 이미지 시스템으로 마이그레이션
  static List<PropertyChartModel> migrateAllCharts(List<PropertyChartModel> charts) {
    try {
      AppLogger.info('전체 차트 마이그레이션 시작: ${charts.length}개');

      final migratedCharts = charts.map((chart) => chart.migrateToEnhancedImages()).toList();

      AppLogger.info('전체 차트 마이그레이션 완료: ${charts.length}개');
      return migratedCharts;
    } catch (e) {
      AppLogger.error('전체 차트 마이그레이션 실패', error: e);
      return charts;
    }
  }

  /// 이미지 백업 상태 확인
  /// 
  /// [charts] 확인할 차트 목록
  /// Returns 백업 상태 보고서
  static Map<String, dynamic> checkBackupStatus(List<PropertyChartModel> charts) {
    try {
      int totalCharts = charts.length;
      int totalProperties = 0;
      int totalImages = 0;
      int backedUpImages = 0;
      int localOnlyImages = 0;
      int failedImages = 0;

      final chartReports = <Map<String, dynamic>>[];

      for (final chart in charts) {
        final stats = chart.getImageStats();
        
        totalProperties += (stats['totalProperties'] as int? ?? 0);
        totalImages += (stats['totalImages'] as int? ?? 0);
        backedUpImages += (stats['syncedImages'] as int? ?? 0);
        localOnlyImages += (stats['localOnlyImages'] as int? ?? 0);
        failedImages += (stats['failedImages'] as int? ?? 0);

        chartReports.add({
          'chartId': chart.id,
          'chartTitle': chart.title,
          'stats': stats,
        });
      }

      final backupRate = totalImages > 0 ? (backedUpImages / totalImages) : 0.0;
      final isFullyBackedUp = totalImages > 0 && backedUpImages == totalImages;
      final needsBackup = localOnlyImages + failedImages > 0;

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'summary': {
          'totalCharts': totalCharts,
          'totalProperties': totalProperties,
          'totalImages': totalImages,
          'backedUpImages': backedUpImages,
          'localOnlyImages': localOnlyImages,
          'failedImages': failedImages,
          'backupRate': backupRate,
          'isFullyBackedUp': isFullyBackedUp,
          'needsBackup': needsBackup,
        },
        'chartReports': chartReports,
        'recommendations': _generateBackupRecommendations(
          needsBackup: needsBackup,
          failedImages: failedImages,
          localOnlyImages: localOnlyImages,
          backupRate: backupRate,
        ),
      };

    } catch (e) {
      AppLogger.error('백업 상태 확인 실패', error: e);
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 백업 권장사항 생성
  static List<String> _generateBackupRecommendations({
    required bool needsBackup,
    required int failedImages,
    required int localOnlyImages,
    required double backupRate,
  }) {
    final recommendations = <String>[];

    if (!needsBackup) {
      recommendations.add('✅ 모든 이미지가 안전하게 백업되었습니다!');
      return recommendations;
    }

    if (backupRate < 0.5) {
      recommendations.add('⚠️ 백업률이 50% 미만입니다. 즉시 전체 동기화를 실행하세요.');
    } else if (backupRate < 0.8) {
      recommendations.add('📤 백업률이 80% 미만입니다. 동기화를 권장합니다.');
    }

    if (failedImages > 0) {
      recommendations.add('🔄 $failedImages개의 이미지 업로드가 실패했습니다. 재시도하세요.');
    }

    if (localOnlyImages > 0) {
      recommendations.add('☁️ $localOnlyImages개의 이미지가 로컬에만 저장되어 있습니다. 동기화하세요.');
    }

    recommendations.add('💡 정기적인 동기화로 소중한 이미지를 안전하게 보호하세요.');

    return recommendations;
  }

  /// 서비스 정리
  static void dispose() {
    _syncService.dispose();
  }
}