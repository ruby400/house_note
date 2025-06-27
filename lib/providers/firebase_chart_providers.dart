import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/logger.dart';
import '../data/models/property_chart_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/data_migration_service.dart';
import 'property_chart_providers.dart';

/// Firebase와 로컬 데이터를 통합 관리하는 Provider들

// Firebase 차트 목록 Provider (실시간 동기화)
final firebaseChartsProvider = StreamProvider<List<PropertyChartModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final authService = ref.watch(authServiceProvider);

  if (!authService.isSignedIn) {
    return Stream.value([]);
  }

  return firestoreService.getUserCharts();
});

// 통합 차트 목록 Provider (로컬 + Firebase 병합)
final integratedChartsProvider = Provider<List<PropertyChartModel>>((ref) {
  final authService = ref.watch(authServiceProvider);
  final localCharts = ref.watch(propertyChartListProvider);
  
  if (authService.isSignedIn) {
    // 로그인된 경우 Firebase와 로컬 데이터 병합
    final firebaseCharts = ref.watch(firebaseChartsProvider);
    return firebaseCharts.when(
      data: (firebaseData) {
        // Firebase 데이터를 기준으로 로컬 데이터 동기화
        _syncLocalWithFirebase(ref, localCharts, firebaseData);
        
        // Firebase 데이터가 최신이므로 Firebase 데이터 사용
        AppLogger.info('Firebase 차트 로드 완료: ${firebaseData.length}개 (로컬과 동기화됨)');
        return firebaseData;
      },
      loading: () {
        AppLogger.info('Firebase 차트 로딩 중... 로컬 데이터 사용');
        return localCharts;
      },
      error: (error, stack) {
        AppLogger.error('Firebase 차트 로드 실패', error: error);
        AppLogger.info('로컬 데이터로 fallback: ${localCharts.length}개');
        return localCharts;
      },
    );
  } else {
    // 로그인하지 않은 경우 로컬 데이터만 사용
    AppLogger.info('로그인하지 않은 상태 - 로컬 데이터 사용: ${localCharts.length}개');
    return localCharts;
  }
});

// 로컬과 Firebase 데이터 동기화 함수 (안전한 버전)
void _syncLocalWithFirebase(Ref ref, List<PropertyChartModel> localCharts, List<PropertyChartModel> firebaseCharts) {
  try {
    AppLogger.info('동기화 시작: 로컬 ${localCharts.length}개, Firebase ${firebaseCharts.length}개');
    
    // 동기화는 백그라운드에서만 수행하여 UI 충돌 방지
    Future.microtask(() async {
      try {
        final firestoreService = ref.read(firestoreServiceProvider);
        final firebaseIds = firebaseCharts.map((c) => c.id).toSet();
        
        // 1. 로컬에만 있는 차트를 Firebase에 업로드
        final localOnlyCharts = localCharts.where((chart) => !firebaseIds.contains(chart.id)).toList();
        if (localOnlyCharts.isNotEmpty) {
          AppLogger.info('로컬 전용 차트 ${localOnlyCharts.length}개를 Firebase에 업로드');
          for (final chart in localOnlyCharts) {
            try {
              await firestoreService.saveChart(chart);
              AppLogger.info('업로드 완료: ${chart.title} (${chart.id})');
            } catch (e) {
              AppLogger.error('업로드 실패: ${chart.title}', error: e);
            }
          }
        }
      } catch (e) {
        AppLogger.error('백그라운드 동기화 실패', error: e);
      }
    });
    
  } catch (e) {
    AppLogger.error('동기화 초기화 실패', error: e);
  }
}

// 차트 관리 서비스 (Firebase와 로컬 통합)
class IntegratedChartService {
  final FirestoreService _firestoreService;
  final AuthService _authService;
  final Ref _ref;

  IntegratedChartService(this._firestoreService, this._authService, this._ref);

