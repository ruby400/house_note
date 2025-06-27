import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/logger.dart';
import '../providers/firebase_chart_providers.dart';
import 'image_service.dart';
import 'auth_service.dart';

/// 앱 데이터 초기화 서비스
/// 로컬 저장소에 저장된 차트 데이터와 이미지 파일들을 초기화하는 기능 제공
class DataResetService {
  final Ref _ref;

  DataResetService(this._ref);

  /// 모든 로컬 데이터 완전 초기화
  /// - 모든 차트 데이터 삭제
  /// - 모든 이미지 파일 삭제
  /// - 현재 선택된 차트 해제
  Future<DataResetResult> resetAllData() async {
    try {
      AppLogger.info('=== 모든 로컬 데이터 완전 초기화 시작 ===');
      
      final integratedService = _ref.read(integratedChartServiceProvider);
      
      // 1. 차트 데이터 초기화
      AppLogger.info('1단계: 차트 데이터 초기화');
      integratedService.clearLocalCharts();
      
      // 2. 이미지 파일 정리
      AppLogger.info('2단계: 이미지 파일 정리');
      await ImageService.cleanupImages();
      
      AppLogger.info('=== 모든 로컬 데이터 완전 초기화 완료 ===');
      
      return DataResetResult.success(
        message: '모든 로컬 데이터가 성공적으로 초기화되었습니다.',
        resetType: ResetType.all,
      );
    } catch (e, stackTrace) {
      AppLogger.error('모든 로컬 데이터 초기화 실패', error: e, stackTrace: stackTrace);
      return DataResetResult.failure(
        error: e.toString(),
        resetType: ResetType.all,
      );
    }
  }

  /// 차트 데이터만 초기화 (기본 예시 차트로 리셋)
  /// - 모든 차트를 삭제하고 기본 예시 차트 하나만 남김
  /// - 현재 선택된 차트 해제
  Future<DataResetResult> resetToDefaultChart() async {
    try {
      AppLogger.info('=== 차트 데이터 기본값으로 리셋 시작 ===');
      
      final integratedService = _ref.read(integratedChartServiceProvider);
      
      // 기본 차트로 리셋
      integratedService.resetLocalChartsToDefault();
      
      AppLogger.info('=== 차트 데이터 기본값으로 리셋 완료 ===');
      
      return DataResetResult.success(
        message: '차트 데이터가 기본 예시 차트로 초기화되었습니다.',
        resetType: ResetType.chartsToDefault,
      );
    } catch (e, stackTrace) {
      AppLogger.error('차트 데이터 기본값 리셋 실패', error: e, stackTrace: stackTrace);
      return DataResetResult.failure(
        error: e.toString(),
        resetType: ResetType.chartsToDefault,
      );
    }
  }

  /// 모든 차트 데이터 삭제 (빈 상태로 만들기)
  /// - 모든 차트 데이터 삭제
  /// - 현재 선택된 차트 해제
  Future<DataResetResult> clearAllCharts() async {
    try {
      AppLogger.info('=== 모든 차트 데이터 삭제 시작 ===');
      
      final integratedService = _ref.read(integratedChartServiceProvider);
      
      // 모든 차트 삭제
      integratedService.clearLocalCharts();
      
      AppLogger.info('=== 모든 차트 데이터 삭제 완료 ===');
      
      return DataResetResult.success(
        message: '모든 차트 데이터가 삭제되었습니다.',
        resetType: ResetType.chartsOnly,
      );
    } catch (e, stackTrace) {
      AppLogger.error('모든 차트 데이터 삭제 실패', error: e, stackTrace: stackTrace);
      return DataResetResult.failure(
        error: e.toString(),
        resetType: ResetType.chartsOnly,
      );
    }
  }

