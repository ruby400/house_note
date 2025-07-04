import 'package:shared_preferences/shared_preferences.dart';
import 'package:house_note/core/utils/logger.dart';
import 'package:house_note/services/firebase_image_service.dart';

/// 백업 정책 관리 서비스
/// 
/// Firebase Storage 무료 요금제 한도를 고려하여
/// 스마트한 백업 정책을 제공합니다.
class BackupPolicyService {
  
  // 무료 요금제 한도
  static const double maxFreeStorageGB = 5.0;
  static const double maxFreeDailyDownloadGB = 1.0;
  static const double warningThresholdGB = 4.5; // 90% 사용 시 경고
  
  // 설정 키들
  static const String keyEnableBackup = 'enable_cloud_backup';
  static const String keyBackupQuality = 'backup_image_quality';
  static const String keyBackupWifiOnly = 'backup_wifi_only';
  static const String keyLastStorageCheck = 'last_storage_check';
  static const String keyEstimatedUsageGB = 'estimated_usage_gb';

  /// 백업 활성화 여부 확인
  static Future<bool> isBackupEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(keyEnableBackup) ?? false;
    } catch (e) {
      AppLogger.error('백업 설정 확인 실패: $e');
      return false;
    }
  }

  /// 백업 활성화/비활성화
  static Future<void> setBackupEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyEnableBackup, enabled);
      
      AppLogger.info('백업 설정 변경: $enabled');
    } catch (e) {
      AppLogger.error('백업 설정 저장 실패: $e');
    }
  }

  /// 현재 이미지를 백업해야 하는지 판단
  static Future<BackupDecision> shouldBackupImage() async {
    try {
      // 1. 백업이 활성화되어 있는지 확인
      final isEnabled = await isBackupEnabled();
      if (!isEnabled) {
        return BackupDecision.skip('백업이 비활성화됨');
      }

      // 2. 네트워크 상태 확인 (WiFi 전용 설정인 경우)
      final wifiOnly = await isWifiOnlyBackup();
      if (wifiOnly && !await isConnectedToWifi()) {
        return BackupDecision.skip('WiFi 연결 필요');
      }

      // 3. 저장 용량 확인
      final storageCheck = await checkStorageUsage();
      if (storageCheck.isNearLimit) {
        return BackupDecision.skip('저장 용량 부족 (${storageCheck.usedGB.toStringAsFixed(1)}GB/${maxFreeStorageGB}GB)');
      }

      // 4. 일일 다운로드 한도 확인 (추정)
      final downloadCheck = await checkDailyDownloadUsage();
      if (downloadCheck.isNearLimit) {
        return BackupDecision.skip('일일 다운로드 한도 근접');
      }

      return BackupDecision.proceed('백업 가능');
      
    } catch (e) {
      AppLogger.error('백업 정책 확인 실패: $e');
      return BackupDecision.skip('오류로 인한 백업 스킵');
    }
  }

  /// Firebase Storage 사용량 확인
  static Future<StorageUsageInfo> checkStorageUsage() async {
    try {
      // Firebase Storage API를 통한 정확한 사용량 확인은 제한적이므로
      // 업로드된 이미지 수를 기반으로 추정
      final userImages = await FirebaseImageService.getUserImages();
      
      // 이미지당 평균 크기 추정 (압축된 이미지 기준)
      const double avgImageSizeMB = 2.0; // 압축 후 약 2MB
      final double estimatedUsageGB = (userImages.length * avgImageSizeMB) / 1024;
      
      // 로컬에 추정 사용량 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(keyEstimatedUsageGB, estimatedUsageGB);
      await prefs.setString(keyLastStorageCheck, DateTime.now().toIso8601String());
      
      return StorageUsageInfo(
        usedGB: estimatedUsageGB,
        maxGB: maxFreeStorageGB,
        isNearLimit: estimatedUsageGB > warningThresholdGB,
        imageCount: userImages.length,
      );
      
    } catch (e) {
      AppLogger.error('저장 용량 확인 실패: $e');
      
      // 실패 시 로컬 추정값 사용
      final prefs = await SharedPreferences.getInstance();
      final estimatedUsage = prefs.getDouble(keyEstimatedUsageGB) ?? 0.0;
      
      return StorageUsageInfo(
        usedGB: estimatedUsage,
        maxGB: maxFreeStorageGB,
        isNearLimit: estimatedUsage > warningThresholdGB,
        imageCount: -1, // 알 수 없음
      );
    }
  }

  /// 일일 다운로드 사용량 확인 (추정)
  static Future<DownloadUsageInfo> checkDailyDownloadUsage() async {
    try {
      // 실제 다운로드 사용량을 정확히 알기는 어려우므로
      // 안전하게 추정하여 관리
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
      
      final lastCheckDate = prefs.getString('last_download_check_date') ?? '';
      double dailyUsageGB = 0.0;
      
      if (lastCheckDate == today) {
        // 오늘 이미 확인한 경우 저장된 값 사용
        dailyUsageGB = prefs.getDouble('daily_download_usage_gb') ?? 0.0;
      } else {
        // 새로운 날이면 초기화
        dailyUsageGB = 0.0;
        await prefs.setString('last_download_check_date', today);
        await prefs.setDouble('daily_download_usage_gb', 0.0);
      }
      
      return DownloadUsageInfo(
        usedGB: dailyUsageGB,
        maxGB: maxFreeDailyDownloadGB,
        isNearLimit: dailyUsageGB > (maxFreeDailyDownloadGB * 0.8), // 80% 사용 시 경고
      );
      
    } catch (e) {
      AppLogger.error('다운로드 사용량 확인 실패: $e');
      return DownloadUsageInfo(
        usedGB: 0.0,
        maxGB: maxFreeDailyDownloadGB,
        isNearLimit: false,
      );
    }
  }

  /// WiFi 전용 백업 설정 확인
  static Future<bool> isWifiOnlyBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(keyBackupWifiOnly) ?? true; // 기본값: WiFi만 사용
    } catch (e) {
      AppLogger.error('WiFi 설정 확인 실패: $e');
      return true; // 안전하게 WiFi만 사용
    }
  }

  /// WiFi 연결 상태 확인
  static Future<bool> isConnectedToWifi() async {
    try {
      // 실제 구현에서는 connectivity_plus 패키지 사용
      // 여기서는 개념적 구현만 제공
      return true; // 임시로 항상 true 반환
    } catch (e) {
      AppLogger.error('WiFi 연결 확인 실패: $e');
      return false;
    }
  }

  /// 백업 품질 설정 가져오기
  static Future<int> getBackupQuality() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(keyBackupQuality) ?? 60; // 기본값: 60% 품질
    } catch (e) {
      AppLogger.error('백업 품질 설정 확인 실패: $e');
      return 60;
    }
  }

  /// 백업 품질 설정 저장
  static Future<void> setBackupQuality(int quality) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(keyBackupQuality, quality);
      
      AppLogger.info('백업 품질 설정: $quality%');
    } catch (e) {
      AppLogger.error('백업 품질 설정 저장 실패: $e');
    }
  }

  /// 다운로드 사용량 추가 (추정)
  static Future<void> addDownloadUsage(double sizeGB) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      
      final lastCheckDate = prefs.getString('last_download_check_date') ?? '';
      double currentUsage = 0.0;
      
      if (lastCheckDate == today) {
        currentUsage = prefs.getDouble('daily_download_usage_gb') ?? 0.0;
      }
      
      final newUsage = currentUsage + sizeGB;
      await prefs.setDouble('daily_download_usage_gb', newUsage);
      await prefs.setString('last_download_check_date', today);
      
      AppLogger.d('일일 다운로드 사용량 업데이트: ${newUsage.toStringAsFixed(3)}GB');
      
    } catch (e) {
      AppLogger.error('다운로드 사용량 업데이트 실패: $e');
    }
  }

  /// 업로드 사용량 추가 (추정)
  static Future<void> addUploadUsage(double sizeGB) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUsage = prefs.getDouble(keyEstimatedUsageGB) ?? 0.0;
      final newUsage = currentUsage + sizeGB;
      
      await prefs.setDouble(keyEstimatedUsageGB, newUsage);
      
      AppLogger.d('총 저장 사용량 업데이트: ${newUsage.toStringAsFixed(3)}GB');
      
    } catch (e) {
      AppLogger.error('업로드 사용량 업데이트 실패: $e');
    }
  }

  /// 백업 설정 초기화 (첫 실행 시)
  static Future<void> initializeBackupSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 첫 실행인지 확인
      final isFirstRun = !prefs.containsKey(keyEnableBackup);
      
      if (isFirstRun) {
        AppLogger.info('백업 설정 초기화 시작');
        
        // 기본 설정값 저장
        await prefs.setBool(keyEnableBackup, false); // 기본값: 비활성화
        await prefs.setInt(keyBackupQuality, 60);    // 기본값: 60% 품질
        await prefs.setBool(keyBackupWifiOnly, true); // 기본값: WiFi만 사용
        await prefs.setDouble(keyEstimatedUsageGB, 0.0);
        
        AppLogger.info('백업 설정 초기화 완료');
      }
      
    } catch (e) {
      AppLogger.error('백업 설정 초기화 실패: $e');
    }
  }

  /// 요금제 업그레이드 안내 메시지
  static String getUpgradeMessage(StorageUsageInfo storageInfo) {
    final usagePercent = (storageInfo.usedGB / storageInfo.maxGB * 100).toInt();
    
    if (usagePercent >= 90) {
      return '⚠️ 저장 공간이 거의 찼습니다 ($usagePercent% 사용)\n'
             'Firebase Blaze 요금제로 업그레이드하면 무제한 저장이 가능합니다.\n'
             '월 \$0.026/GB의 합리적인 요금으로 소중한 이미지를 안전하게 보관하세요.';
    } else if (usagePercent >= 70) {
      return '📊 저장 공간 사용량: $usagePercent%\n'
             '곧 무료 한도(5GB)에 도달할 예정입니다.\n'
             '요금제 업그레이드를 고려해보세요.';
    } else {
      return '✅ 저장 공간 여유: $usagePercent% 사용 중\n'
             '무료 한도 내에서 안전하게 사용 중입니다.';
    }
  }
}