  /// 차트 저장 (로컬과 Firebase 동시 저장)
  Future<String> saveChart(PropertyChartModel chart) async {
    try {
      String chartId = chart.id;
      
      // 새 차트인 경우 ID 생성
      if (chartId.isEmpty) {
        chartId = DateTime.now().millisecondsSinceEpoch.toString();
        chart = chart.copyWith(id: chartId);
      }

      // 1. 로컬에 저장 (항상 실행) - 중복 방지 로직
      final existingCharts = _ref.read(propertyChartListProvider);
      final existingChartIndex = existingCharts.indexWhere((c) => c.id == chartId);
      
      if (existingChartIndex == -1) {
        // 새 차트인 경우만 추가
        AppLogger.info('새 차트 로컬 저장: ${chart.title} ($chartId)');
        // Firebase에서 받은 차트를 그대로 추가 (기본 데이터 변경 없이)
        _ref.read(propertyChartListProvider.notifier).addChartAsIs(chart);
      } else {
        // 기존 차트 업데이트
        AppLogger.info('기존 차트 로컬 업데이트: ${chart.title} ($chartId)');
        _ref.read(propertyChartListProvider.notifier).updateChart(chart);
      }

      // 2. Firebase에 저장 (로그인한 경우)
      if (_authService.isSignedIn) {
        try {
          await _firestoreService.saveChart(chart);
          AppLogger.info('Firebase에 차트 저장 완료: $chartId');
        } catch (e) {
          AppLogger.error('Firebase 저장 실패 (로컬은 저장됨)', error: e);
          // Firebase 실패해도 로컬은 저장되었으므로 계속 진행
        }
      } else {
        AppLogger.info('로그인하지 않음 - 로컬에만 저장: $chartId');
      }

      return chartId;
    } catch (e) {
      AppLogger.error('차트 저장 실패', error: e);
      rethrow;
    }
  }

  /// 차트 삭제 (로컬과 Firebase 동시 삭제)
  Future<void> deleteChart(String chartId) async {
    try {
      // 1. 로컬에서 삭제 (항상 실행)
      _ref.read(propertyChartListProvider.notifier).deleteChart(chartId);
      AppLogger.info('로컬에서 차트 삭제: $chartId');

      // 2. Firebase에서 삭제 (로그인한 경우)
      if (_authService.isSignedIn) {
        try {
          await _firestoreService.deleteChart(chartId);
          AppLogger.info('Firebase에서 차트 삭제: $chartId');
        } catch (e) {
          AppLogger.error('Firebase 삭제 실패 (로컬은 삭제됨)', error: e);
          // Firebase 실패해도 로컬은 삭제되었으므로 계속 진행
        }
      } else {
        AppLogger.info('로그인하지 않음 - 로컬에서만 삭제: $chartId');
      }
    } catch (e) {
      AppLogger.error('차트 삭제 실패', error: e);
      rethrow;
    }
  }

  /// 차트 조회
  Future<PropertyChartModel?> getChart(String chartId) async {
    try {
      if (_authService.isSignedIn) {
        // Firebase에서 조회
        return await _firestoreService.getChart(chartId);
      } else {
        // 로컬에서 조회
        return _ref.read(propertyChartListProvider.notifier).getChart(chartId);
      }
    } catch (e) {
      AppLogger.error('차트 조회 실패', error: e);
      return null;
    }
  }

  /// 로그인 후 데이터 동기화
  Future<MigrationResult?> syncDataAfterLogin() async {
    try {
      if (!_authService.isSignedIn) {
        AppLogger.warning('로그인되지 않은 상태에서 동기화 시도');
        return null;
      }

      final migrationService = DataMigrationService(_firestoreService, _authService);
      final localCharts = _ref.read(propertyChartListProvider);

      // 마이그레이션 필요 여부 확인
      final needsMigration = await migrationService.needsMigration(localCharts);
      if (!needsMigration) {
        AppLogger.info('동기화가 필요하지 않습니다.');
        return null;
      }

      // 로컬 데이터를 Firebase로 마이그레이션
      final result = await migrationService.migrateLocalDataToFirebase(localCharts);
      AppLogger.info('로그인 후 데이터 동기화 완료: ${result.summary}');
      
      return result;
    } catch (e) {
      AppLogger.error('로그인 후 데이터 동기화 실패', error: e);
      return MigrationResult.failure(error: e.toString());
    }
  }

