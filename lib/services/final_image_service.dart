import 'package:flutter/material.dart';
import 'package:house_note/services/optimized_image_service.dart';
import 'package:house_note/services/firebase_image_service.dart';
import 'package:house_note/services/premium_subscription_service.dart';
import 'package:house_note/core/utils/logger.dart';

/// 최종 통합 이미지 서비스
/// 
/// 기능:
/// 1. 모든 이미지는 최대 압축 (용량 최소화)
/// 2. 클라우드 백업은 프리미엄 사용자만 가능
/// 3. 기존 API 완전 호환
class FinalImageService {
  
  /// 카메라로 사진 촬영
  /// - 모든 사용자: 최대 압축 로컬 저장
  /// - 프리미엄 사용자: 추가로 Firebase 백업
  static Future<String?> takePicture() async {
    try {
      AppLogger.info('📸 통합 이미지 촬영 시작');

      // 1. 최적화된 이미지 촬영 (모든 사용자)
      final String? localPath = await OptimizedImageService.takePictureOptimized();
      
      if (localPath == null) {
        AppLogger.d('❌ 이미지 촬영 취소됨');
        return null;
      }

      // 2. 프리미엄 사용자인지 확인
      final canBackup = await PremiumSubscriptionService.canUseCloudBackup();
      
      if (canBackup) {
        // 3. 프리미엄 사용자: Firebase 백업 실행 (백그라운드)
        AppLogger.info('☁️ 프리미엄 사용자 - Firebase 백업 시작');
        _backupToFirebaseAsync(localPath);
      } else {
        AppLogger.d('💾 무료 사용자 - 로컬 저장만 실행');
      }

      return localPath;

    } catch (e) {
      AppLogger.error('❌ 통합 이미지 촬영 실패: $e');
      return null;
    }
  }

  /// 갤러리에서 사진 선택
  static Future<String?> pickImageFromGallery() async {
    try {
      AppLogger.info('🖼️ 통합 갤러리 이미지 선택 시작');

      // 1. 최적화된 이미지 선택 (모든 사용자)
      final String? localPath = await OptimizedImageService.pickImageFromGalleryOptimized();
      
      if (localPath == null) {
        AppLogger.d('❌ 갤러리 선택 취소됨');
        return null;
      }

      // 2. 프리미엄 사용자인지 확인
      final canBackup = await PremiumSubscriptionService.canUseCloudBackup();
      
      if (canBackup) {
        // 3. 프리미엄 사용자: Firebase 백업 실행 (백그라운드)
        AppLogger.info('☁️ 프리미엄 사용자 - Firebase 백업 시작');
        _backupToFirebaseAsync(localPath);
      } else {
        AppLogger.d('💾 무료 사용자 - 로컬 저장만 실행');
      }

      return localPath;

    } catch (e) {
      AppLogger.error('❌ 통합 갤러리 선택 실패: $e');
      return null;
    }
  }

  /// 갤러리에서 여러 사진 선택
  static Future<List<String>> pickMultipleImagesFromGallery() async {
    try {
      AppLogger.info('🖼️ 통합 다중 갤러리 이미지 선택 시작');

      // 1. 최적화된 다중 이미지 선택 (모든 사용자)
      final List<String> localPaths = await OptimizedImageService.pickMultipleImagesFromGalleryOptimized();
      
      if (localPaths.isEmpty) {
        AppLogger.d('❌ 다중 갤러리 선택 취소됨');
        return [];
      }

      // 2. 프리미엄 사용자인지 확인
      final canBackup = await PremiumSubscriptionService.canUseCloudBackup();
      
      if (canBackup) {
        // 3. 프리미엄 사용자: 모든 이미지를 Firebase에 백업 (백그라운드)
        AppLogger.info('☁️ 프리미엄 사용자 - ${localPaths.length}개 이미지 Firebase 백업 시작');
        for (final path in localPaths) {
          _backupToFirebaseAsync(path);
        }
      } else {
        AppLogger.d('💾 무료 사용자 - ${localPaths.length}개 이미지 로컬 저장만 실행');
      }

      return localPaths;

    } catch (e) {
      AppLogger.error('❌ 통합 다중 갤러리 선택 실패: $e');
      return [];
    }
  }

  /// 백그라운드 Firebase 백업 (프리미엄 사용자만)
  static void _backupToFirebaseAsync(String localPath) {
    // 백그라운드에서 실행 (UI 블로킹하지 않음)
    Future.microtask(() async {
      try {
        final syncResult = await FirebaseImageService.syncImage(localPath);
        
        if (syncResult['firebaseUrl'] != null) {
          AppLogger.info('✅ Firebase 백업 완료: ${syncResult['firebaseUrl']}');
        } else {
          AppLogger.warning('❌ Firebase 백업 실패: $localPath');
        }
      } catch (e) {
        AppLogger.error('❌ 백그라운드 Firebase 백업 오류: $e');
      }
    });
  }

  /// 프리미엄 기능 시도 시 권한 확인 및 안내
  static Future<bool> tryPremiumFeature(String featureName, {
    Function? onUpgradeNeeded,
  }) async {
    try {
      final accessResult = await PremiumSubscriptionService.checkPremiumAccess(featureName);
      
      if (accessResult.isAllowed) {
        return true;
      } else {
        AppLogger.info('프리미엄 기능 접근 차단: $featureName');
        
        // 업그레이드 안내 콜백 호출
        if (onUpgradeNeeded != null) {
          onUpgradeNeeded();
        }
        
        return false;
      }
    } catch (e) {
      AppLogger.error('프리미엄 기능 확인 실패: $e');
      return false;
    }
  }

