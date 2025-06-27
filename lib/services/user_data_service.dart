import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';
import '../data/models/property_chart_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

/// 사용자 데이터 통합 관리 서비스
/// 로그인/로그아웃 시 자동으로 데이터 동기화 처리
class UserDataService {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  UserDataService(this._authService, this._firestoreService);

  // === 사용자 인증 및 프로필 관리 ===

  /// 회원가입 및 프로필 생성
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      AppLogger.info('회원가입 및 프로필 생성 시작');
      
      // 1. Firebase Auth로 회원가입
      final credential = await _authService.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      final user = credential?.user;
      if (user == null) throw '회원가입에 실패했습니다.';

      // 2. Firestore에 사용자 프로필 생성
      await _firestoreService.createOrUpdateUserProfile(
        userId: user.uid,
        email: email,
        displayName: displayName,
        photoURL: user.photoURL,
        additionalData: {
          'registrationMethod': 'email',
          'version': '1.0.0',
        },
      );

      // 3. 오프라인 지원 활성화
      _firestoreService.enableOfflineSupport();

      AppLogger.info('회원가입 및 프로필 생성 완료');
      return user;
    } catch (e) {
      AppLogger.error('회원가입 및 프로필 생성 실패', error: e);
      rethrow;
    }
  }

  /// 이메일 로그인 및 데이터 동기화
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('이메일 로그인 및 데이터 동기화 시작');
      
      // 1. Firebase Auth로 로그인
      final credential = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      final user = credential?.user;
      if (user == null) throw '로그인에 실패했습니다.';

      // 2. 사용자 프로필 업데이트 (마지막 로그인 시간 등)
      await _firestoreService.createOrUpdateUserProfile(
        userId: user.uid,
        email: email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        additionalData: {
          'lastLoginMethod': 'email',
        },
      );

      // 3. 오프라인 지원 활성화
      _firestoreService.enableOfflineSupport();

      AppLogger.info('이메일 로그인 및 데이터 동기화 완료');
      return user;
    } catch (e) {
      AppLogger.error('이메일 로그인 실패', error: e);
      rethrow;
    }
  }

  /// 구글 로그인 및 데이터 동기화
  Future<User?> signInWithGoogle() async {
    try {
      AppLogger.info('구글 로그인 및 데이터 동기화 시작');
      
      // 1. Firebase Auth로 구글 로그인
      final credential = await _authService.signInWithGoogle();
      
      final user = credential?.user;
      if (user == null) return null; // 사용자가 취소한 경우

      // 2. 사용자 프로필 생성/업데이트
      await _firestoreService.createOrUpdateUserProfile(
        userId: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoURL: user.photoURL,
        additionalData: {
          'registrationMethod': 'google',
          'lastLoginMethod': 'google',
          'version': '1.0.0',
        },
      );

      // 3. 오프라인 지원 활성화
      _firestoreService.enableOfflineSupport();

      AppLogger.info('구글 로그인 및 데이터 동기화 완료');
      return user;
    } catch (e) {
      AppLogger.error('구글 로그인 실패', error: e);
      rethrow;
    }
  }

  /// 로그아웃 및 로컬 캐시 정리
  Future<void> signOut() async {
    try {
      AppLogger.info('로그아웃 및 로컬 캐시 정리 시작');
      
      // 1. Firebase Auth 로그아웃
      await _authService.signOut();
      
      // 2. 추가적인 로컬 데이터 정리가 필요한 경우 여기에 추가
      // 예: 로컬 캐시, 임시 파일 등
      
      AppLogger.info('로그아웃 완료');
    } catch (e) {
      AppLogger.error('로그아웃 실패', error: e);
      rethrow;
    }
  }

  // === 데이터 마이그레이션 ===

  /// 로컬 데이터를 Firebase로 마이그레이션
  Future<void> migrateLocalDataToFirebase(List<PropertyChartModel> localCharts) async {
    try {
      if (_authService.currentUser == null) {
        throw '로그인이 필요합니다.';
      }

      AppLogger.info('로컬 데이터 마이그레이션 시작: ${localCharts.length}개 차트');

      // 1. Firestore로 데이터 마이그레이션
      await _firestoreService.migrateLocalData(localCharts);

      // 2. 사용자 통계 업데이트
      await _firestoreService.updateUserStats();

      AppLogger.info('로컬 데이터 마이그레이션 완료');
    } catch (e) {
      AppLogger.error('로컬 데이터 마이그레이션 실패', error: e);
      rethrow;
    }
  }

  // === 차트 관리 (Firebase 통합) ===

  /// 차트 저장 (자동으로 Firebase에 저장)
  Future<String> saveChart(PropertyChartModel chart) async {
    try {
      if (_authService.currentUser == null) {
        throw '로그인이 필요합니다.';
      }

      final chartId = await _firestoreService.saveChart(chart);
      
      // 통계 업데이트 (백그라운드에서 실행)
      _firestoreService.updateUserStats().catchError((e) {
        AppLogger.error('통계 업데이트 실패', error: e);
      });

      return chartId;
    } catch (e) {
      AppLogger.error('차트 저장 실패', error: e);
      rethrow;
    }
  }

  /// 차트 삭제 (자동으로 Firebase에서 삭제)
  Future<void> deleteChart(String chartId) async {
    try {
      if (_authService.currentUser == null) {
        throw '로그인이 필요합니다.';
      }

      await _firestoreService.deleteChart(chartId);
      
      // 통계 업데이트 (백그라운드에서 실행)
      _firestoreService.updateUserStats().catchError((e) {
        AppLogger.error('통계 업데이트 실패', error: e);
      });
    } catch (e) {
      AppLogger.error('차트 삭제 실패', error: e);
      rethrow;
    }
  }

  // === 네트워크 상태 및 동기화 ===

  /// 네트워크 연결 상태 확인
  Future<bool> isConnectedToFirebase() async {
    return await _firestoreService.isConnected();
  }

  /// 강제 동기화 (수동으로 데이터 동기화)
  Future<void> forceSyncData() async {
    try {
      if (_authService.currentUser == null) {
        throw '로그인이 필요합니다.';
      }

      AppLogger.info('강제 데이터 동기화 시작');
      
      // Firestore 네트워크 재연결
      await FirebaseFirestore.instance.enableNetwork();
      
      // 사용자 통계 업데이트
      await _firestoreService.updateUserStats();

      AppLogger.info('강제 데이터 동기화 완료');
    } catch (e) {
      AppLogger.error('강제 데이터 동기화 실패', error: e);
      rethrow;
    }
  }

  // === 계정 관리 ===

  /// 계정 완전 삭제 (모든 데이터 삭제)
  Future<void> deleteAccountCompletely() async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw '로그인이 필요합니다.';

      AppLogger.info('계정 완전 삭제 시작');

      // 1. Firestore에서 모든 사용자 데이터 삭제
      await _firestoreService.deleteAllUserData(user.uid);

      // 2. Firebase Auth에서 계정 삭제
      await _authService.deleteAccount();

      AppLogger.info('계정 완전 삭제 완료');
    } catch (e) {
      AppLogger.error('계정 삭제 실패', error: e);
      rethrow;
    }
  }

  // === 유틸리티 ===

  /// 현재 사용자 정보
  User? get currentUser => _authService.currentUser;

  /// 로그인 상태
  bool get isSignedIn => _authService.isSignedIn;

  /// 인증 상태 변화 스트림
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  /// 사용자 차트 목록 스트림
  Stream<List<PropertyChartModel>> get userChartsStream => _firestoreService.getUserCharts();
}

// Riverpod Providers
final userDataServiceProvider = Provider<UserDataService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return UserDataService(authService, firestoreService);
});

// 인증 상태 Provider
final authStateProvider = StreamProvider<User?>((ref) {
  final userDataService = ref.watch(userDataServiceProvider);
  return userDataService.authStateChanges;
});

// 로그인 상태 Provider
final isSignedInProvider = Provider<bool>((ref) {
  final userDataService = ref.watch(userDataServiceProvider);
  return userDataService.isSignedIn;
});

// 통합 차트 목록 Provider (Firebase에서 실시간으로 가져옴)
final firebaseChartsProvider = StreamProvider<List<PropertyChartModel>>((ref) {
  final userDataService = ref.watch(userDataServiceProvider);
  return userDataService.userChartsStream;
});