  /// 오프라인 모드 활성화
  void enableOfflineMode() {
    _firestoreService.enableOfflineSupport();
    AppLogger.info('오프라인 모드 활성화');
  }

  /// 네트워크 연결 상태 확인
  Future<bool> isOnline() async {
    return await _firestoreService.isConnected();
  }

  /// 강제 동기화
  Future<void> forceSync() async {
    if (!_authService.isSignedIn) {
      throw '로그인이 필요합니다.';
    }

    try {
      AppLogger.info('강제 동기화 시작');
      
      // Firestore 네트워크 재연결
      await _firestoreService.isConnected();
      
      // 통계 업데이트
      await _firestoreService.updateUserStats();
      
      AppLogger.info('강제 동기화 완료');
    } catch (e) {
      AppLogger.error('강제 동기화 실패', error: e);
      rethrow;
    }
  }

  /// 로컬 차트 데이터 완전 초기화 (예시 데이터 제거)
  void clearLocalCharts() {
    AppLogger.info('로컬 차트 데이터 완전 초기화');
    _ref.read(propertyChartListProvider.notifier).clearAllCharts();
    _ref.read(currentChartProvider.notifier).clearCurrentChart();
  }

  /// 로컬 차트를 기본 상태로 리셋 (예시 차트 하나만 남김)
  void resetLocalChartsToDefault() {
    AppLogger.info('로컬 차트를 기본 상태로 리셋');
    _ref.read(propertyChartListProvider.notifier).resetToDefaultChart();
    _ref.read(currentChartProvider.notifier).clearCurrentChart();
  }

  /// 현재 차트의 데이터만 초기화 (빈 차트로 만들기)
  void clearCurrentChartData() {
    AppLogger.info('현재 차트의 데이터만 초기화');
    _ref.read(currentChartProvider.notifier).clearCurrentChartData();
  }
}

// 통합 차트 서비스 Provider
final integratedChartServiceProvider = Provider<IntegratedChartService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final authService = ref.watch(authServiceProvider);
  return IntegratedChartService(firestoreService, authService, ref);
});

// 특정 차트 Provider (Firebase + 로컬 통합)
final integratedChartProvider = FutureProvider.family<PropertyChartModel?, String>((ref, chartId) async {
  final chartService = ref.watch(integratedChartServiceProvider);
  return await chartService.getChart(chartId);
});

// 로그인 후 자동 동기화 Provider
final loginSyncProvider = FutureProvider<MigrationResult?>((ref) async {
  final chartService = ref.watch(integratedChartServiceProvider);
  final authService = ref.watch(authServiceProvider);
  
  if (!authService.isSignedIn) {
    return null;
  }

  // 로그인 상태가 변경될 때마다 동기화 시도
  return await chartService.syncDataAfterLogin();
});

// 네트워크 상태 Provider
final networkStatusProvider = FutureProvider<bool>((ref) async {
  final chartService = ref.watch(integratedChartServiceProvider);
  return await chartService.isOnline();
});

// 동기화 상태 관리
class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  final IntegratedChartService _chartService;

  SyncStatusNotifier(this._chartService) : super(SyncStatus.idle);

  Future<void> sync() async {
    if (state == SyncStatus.syncing) return;

    state = SyncStatus.syncing;
    try {
      await _chartService.forceSync();
      state = SyncStatus.success;
      
      // 3초 후 idle 상태로 복원
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) state = SyncStatus.idle;
      });
    } catch (e) {
      state = SyncStatus.error;
      AppLogger.error('동기화 실패', error: e);
      
      // 5초 후 idle 상태로 복원
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) state = SyncStatus.idle;
      });
    }
  }
}

enum SyncStatus { idle, syncing, success, error }

final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  final chartService = ref.watch(integratedChartServiceProvider);
  return SyncStatusNotifier(chartService);
});