  /// 현재 차트의 데이터만 초기화 (빈 차트로 만들기)
  /// - 현재 선택된 차트의 프로퍼티 데이터만 삭제
  /// - 차트 자체는 유지
  Future<DataResetResult> clearCurrentChartData() async {
    try {
      AppLogger.info('=== 현재 차트 데이터 초기화 시작 ===');
      
      final integratedService = _ref.read(integratedChartServiceProvider);
      
      // 현재 차트의 데이터만 초기화
      integratedService.clearCurrentChartData();
      
      AppLogger.info('=== 현재 차트 데이터 초기화 완료 ===');
      
      return DataResetResult.success(
        message: '현재 차트의 데이터가 초기화되었습니다.',
        resetType: ResetType.currentChart,
      );
    } catch (e, stackTrace) {
      AppLogger.error('현재 차트 데이터 초기화 실패', error: e, stackTrace: stackTrace);
      return DataResetResult.failure(
        error: e.toString(),
        resetType: ResetType.currentChart,
      );
    }
  }

  /// 이미지 파일만 정리
  /// - 앱 내부 저장소의 모든 이미지 파일 삭제
  /// - 차트 데이터는 유지
  Future<DataResetResult> cleanupImagesOnly() async {
    try {
      AppLogger.info('=== 이미지 파일만 정리 시작 ===');
      
      await ImageService.cleanupImages();
      
      AppLogger.info('=== 이미지 파일만 정리 완료 ===');
      
      return DataResetResult.success(
        message: '모든 이미지 파일이 정리되었습니다.',
        resetType: ResetType.imagesOnly,
      );
    } catch (e, stackTrace) {
      AppLogger.error('이미지 파일 정리 실패', error: e, stackTrace: stackTrace);
      return DataResetResult.failure(
        error: e.toString(),
        resetType: ResetType.imagesOnly,
      );
    }
  }

  /// 로그인 상태 확인
  bool get isSignedIn {
    final authService = _ref.read(authServiceProvider);
    return authService.isSignedIn;
  }

  /// Firebase 데이터는 건드리지 않음을 경고
  String get firebaseWarning {
    return '이 작업은 로컬 데이터만 초기화합니다. 로그인된 상태에서는 Firebase에 저장된 데이터가 다시 동기화될 수 있습니다.';
  }
}

/// 데이터 초기화 결과
class DataResetResult {
  final bool isSuccess;
  final String message;
  final ResetType resetType;
  final String? error;

  DataResetResult._({
    required this.isSuccess,
    required this.message,
    required this.resetType,
    this.error,
  });

  factory DataResetResult.success({
    required String message,
    required ResetType resetType,
  }) {
    return DataResetResult._(
      isSuccess: true,
      message: message,
      resetType: resetType,
    );
  }

  factory DataResetResult.failure({
    required String error,
    required ResetType resetType,
  }) {
    return DataResetResult._(
      isSuccess: false,
      message: '초기화 중 오류가 발생했습니다: $error',
      resetType: resetType,
      error: error,
    );
  }
}

/// 초기화 타입
enum ResetType {
  all,              // 모든 데이터 초기화
  chartsToDefault,  // 차트를 기본값으로 리셋
  chartsOnly,       // 차트 데이터만 삭제
  currentChart,     // 현재 차트만 초기화
  imagesOnly,       // 이미지 파일만 정리
}

extension ResetTypeExtension on ResetType {
  String get displayName {
    switch (this) {
      case ResetType.all:
        return '모든 데이터 초기화';
      case ResetType.chartsToDefault:
        return '기본 차트로 리셋';
      case ResetType.chartsOnly:
        return '모든 차트 삭제';
      case ResetType.currentChart:
        return '현재 차트 초기화';
      case ResetType.imagesOnly:
        return '이미지 파일 정리';
    }
  }

  String get description {
    switch (this) {
      case ResetType.all:
        return '모든 차트 데이터와 이미지 파일을 완전히 삭제합니다.';
      case ResetType.chartsToDefault:
        return '모든 차트를 삭제하고 기본 예시 차트 하나만 남깁니다.';
      case ResetType.chartsOnly:
        return '모든 차트 데이터를 삭제합니다. (이미지 파일은 유지)';
      case ResetType.currentChart:
        return '현재 선택된 차트의 데이터만 초기화합니다.';
      case ResetType.imagesOnly:
        return '앱 내부 저장소의 모든 이미지 파일을 삭제합니다. (차트 데이터는 유지)';
    }
  }
}

// Riverpod Provider
final dataResetServiceProvider = Provider<DataResetService>((ref) {
  return DataResetService(ref);
});