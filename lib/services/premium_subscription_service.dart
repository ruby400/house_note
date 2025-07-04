import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_note/core/utils/logger.dart';

/// 프리미엄 구독 관리 서비스
/// 
/// 향후 인앱 결제 시스템 연동을 위한 기반 구조 제공
/// 현재는 개발/테스트용 수동 설정 지원
class PremiumSubscriptionService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 구독 타입
  static const String subscriptionFree = 'free';
  static const String subscriptionPremium = 'premium';
  static const String subscriptionPremiumPro = 'premium_pro';
  
  // 로컬 저장 키
  static const String keySubscriptionType = 'subscription_type';
  static const String keySubscriptionExpiry = 'subscription_expiry';
  static const String keyLastSubscriptionCheck = 'last_subscription_check';

  /// 현재 사용자의 구독 상태 확인
  static Future<UserSubscription> getCurrentSubscription() async {
    try {
      // 1. 로그인 상태 확인
      final user = _auth.currentUser;
      if (user == null) {
        return UserSubscription.free();
      }

      // 2. 로컬 캐시 확인 (빠른 응답)
      final cachedSubscription = await _getCachedSubscription();
      
      // 3. 캐시가 유효하면 반환
      final isCacheValid = await _isCacheValid(cachedSubscription);
      if (isCacheValid) {
        AppLogger.d('구독 정보 캐시 사용: ${cachedSubscription.type}');
        return cachedSubscription;
      }

      // 4. Firebase에서 최신 구독 정보 조회
      final firebaseSubscription = await _getSubscriptionFromFirebase(user.uid);
      
      // 5. 로컬에 캐시 저장
      await _cacheSubscription(firebaseSubscription);
      
      AppLogger.info('구독 정보 업데이트: ${firebaseSubscription.type}');
      return firebaseSubscription;

    } catch (e) {
      AppLogger.error('구독 상태 확인 실패: $e');
      // 오류 시 안전하게 무료 계정으로 처리
      return UserSubscription.free();
    }
  }

  /// Firebase에서 구독 정보 조회
  static Future<UserSubscription> _getSubscriptionFromFirebase(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('current')
          .get();

      if (!doc.exists) {
        // 구독 정보가 없으면 무료 계정
        AppLogger.d('구독 정보 없음, 무료 계정으로 설정');
        return UserSubscription.free();
      }

      final data = doc.data()!;
      final type = data['type'] as String? ?? subscriptionFree;
      final expiryTimestamp = data['expiryDate'] as Timestamp?;
      final expiryDate = expiryTimestamp?.toDate();

      // 만료일 확인
      if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
        AppLogger.info('구독 만료됨: $expiryDate');
        return UserSubscription.free();
      }

      return UserSubscription(
        type: type,
        isActive: true,
        expiryDate: expiryDate,
        features: _getSubscriptionFeatures(type),
      );

    } catch (e) {
      AppLogger.error('Firebase 구독 조회 실패: $e');
      return UserSubscription.free();
    }
  }

  /// 로컬 캐시에서 구독 정보 조회
  static Future<UserSubscription> _getCachedSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final type = prefs.getString(keySubscriptionType) ?? subscriptionFree;
      final expiryString = prefs.getString(keySubscriptionExpiry);
      final expiryDate = expiryString != null ? DateTime.tryParse(expiryString) : null;

      // 만료일 확인
      if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
        return UserSubscription.free();
      }

      return UserSubscription(
        type: type,
        isActive: type != subscriptionFree,
        expiryDate: expiryDate,
        features: _getSubscriptionFeatures(type),
      );

    } catch (e) {
      AppLogger.error('캐시된 구독 정보 조회 실패: $e');
      return UserSubscription.free();
    }
  }

  /// 구독 정보를 로컬에 캐시
  static Future<void> _cacheSubscription(UserSubscription subscription) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(keySubscriptionType, subscription.type);
      await prefs.setString(keyLastSubscriptionCheck, DateTime.now().toIso8601String());
      
      if (subscription.expiryDate != null) {
        await prefs.setString(keySubscriptionExpiry, subscription.expiryDate!.toIso8601String());
      } else {
        await prefs.remove(keySubscriptionExpiry);
      }

    } catch (e) {
      AppLogger.error('구독 정보 캐시 실패: $e');
    }
  }

  /// 캐시 유효성 확인 (5분간 유효)
  static Future<bool> _isCacheValid(UserSubscription subscription) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckString = prefs.getString(keyLastSubscriptionCheck);
      if (lastCheckString == null) return false;
      
      final lastCheck = DateTime.tryParse(lastCheckString);
      if (lastCheck == null) return false;
      
      final now = DateTime.now();
      final cacheAge = now.difference(lastCheck);
      
      return cacheAge.inMinutes < 5; // 5분간 캐시 유효
    } catch (e) {
      return false;
    }
  }

  /// 구독별 기능 목록 반환
  static SubscriptionFeatures _getSubscriptionFeatures(String subscriptionType) {
    switch (subscriptionType) {
      case subscriptionPremium:
        return SubscriptionFeatures(
          cloudBackup: true,
          unlimitedImages: true,
          prioritySupport: true,
          advancedFeatures: false,
          maxCloudStorageGB: 50,
          maxChartsCount: 100,
        );
      
      case subscriptionPremiumPro:
        return SubscriptionFeatures(
          cloudBackup: true,
          unlimitedImages: true,
          prioritySupport: true,
          advancedFeatures: true,
          maxCloudStorageGB: 500,
          maxChartsCount: -1, // 무제한
        );
      
      default: // free
        return SubscriptionFeatures(
          cloudBackup: false,
          unlimitedImages: false,
          prioritySupport: false,
          advancedFeatures: false,
          maxCloudStorageGB: 0,
          maxChartsCount: 10,
        );
    }
  }

  /// 프리미엄 사용자인지 확인
  static Future<bool> isPremiumUser() async {
    final subscription = await getCurrentSubscription();
    return subscription.isPremium;
  }

  /// 클라우드 백업 사용 가능한지 확인
  static Future<bool> canUseCloudBackup() async {
    final subscription = await getCurrentSubscription();
    return subscription.features.cloudBackup;
  }

  /// 특정 기능 사용 가능한지 확인
  static Future<bool> hasFeature(String featureName) async {
    final subscription = await getCurrentSubscription();
    
    switch (featureName) {
      case 'cloud_backup':
        return subscription.features.cloudBackup;
      case 'unlimited_images':
        return subscription.features.unlimitedImages;
      case 'priority_support':
        return subscription.features.prioritySupport;
      case 'advanced_features':
        return subscription.features.advancedFeatures;
      default:
        return false;
    }
  }

  /// 구독 업그레이드 (개발/테스트용)
  static Future<bool> upgradeSubscription({
    required String subscriptionType,
    DateTime? expiryDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.warning('로그인이 필요합니다');
        return false;
      }

      // Firebase에 구독 정보 저장
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('subscription')
          .doc('current')
          .set({
        'type': subscriptionType,
        'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
        'upgradedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      // 로컬 캐시 업데이트
      final newSubscription = UserSubscription(
        type: subscriptionType,
        isActive: true,
        expiryDate: expiryDate,
        features: _getSubscriptionFeatures(subscriptionType),
      );
      
      await _cacheSubscription(newSubscription);

      AppLogger.info('구독 업그레이드 완료: $subscriptionType');
      return true;

    } catch (e) {
      AppLogger.error('구독 업그레이드 실패: $e');
      return false;
    }
  }

  /// 구독 취소 (개발/테스트용)
  static Future<bool> cancelSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // Firebase에서 구독 상태 업데이트
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('subscription')
          .doc('current')
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // 로컬 캐시를 무료 계정으로 변경
      await _cacheSubscription(UserSubscription.free());

      AppLogger.info('구독 취소 완료');
      return true;

    } catch (e) {
      AppLogger.error('구독 취소 실패: $e');
      return false;
    }
  }

  /// 구독 갱신
  static Future<void> refreshSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final subscription = await _getSubscriptionFromFirebase(user.uid);
      await _cacheSubscription(subscription);
      
      AppLogger.info('구독 정보 갱신 완료');
    } catch (e) {
      AppLogger.error('구독 정보 갱신 실패: $e');
    }
  }

  /// 사용 통계 확인 (차트 개수, 이미지 개수 등)
  static Future<Map<String, dynamic>> getUsageStats() async {
    try {
      final subscription = await getCurrentSubscription();
      
      // 실제 구현에서는 차트 개수, 이미지 개수 등을 실제로 계산
      // 여기서는 예시 데이터 반환
      return {
        'subscription': subscription.toJson(),
        'usage': {
          'chartsCount': 5,
          'imagesCount': 150,
          'cloudStorageUsedMB': subscription.features.cloudBackup ? 250 : 0,
        },
        'limits': {
          'maxCharts': subscription.features.maxChartsCount,
          'maxCloudStorageGB': subscription.features.maxCloudStorageGB,
          'unlimitedImages': subscription.features.unlimitedImages,
        },
      };
    } catch (e) {
      AppLogger.error('사용 통계 조회 실패: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// 구독 만료 알림이 필요한지 확인
  static Future<bool> shouldShowExpiryNotification() async {
    try {
      final subscription = await getCurrentSubscription();
      
      if (!subscription.isPremium || subscription.expiryDate == null) {
        return false;
      }

      final daysUntilExpiry = subscription.expiryDate!.difference(DateTime.now()).inDays;
      
      // 만료 7일 전부터 알림
      return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
      
    } catch (e) {
      AppLogger.error('만료 알림 확인 실패: $e');
      return false;
    }
  }

  /// 프리미엄 기능 사용 시도 시 권한 확인 및 업그레이드 안내
  static Future<PremiumAccessResult> checkPremiumAccess(String featureName) async {
    try {
      final hasAccess = await hasFeature(featureName);
      
      if (hasAccess) {
        return PremiumAccessResult.allowed();
      } else {
        final subscription = await getCurrentSubscription();
        return PremiumAccessResult.denied(
          currentPlan: subscription.type,
          requiredFeature: featureName,
        );
      }
      
    } catch (e) {
      AppLogger.error('프리미엄 접근 확인 실패: $e');
      return PremiumAccessResult.denied(
        currentPlan: subscriptionFree,
        requiredFeature: featureName,
      );
    }
  }
}

/// 사용자 구독 정보
class UserSubscription {
  final String type;
  final bool isActive;
  final DateTime? expiryDate;
  final SubscriptionFeatures features;

  const UserSubscription({
    required this.type,
    required this.isActive,
    this.expiryDate,
    required this.features,
  });

  factory UserSubscription.free() {
    return UserSubscription(
      type: PremiumSubscriptionService.subscriptionFree,
      isActive: false,
      expiryDate: null,
      features: PremiumSubscriptionService._getSubscriptionFeatures(
        PremiumSubscriptionService.subscriptionFree,
      ),
    );
  }

  bool get isPremium => type != PremiumSubscriptionService.subscriptionFree && isActive;
  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
  
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'isActive': isActive,
      'isPremium': isPremium,
      'expiryDate': expiryDate?.toIso8601String(),
      'daysUntilExpiry': daysUntilExpiry,
      'features': features.toJson(),
    };
  }

  @override
  String toString() => 'UserSubscription(type: $type, isActive: $isActive, isPremium: $isPremium)';
}