  /// 클라우드 백업 시도 (프리미엄 체크 포함)
  static Future<Map<String, String?>> tryCloudBackup(String localPath) async {
    try {
      // 프리미엄 기능 접근 확인
      final canBackup = await PremiumSubscriptionService.canUseCloudBackup();
      
      if (!canBackup) {
        AppLogger.info('⚠️ 클라우드 백업은 프리미엄 기능입니다');
        return {
          'localPath': localPath,
          'firebaseUrl': null,
          'error': 'Premium feature required',
          'message': '클라우드 백업은 프리미엄 사용자만 이용할 수 있습니다.',
        };
      }

      // 프리미엄 사용자: Firebase 백업 실행
      final syncResult = await FirebaseImageService.syncImage(localPath);
      
      return {
        'localPath': localPath,
        'firebaseUrl': syncResult['firebaseUrl'],
        'syncStatus': syncResult['firebaseUrl'] != null ? 'synced' : 'failed',
      };

    } catch (e) {
      AppLogger.error('클라우드 백업 실패: $e');
      return {
        'localPath': localPath,
        'firebaseUrl': null,
        'error': e.toString(),
      };
    }
  }

  /// 구독 상태 확인
  static Future<Map<String, dynamic>> getSubscriptionInfo() async {
    try {
      final subscription = await PremiumSubscriptionService.getCurrentSubscription();
      final usageStats = await PremiumSubscriptionService.getUsageStats();
      
      return {
        'subscription': subscription.toJson(),
        'usage': usageStats,
        'canUseCloudBackup': subscription.features.cloudBackup,
        'isPremium': subscription.isPremium,
      };
    } catch (e) {
      AppLogger.error('구독 정보 조회 실패: $e');
      return {
        'error': e.toString(),
        'isPremium': false,
        'canUseCloudBackup': false,
      };
    }
  }

  /// 이미지 저장 통계
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final localStats = await OptimizedImageService.getStorageStats();
      final compressionInfo = OptimizedImageService.getCompressionInfo();
      final subscriptionInfo = await getSubscriptionInfo();
      
      return {
        'local': localStats,
        'compression': compressionInfo,
        'subscription': subscriptionInfo,
        'recommendations': _getStorageRecommendations(localStats, subscriptionInfo),
      };
    } catch (e) {
      AppLogger.error('저장 통계 조회 실패: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// 저장 공간 권장사항
  static List<String> _getStorageRecommendations(
    Map<String, dynamic> localStats, 
    Map<String, dynamic> subscriptionInfo
  ) {
    final recommendations = <String>[];
    
    try {
      final totalImages = localStats['totalImages'] as int? ?? 0;
      final totalSizeMB = (localStats['totalSizeBytes'] as int? ?? 0) / (1024 * 1024);
      final isPremium = subscriptionInfo['isPremium'] as bool? ?? false;
      
      if (totalImages == 0) {
        recommendations.add('📸 첫 번째 이미지를 촬영해보세요!');
        return recommendations;
      }
      
      // 압축 효과 안내
      recommendations.add('✅ 이미지 압축으로 ${totalSizeMB.toStringAsFixed(1)}MB만 사용 중 (90% 압축)');
      
      // 이미지 개수에 따른 안내
      if (totalImages < 50) {
        recommendations.add('📊 아직 여유롭습니다 ($totalImages개 이미지)');
      } else if (totalImages < 200) {
        recommendations.add('📈 적당한 사용량입니다 ($totalImages개 이미지)');
      } else {
        recommendations.add('📊 많은 이미지를 저장 중입니다 ($totalImages개 이미지)');
      }
      
      // 프리미엄 관련 안내
      if (!isPremium) {
        recommendations.add('☁️ 프리미엄으로 업그레이드하면 클라우드 백업을 이용할 수 있습니다');
        if (totalImages > 100) {
          recommendations.add('💡 $totalImages개의 소중한 이미지를 안전하게 백업해보세요!');
        }
      } else {
        recommendations.add('✨ 프리미엄 사용자로 클라우드 백업이 활성화되어 있습니다');
        recommendations.add('🔒 이미지가 안전하게 보호되고 있습니다');
      }
      
    } catch (e) {
      recommendations.add('❌ 권장사항 생성 중 오류가 발생했습니다');
    }
    
    return recommendations;
  }

  // ===== 기존 ImageService 호환 메서드들 =====

  /// 이미지 삭제
  static Future<bool> deleteImage(String imagePath) async {
    return await OptimizedImageService.deleteImage(imagePath);
  }

  /// 이미지 존재 확인
  static Future<bool> imageExists(String imagePath) async {
    return await OptimizedImageService.imageExists(imagePath);
  }

  /// 이미지 경로 복구
  static Future<String?> fixImagePath(String oldPath) async {
    return await OptimizedImageService.fixImagePath(oldPath);
  }

  /// 권한 확인 및 요청
  static Future<bool> checkAndRequestPermissions() async {
    return await OptimizedImageService.checkAndRequestPermissions();
  }

  /// 설정 앱으로 이동
  static Future<bool> openSettings() async {
    return await OptimizedImageService.openSettings();
  }

  /// 모든 이미지 정리
  static Future<void> cleanupImages() async {
    return await OptimizedImageService.cleanupImages();
  }

  /// 이미지 크기 정보
  static Future<Size?> getImageSize(String imagePath) async {
    return await OptimizedImageService.getImageSize(imagePath);
  }
}