import 'dart:async';
import 'package:house_note/data/models/property_chart_model.dart';
import 'package:house_note/data/models/enhanced_image_data.dart';
import 'package:house_note/data/models/property_data_extensions.dart';
import 'package:house_note/services/firebase_image_service.dart';
import 'package:house_note/core/utils/logger.dart';

/// 이미지 동기화 서비스
/// 
/// 로컬과 Firebase Storage 간의 이미지 동기화를 관리합니다.
/// 
/// 주요 기능:
/// 1. 백그라운드 이미지 동기화
/// 2. 실패한 업로드 재시도
/// 3. 동기화 상태 모니터링
/// 4. 자동 마이그레이션
class ImageSyncService {
  static final ImageSyncService _instance = ImageSyncService._internal();
  factory ImageSyncService() => _instance;
  ImageSyncService._internal();

  /// 동기화 진행 상태 스트림
  final StreamController<ImageSyncStatus> _syncStatusController = 
      StreamController<ImageSyncStatus>.broadcast();
  
  /// 동기화 상태 스트림
  Stream<ImageSyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// 현재 동기화 진행 중인지 여부
  bool _isSyncing = false;
  
  /// 동기화 취소 토큰
  bool _shouldCancelSync = false;

  /// 재시도 설정
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  /// 단일 PropertyData 동기화
  /// 
  /// [propertyData] 동기화할 PropertyData
  /// Returns 동기화된 PropertyData
  Future<PropertyData> syncPropertyImages(PropertyData propertyData) async {
    try {
      AppLogger.info('PropertyData 이미지 동기화 시작: ${propertyData.id}');

      // 1. 마이그레이션 확인 및 실행
      PropertyData migratedData = propertyData.migrateToEnhancedImages();

      // 2. 동기화되지 않은 이미지들 수집
      final unsyncedImages = migratedData.getAllUnsyncedImages();
      
      if (unsyncedImages.isEmpty) {
        AppLogger.d('동기화할 이미지가 없음: ${propertyData.id}');
        return migratedData;
      }

      AppLogger.info('동기화 대상 이미지: ${unsyncedImages.length}개');

      // 3. 각 이미지를 Firebase에 업로드
      final syncResults = <String, String>{};
      
      for (int i = 0; i < unsyncedImages.length; i++) {
        if (_shouldCancelSync) {
          AppLogger.info('동기화 취소됨');
          break;
        }

        final image = unsyncedImages[i];
        AppLogger.d('이미지 업로드 중 (${i + 1}/${unsyncedImages.length}): ${image.localPath}');

        // 상태 업데이트
        _syncStatusController.add(ImageSyncStatus(
          isActive: true,
          currentImage: i + 1,
          totalImages: unsyncedImages.length,
          imagePath: image.localPath,
          status: 'uploading',
        ));

        // Firebase에 업로드
        final firebaseUrl = await _uploadWithRetry(image.localPath);
        
        if (firebaseUrl != null) {
          syncResults[image.localPath] = firebaseUrl;
          AppLogger.d('업로드 성공: ${image.localPath} -> $firebaseUrl');
        } else {
          AppLogger.warning('업로드 실패: ${image.localPath}');
        }

        // API 제한 방지를 위한 딜레이
        if (i < unsyncedImages.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // 4. 동기화 결과를 PropertyData에 반영
      final syncedData = migratedData.updateImageSyncStatus(syncResults);

      AppLogger.info('PropertyData 동기화 완료: ${propertyData.id} (${syncResults.length}/${unsyncedImages.length}개 성공)');

      return syncedData;

    } catch (e) {
      AppLogger.error('PropertyData 동기화 실패: ${propertyData.id}', error: e);
      return propertyData;
    }
  }

  /// 전체 차트 동기화
  /// 
  /// [chart] 동기화할 PropertyChartModel
  /// Returns 동기화된 PropertyChartModel
  Future<PropertyChartModel> syncChartImages(PropertyChartModel chart) async {
    if (_isSyncing) {
      AppLogger.warning('이미 동기화가 진행 중입니다');
      return chart;
    }

    try {
      _isSyncing = true;
      _shouldCancelSync = false;

      AppLogger.info('차트 이미지 동기화 시작: ${chart.id}');

      // 동기화 시작 알림
      _syncStatusController.add(ImageSyncStatus(
        isActive: true,
        currentProperty: 0,
        totalProperties: chart.properties.length,
        status: 'starting',
      ));

      // 1. 차트 마이그레이션
      PropertyChartModel migratedChart = chart.migrateToEnhancedImages();

      // 2. 각 PropertyData 동기화
      final syncedProperties = <PropertyData>[];
      
      for (int i = 0; i < migratedChart.properties.length; i++) {
        if (_shouldCancelSync) {
          AppLogger.info('차트 동기화 취소됨');
          break;
        }

        final property = migratedChart.properties[i];
        
        // 상태 업데이트
        _syncStatusController.add(ImageSyncStatus(
          isActive: true,
          currentProperty: i + 1,
          totalProperties: migratedChart.properties.length,
          propertyId: property.id,
          status: 'syncing_property',
        ));

        // PropertyData 동기화
        final syncedProperty = await syncPropertyImages(property);
        syncedProperties.add(syncedProperty);

        AppLogger.d('Property 동기화 완료 (${i + 1}/${migratedChart.properties.length}): ${property.id}');
      }

      final result = migratedChart.copyWith(properties: syncedProperties);

      // 동기화 완료 알림
      _syncStatusController.add(ImageSyncStatus(
        isActive: false,
        status: 'completed',
        completedAt: DateTime.now(),
      ));

      AppLogger.info('차트 동기화 완료: ${chart.id}');
      return result;

    } catch (e) {
      AppLogger.error('차트 동기화 실패: ${chart.id}', error: e);
      
      // 동기화 실패 알림
      _syncStatusController.add(ImageSyncStatus(
        isActive: false,
        status: 'failed',
        error: e.toString(),
      ));

      return chart;
    } finally {
      _isSyncing = false;
    }
  }

  /// 여러 차트 일괄 동기화
  /// 
  /// [charts] 동기화할 차트 목록
  /// Returns 동기화된 차트 목록
  Future<List<PropertyChartModel>> syncMultipleCharts(List<PropertyChartModel> charts) async {
    if (_isSyncing) {
      AppLogger.warning('이미 동기화가 진행 중입니다');
      return charts;
    }

    try {
      _isSyncing = true;
      _shouldCancelSync = false;

      AppLogger.info('다중 차트 동기화 시작: ${charts.length}개 차트');

      final syncedCharts = <PropertyChartModel>[];

      for (int i = 0; i < charts.length; i++) {
        if (_shouldCancelSync) {
          AppLogger.info('다중 차트 동기화 취소됨');
          // 이미 처리된 차트들은 유지
          syncedCharts.addAll(charts.skip(i));
          break;
        }

        final chart = charts[i];
        AppLogger.info('차트 동기화 진행 (${i + 1}/${charts.length}): ${chart.id}');

        final syncedChart = await syncChartImages(chart);
        syncedCharts.add(syncedChart);
      }

      AppLogger.info('다중 차트 동기화 완료: ${syncedCharts.length}/${charts.length}개');
      return syncedCharts;

    } catch (e) {
      AppLogger.error('다중 차트 동기화 실패', error: e);
      return charts;
    } finally {
      _isSyncing = false;
    }
  }

  /// 동기화 취소
  void cancelSync() {
    if (_isSyncing) {
      AppLogger.info('동기화 취소 요청');
      _shouldCancelSync = true;
      
      _syncStatusController.add(ImageSyncStatus(
        isActive: false,
        status: 'cancelled',
      ));
    }
  }

  /// 실패한 이미지들 재동기화
  /// 
  /// [chart] 재동기화할 차트
  /// Returns 재동기화된 차트
  Future<PropertyChartModel> retrySyncFailedImages(PropertyChartModel chart) async {
    try {
      AppLogger.info('실패 이미지 재동기화 시작: ${chart.id}');

      final updatedProperties = <PropertyData>[];

      for (final property in chart.properties) {
        final unsyncedImages = property.getAllUnsyncedImages();
        final failedImages = unsyncedImages.where((img) => img.isFailed).toList();

        if (failedImages.isNotEmpty) {
          AppLogger.d('재동기화 대상 (${property.id}): ${failedImages.length}개');
          final syncedProperty = await syncPropertyImages(property);
          updatedProperties.add(syncedProperty);
        } else {
          updatedProperties.add(property);
        }
      }

      final result = chart.copyWith(properties: updatedProperties);
      AppLogger.info('실패 이미지 재동기화 완료: ${chart.id}');
      
      return result;
    } catch (e) {
      AppLogger.error('실패 이미지 재동기화 실패: ${chart.id}', error: e);
      return chart;
    }
  }

  /// 재시도를 포함한 이미지 업로드
  Future<String?> _uploadWithRetry(String localPath, {int retryCount = 0}) async {
    try {
      final firebaseUrl = await FirebaseImageService.uploadImage(localPath);
      
      if (firebaseUrl != null) {
        return firebaseUrl;
      }
      
      // 업로드 실패 시 재시도
      if (retryCount < maxRetries) {
        AppLogger.d('업로드 재시도 (${retryCount + 1}/$maxRetries): $localPath');
        await Future.delayed(retryDelay);
        return await _uploadWithRetry(localPath, retryCount: retryCount + 1);
      }
      
      AppLogger.warning('업로드 최종 실패: $localPath');
      return null;
      
    } catch (e) {
      AppLogger.error('업로드 오류: $localPath', error: e);
      
      // 재시도 가능한 오류인지 확인
      if (retryCount < maxRetries && _isRetryableError(e)) {
        AppLogger.d('재시도 가능한 오류, 재시도 (${retryCount + 1}/$maxRetries): $localPath');
        await Future.delayed(retryDelay);
        return await _uploadWithRetry(localPath, retryCount: retryCount + 1);
      }
      
      return null;
    }
  }

  /// 재시도 가능한 오류인지 확인
  bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // 네트워크 관련 오류는 재시도 가능
    if (errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('socket')) {
      return true;
    }
    
    // Firebase 관련 임시 오류도 재시도 가능
    if (errorString.contains('internal-error') ||
        errorString.contains('unavailable') ||
        errorString.contains('deadline-exceeded')) {
      return true;
    }
    
    return false;
  }

  /// 동기화 통계 정보
  Future<Map<String, dynamic>> getSyncStats(List<PropertyChartModel> charts) async {
    try {
      int totalCharts = charts.length;
      int totalProperties = 0;
      int totalImages = 0;
      int syncedImages = 0;
      int pendingImages = 0;
      int failedImages = 0;
      int localOnlyImages = 0;

      for (final chart in charts) {
        final stats = chart.getImageStats();
        totalProperties += (stats['totalProperties'] as int? ?? 0);
        totalImages += (stats['totalImages'] as int? ?? 0);
        syncedImages += (stats['syncedImages'] as int? ?? 0);
        pendingImages += (stats['pendingImages'] as int? ?? 0);
        failedImages += (stats['failedImages'] as int? ?? 0);
        localOnlyImages += (stats['localOnlyImages'] as int? ?? 0);
      }

      final isFirebaseConnected = await FirebaseImageService.isConnected();

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'isFirebaseConnected': isFirebaseConnected,
        'isSyncing': _isSyncing,
        'totalCharts': totalCharts,
        'totalProperties': totalProperties,
        'totalImages': totalImages,
        'syncedImages': syncedImages,
        'pendingImages': pendingImages,
        'failedImages': failedImages,
        'localOnlyImages': localOnlyImages,
        'syncRate': totalImages > 0 ? (syncedImages / totalImages) : 0.0,
        'needsSync': pendingImages + failedImages + localOnlyImages > 0,
      };
    } catch (e) {
      AppLogger.error('동기화 통계 수집 실패', error: e);
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 서비스 종료 시 정리
  void dispose() {
    _syncStatusController.close();
  }
}

/// 이미지 동기화 상태
class ImageSyncStatus {
  /// 동기화 진행 중인지 여부
  final bool isActive;
  
  /// 현재 처리 중인 Property 인덱스
  final int? currentProperty;
  
  /// 전체 Property 수
  final int? totalProperties;
  
  /// 현재 처리 중인 Property ID
  final String? propertyId;
  
  /// 현재 처리 중인 이미지 인덱스
  final int? currentImage;
  
  /// 전체 이미지 수
  final int? totalImages;
  
  /// 현재 처리 중인 이미지 경로
  final String? imagePath;
  
  /// 동기화 상태
  /// - 'starting': 동기화 시작
  /// - 'syncing_property': Property 동기화 중
  /// - 'uploading': 이미지 업로드 중
  /// - 'completed': 동기화 완료
  /// - 'failed': 동기화 실패
  /// - 'cancelled': 동기화 취소
  final String status;
  
  /// 오류 메시지 (실패 시)
  final String? error;
  
  /// 완료 시각
  final DateTime? completedAt;

  const ImageSyncStatus({
    required this.isActive,
    this.currentProperty,
    this.totalProperties,
    this.propertyId,
    this.currentImage,
    this.totalImages,
    this.imagePath,
    required this.status,
    this.error,
    this.completedAt,
  });

  /// 진행률 계산 (0.0 ~ 1.0)
  double get progress {
    if (totalProperties != null && currentProperty != null && totalProperties! > 0) {
      return (currentProperty! - 1) / totalProperties!;
    }
    
    if (totalImages != null && currentImage != null && totalImages! > 0) {
      return (currentImage! - 1) / totalImages!;
    }
    
    return 0.0;
  }

  /// 사용자 친화적 상태 메시지
  String get friendlyMessage {
    switch (status) {
      case 'starting':
        return '동기화를 시작합니다...';
      case 'syncing_property':
        if (currentProperty != null && totalProperties != null) {
          return 'Property 동기화 중 ($currentProperty/$totalProperties)';
        }
        return 'Property 동기화 중...';
      case 'uploading':
        if (currentImage != null && totalImages != null) {
          return '이미지 업로드 중 ($currentImage/$totalImages)';
        }
        return '이미지 업로드 중...';
      case 'completed':
        return '동기화가 완료되었습니다';
      case 'failed':
        return '동기화에 실패했습니다${error != null ? ': $error' : ''}';
      case 'cancelled':
        return '동기화가 취소되었습니다';
      default:
        return status;
    }
  }

  @override
  String toString() {
    return 'ImageSyncStatus('
        'isActive: $isActive, '
        'status: $status, '
        'progress: ${(progress * 100).toStringAsFixed(1)}%'
        ')';
  }
}