/// 구독별 기능 목록
class SubscriptionFeatures {
  final bool cloudBackup;
  final bool unlimitedImages;
  final bool prioritySupport;
  final bool advancedFeatures;
  final int maxCloudStorageGB;
  final int maxChartsCount; // -1은 무제한

  const SubscriptionFeatures({
    required this.cloudBackup,
    required this.unlimitedImages,
    required this.prioritySupport,
    required this.advancedFeatures,
    required this.maxCloudStorageGB,
    required this.maxChartsCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'cloudBackup': cloudBackup,
      'unlimitedImages': unlimitedImages,
      'prioritySupport': prioritySupport,
      'advancedFeatures': advancedFeatures,
      'maxCloudStorageGB': maxCloudStorageGB,
      'maxChartsCount': maxChartsCount,
    };
  }
}

/// 프리미엄 접근 결과
class PremiumAccessResult {
  final bool isAllowed;
  final String currentPlan;
  final String? requiredFeature;
  final String? upgradeMessage;

  const PremiumAccessResult({
    required this.isAllowed,
    required this.currentPlan,
    this.requiredFeature,
    this.upgradeMessage,
  });

  factory PremiumAccessResult.allowed() {
    return const PremiumAccessResult(
      isAllowed: true,
      currentPlan: '',
    );
  }

  factory PremiumAccessResult.denied({
    required String currentPlan,
    required String requiredFeature,
  }) {
    String message;
    switch (requiredFeature) {
      case 'cloud_backup':
        message = '클라우드 백업은 프리미엄 사용자만 이용할 수 있습니다.\n안전한 이미지 백업을 위해 프리미엄으로 업그레이드하세요!';
        break;
      case 'unlimited_images':
        message = '무제한 이미지 저장은 프리미엄 기능입니다.\n프리미엄으로 업그레이드하면 원하는 만큼 이미지를 저장할 수 있습니다!';
        break;
      case 'advanced_features':
        message = '고급 기능은 프리미엄 프로 사용자만 이용할 수 있습니다.\n더 많은 기능을 위해 업그레이드하세요!';
        break;
      default:
        message = '이 기능은 프리미엄 사용자만 이용할 수 있습니다.\n업그레이드하여 모든 기능을 사용해보세요!';
    }

    return PremiumAccessResult(
      isAllowed: false,
      currentPlan: currentPlan,
      requiredFeature: requiredFeature,
      upgradeMessage: message,
    );
  }
}