/// 백업 결정 결과
class BackupDecision {
  final bool shouldBackup;
  final String reason;

  const BackupDecision._(this.shouldBackup, this.reason);

  factory BackupDecision.proceed(String reason) => BackupDecision._(true, reason);
  factory BackupDecision.skip(String reason) => BackupDecision._(false, reason);

  @override
  String toString() => 'BackupDecision(shouldBackup: $shouldBackup, reason: $reason)';
}

/// 저장 용량 사용 정보
class StorageUsageInfo {
  final double usedGB;
  final double maxGB;
  final bool isNearLimit;
  final int imageCount;

  const StorageUsageInfo({
    required this.usedGB,
    required this.maxGB,
    required this.isNearLimit,
    required this.imageCount,
  });

  double get usagePercent => (usedGB / maxGB) * 100;
  double get remainingGB => maxGB - usedGB;

  @override
  String toString() => 'StorageUsageInfo(${usedGB.toStringAsFixed(1)}GB/${maxGB}GB, ${usagePercent.toStringAsFixed(1)}%)';
}

/// 다운로드 사용량 정보
class DownloadUsageInfo {
  final double usedGB;
  final double maxGB;
  final bool isNearLimit;

  const DownloadUsageInfo({
    required this.usedGB,
    required this.maxGB,
    required this.isNearLimit,
  });

  double get usagePercent => (usedGB / maxGB) * 100;
  double get remainingGB => maxGB - usedGB;

  @override
  String toString() => 'DownloadUsageInfo(${usedGB.toStringAsFixed(1)}GB/${maxGB}GB 일일)';
}