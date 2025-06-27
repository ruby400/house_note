import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/logger.dart';
import '../data/models/property_chart_model.dart';
import '../providers/property_chart_providers.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

/// 로컬 데이터를 Firebase로 마이그레이션하는 서비스
class DataMigrationService {
  final FirestoreService _firestoreService;
  final AuthService _authService;

  DataMigrationService(this._firestoreService, this._authService);

  /// 로그인 후 자동으로 로컬 데이터를 Firebase로 마이그레이션
  Future<MigrationResult> migrateLocalDataToFirebase(
    List<PropertyChartModel> localCharts
  ) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw '로그인이 필요합니다.';
      }

      AppLogger.info('=== 데이터 마이그레이션 시작 ===');
      AppLogger.info('로컬 차트 개수: ${localCharts.length}');

      if (localCharts.isEmpty) {
        AppLogger.info('마이그레이션할 로컬 데이터가 없습니다.');
        return MigrationResult.success(
          migratedCount: 0,
          skippedCount: 0,
          message: '마이그레이션할 데이터가 없습니다.',
        );
      }

      // Firebase에서 기존 차트 목록 가져오기
      final existingCharts = await _getExistingFirebaseCharts();
      AppLogger.info('Firebase 기존 차트 개수: ${existingCharts.length}');

      int migratedCount = 0;
      int skippedCount = 0;
      List<String> errors = [];

      for (final localChart in localCharts) {
        try {
          // 중복 검사 (제목과 생성 날짜로 판단)
          final isDuplicate = existingCharts.any((existingChart) => 
            existingChart.title.trim().toLowerCase() == localChart.title.trim().toLowerCase() &&
            _isSameDay(existingChart.date, localChart.date)
          );

          if (isDuplicate) {
            AppLogger.info('중복 차트 스킵: ${localChart.title}');
            skippedCount++;
            continue;
          }

          // Firebase에 마이그레이션
          final migrationChart = localChart.copyWith(
            id: '', // Firebase에서 새 ID 생성
          );

          final newChartId = await _firestoreService.saveChart(migrationChart);
          AppLogger.info('차트 마이그레이션 완료: ${localChart.title} -> $newChartId');
          migratedCount++;

        } catch (e) {
          AppLogger.error('차트 마이그레이션 실패: ${localChart.title}', error: e);
          errors.add('${localChart.title}: $e');
        }
      }

      // 통계 업데이트
      await _firestoreService.updateUserStats();

      AppLogger.info('=== 데이터 마이그레이션 완료 ===');
      AppLogger.info('마이그레이션 성공: $migratedCount개');
      AppLogger.info('중복으로 스킵: $skippedCount개');
      AppLogger.info('오류: ${errors.length}개');

      if (errors.isNotEmpty) {
        return MigrationResult.partialSuccess(
          migratedCount: migratedCount,
          skippedCount: skippedCount,
          errors: errors,
        );
      } else {
        return MigrationResult.success(
          migratedCount: migratedCount,
          skippedCount: skippedCount,
          message: '모든 데이터가 성공적으로 마이그레이션되었습니다.',
        );
      }

    } catch (e, stackTrace) {
      AppLogger.error('데이터 마이그레이션 전체 실패', error: e, stackTrace: stackTrace);
      return MigrationResult.failure(
        error: e.toString(),
      );
    }
  }

  /// 사용자의 기존 Firebase 차트 목록 가져오기
  Future<List<PropertyChartModel>> _getExistingFirebaseCharts() async {
    try {
      // Stream을 한 번만 가져오기 위해 first 사용
      return await _firestoreService.getUserCharts().first;
    } catch (e) {
      AppLogger.error('기존 Firebase 차트 조회 실패', error: e);
      return [];
    }
  }

  /// 같은 날짜인지 확인
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// 마이그레이션 필요 여부 확인
  Future<bool> needsMigration(List<PropertyChartModel> localCharts) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return false;

      if (localCharts.isEmpty) return false;

      final existingCharts = await _getExistingFirebaseCharts();
      
      // Firebase에 차트가 없으면 마이그레이션 필요
      if (existingCharts.isEmpty) return true;

      // 로컬에만 있는 차트가 있는지 확인
      for (final localChart in localCharts) {
        final existsInFirebase = existingCharts.any((existingChart) => 
          existingChart.title.trim().toLowerCase() == localChart.title.trim().toLowerCase() &&
          _isSameDay(existingChart.date, localChart.date)
        );
        
        if (!existsInFirebase) {
          return true; // 마이그레이션이 필요한 차트가 있음
        }
      }

      return false; // 모든 차트가 이미 Firebase에 있음
    } catch (e) {
      AppLogger.error('마이그레이션 필요 여부 확인 실패', error: e);
      return false;
    }
  }

  /// 로컬 데이터 백업 (마이그레이션 전)
  Map<String, dynamic> createLocalDataBackup(List<PropertyChartModel> localCharts) {
    return {
      'version': '1.0.0',
      'backupDate': DateTime.now().toIso8601String(),
      'chartCount': localCharts.length,
      'charts': localCharts.map((chart) => chart.toJson()).toList(),
    };
  }
}

/// 마이그레이션 결과
class MigrationResult {
  final bool isSuccess;
  final int migratedCount;
  final int skippedCount;
  final String? message;
  final List<String>? errors;

  MigrationResult._({
    required this.isSuccess,
    required this.migratedCount,
    required this.skippedCount,
    this.message,
    this.errors,
  });

  factory MigrationResult.success({
    required int migratedCount,
    required int skippedCount,
    required String message,
  }) {
    return MigrationResult._(
      isSuccess: true,
      migratedCount: migratedCount,
      skippedCount: skippedCount,
      message: message,
    );
  }

  factory MigrationResult.partialSuccess({
    required int migratedCount,
    required int skippedCount,
    required List<String> errors,
  }) {
    return MigrationResult._(
      isSuccess: false,
      migratedCount: migratedCount,
      skippedCount: skippedCount,
      message: '일부 데이터 마이그레이션 중 오류가 발생했습니다.',
      errors: errors,
    );
  }

  factory MigrationResult.failure({
    required String error,
  }) {
    return MigrationResult._(
      isSuccess: false,
      migratedCount: 0,
      skippedCount: 0,
      message: '마이그레이션에 실패했습니다: $error',
    );
  }

  String get summary {
    if (isSuccess) {
      return message ?? '마이그레이션 완료: $migratedCount개 성공, $skippedCount개 스킵';
    } else {
      return message ?? '마이그레이션 실패';
    }
  }
}

// Riverpod Providers
final dataMigrationServiceProvider = Provider<DataMigrationService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final authService = ref.watch(authServiceProvider);
  return DataMigrationService(firestoreService, authService);
});

/// 로그인 시 자동 마이그레이션을 위한 Provider
final autoMigrationProvider = FutureProvider<MigrationResult?>((ref) async {
  final migrationService = ref.watch(dataMigrationServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final localCharts = ref.watch(propertyChartListProvider);

  // 로그인되지 않았으면 마이그레이션 안함
  if (!authService.isSignedIn) {
    return null;
  }

  // 마이그레이션이 필요한지 확인
  final needsMigration = await migrationService.needsMigration(localCharts);
  if (!needsMigration) {
    AppLogger.info('마이그레이션이 필요하지 않습니다.');
    return null;
  }

  // 자동 마이그레이션 실행
  AppLogger.info('자동 마이그레이션 시작');
  return await migrationService.migrateLocalDataToFirebase(localCharts);
});