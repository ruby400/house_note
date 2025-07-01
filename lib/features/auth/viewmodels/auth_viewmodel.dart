import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/data/repositories/user_repository.dart';
import 'package:house_note/services/firebase_auth_service.dart';
import 'package:house_note/providers/firebase_chart_providers.dart';
import 'package:house_note/providers/property_chart_providers.dart';
import 'package:house_note/features/main_navigation/views/main_navigation_screen.dart';
import 'package:house_note/core/utils/logger.dart';

// 상태 정의
class AuthState {
  final bool isLoading;
  final String? error;
  final User? user; // 현재 로그인된 사용자 정보

  AuthState({this.isLoading = false, this.error, this.user});

  AuthState copyWith(
      {bool? isLoading, String? error, User? user, bool clearError = false}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      user: user ?? this.user,
    );
  }
}

// ViewModel
class AuthViewModel extends StateNotifier<AuthState> {
  final FirebaseAuthService _authService;
  final UserRepository _userRepository;
  final Ref _ref;
  
  // 회원가입 과정 중인지 추적하는 플래그
  bool _isSigningUp = false;

  AuthViewModel(this._authService, this._userRepository, this._ref)
      : super(AuthState(user: _authService.currentUser)) {
    // 초기 사용자 상태 설정
    _authService.authStateChanges.listen((user) {
      debugPrint('🔄 Auth state changed: ${user?.uid}, isSigningUp: $_isSigningUp');
      state = state.copyWith(user: user, isLoading: false);
      
      // 사용자 변경 시 로컬 차트 데이터 다시 로드
      _ref.read(propertyChartListProvider.notifier).reloadChartsForCurrentUser();
      
      // 로그인 시 데이터 동기화 및 하단바 상태 초기화 (회원가입 중이 아닐 때만)
      if (user != null && !_isSigningUp) {
        debugPrint('🔄 Syncing data after login');
        _syncDataAfterLogin();
        // 하단바를 카드목록 탭(0번)으로 초기화
        _ref.read(selectedPageIndexProvider.notifier).state = 0;
      }
    });
  }

  /// 로그인 후 자동 데이터 동기화
  Future<void> _syncDataAfterLogin() async {
    try {
      AppLogger.info('로그인 감지 - 데이터 동기화 시작');
      final chartService = _ref.read(integratedChartServiceProvider);
      final result = await chartService.syncDataAfterLogin();
      
      if (result != null) {
        AppLogger.info('데이터 동기화 완료: ${result.summary}');
      } else {
        AppLogger.info('동기화할 데이터 없음');
      }
    } catch (e) {
      AppLogger.error('로그인 후 데이터 동기화 실패', error: e);
    }
  }

  // Firebase Auth 오류를 한국어로 변환하는 함수
  String _getKoreanErrorMessage(String errorMessage) {
    // Firebase 오류 코드 기반 처리
    if (errorMessage.contains('email-already-in-use')) {
      return '이미 사용 중인 이메일입니다. 다른 이메일을 사용하거나 로그인해주세요.';
    } else if (errorMessage.contains('weak-password')) {
      return '비밀번호가 너무 약합니다. 더 강한 비밀번호를 사용해주세요.';
    } else if (errorMessage.contains('invalid-email')) {
      return '유효하지 않은 이메일 주소입니다.';
    } else if (errorMessage.contains('user-not-found')) {
      return '등록되지 않은 이메일입니다. 회원가입을 먼저 진행해주세요.';
    } else if (errorMessage.contains('wrong-password')) {
      return '잘못된 비밀번호입니다. 다시 확인해주세요.';
    } else if (errorMessage.contains('invalid-credential')) {
      return '잘못된 이메일 또는 비밀번호입니다.\n아직 회원가입을 하지 않으셨다면 회원가입을 먼저 진행해주세요.';
    } else if (errorMessage.contains('user-disabled')) {
      return '비활성화된 계정입니다. 관리자에게 문의해주세요.';
    } else if (errorMessage.contains('too-many-requests')) {
      return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
    } else if (errorMessage.contains('operation-not-allowed')) {
      return '현재 사용할 수 없는 로그인 방법입니다.';
    } else if (errorMessage.contains('network-request-failed')) {
      return '네트워크 연결을 확인해주세요.';
    } else if (errorMessage.contains('requires-recent-login')) {
      return '보안을 위해 다시 로그인이 필요합니다.';
    } else if (errorMessage.contains('account-exists-with-different-credential')) {
      return '다른 로그인 방법으로 이미 가입된 계정입니다.';
    } else if (errorMessage.contains('popup-closed-by-user')) {
      return '로그인이 취소되었습니다.';
    } else if (errorMessage.contains('Apple 로그인 인증 오류') && errorMessage.contains('canceled')) {
      return ''; // Apple 로그인 취소는 오류로 처리하지 않음 (빈 문자열 반환)
    } else if (errorMessage.contains('Authorization was canceled') || errorMessage.contains('canceled')) {
      return ''; // 사용자가 취소한 경우는 오류로 처리하지 않음 (빈 문자열 반환)
    } else if (errorMessage.contains('user-not-found')) {
      return '등록되지 않은 이메일입니다.';
    } else if (errorMessage.contains('invalid-email')) {
      return '유효하지 않은 이메일 주소입니다.';
    } else if (errorMessage.contains('missing-email')) {
      return '이메일 주소를 입력해주세요.';
    } else {
      // 디버깅을 위해 실제 오류 메시지도 포함
      return '오류가 발생했습니다.\n오류: $errorMessage';
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🔐 로그인 시도: $email');
      final userCredential =
          await _authService.signInWithEmailAndPassword(email, password);
      debugPrint('🔐 로그인 결과: ${userCredential?.user?.uid}');
      state = state.copyWith(isLoading: false, user: userCredential?.user);
      return userCredential != null;
    } catch (e) {
      debugPrint('🔐 로그인 에러: $e');
      final errorMessage = _getKoreanErrorMessage(e.toString());
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, {String? nickname}) async {
    debugPrint('📝 회원가입 시작: $email');
    state = state.copyWith(isLoading: true, clearError: true);
    _isSigningUp = true; // 회원가입 과정 시작
    
    try {
      final userCredential =
          await _authService.createUserWithEmailAndPassword(email, password);
      
      if (userCredential != null && userCredential.user != null) {
        debugPrint('📝 Firebase 계정 생성 완료: ${userCredential.user!.uid}');
        
        // Firestore에 사용자 프로필 생성 (닉네임 포함)
        await _userRepository.createUserProfile(userCredential.user!, nickname: nickname);
        debugPrint('📝 Firestore 프로필 생성 완료');
        
        // 회원가입 후 자동 로그인하지 않고 로그아웃 처리
        debugPrint('📝 회원가입 후 자동 로그아웃 처리');
        await _authService.signOut();
        
        // 로그아웃이 완전히 처리될 때까지 잠시 기다림
        await Future.delayed(const Duration(milliseconds: 100));
        
        // 상태를 명시적으로 초기화 (로그아웃 상태로)
        state = AuthState(isLoading: false, user: null);
        _isSigningUp = false; // 회원가입 과정 완료
        debugPrint('📝 회원가입 과정 완료 - 로그아웃 상태로 설정');
        return true;
      }
      
      _isSigningUp = false; // 회원가입 과정 완료
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      _isSigningUp = false; // 회원가입 과정 완료 (에러 발생 시에도)
      final errorMessage = _getKoreanErrorMessage(e.toString());
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential == null) {
        // 사용자가 구글 로그인 취소
        state = state.copyWith(isLoading: false);
        return false;
      }
      
      // 신규 유저인지 확인
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser && userCredential.user != null) {
        // 신규 유저면 Firestore에 프로필 생성
        await _userRepository.createUserProfile(userCredential.user!);
      }
      
      state = state.copyWith(isLoading: false, user: userCredential.user);
      return true;
    } catch (e) {
      final errorMessage = _getKoreanErrorMessage(e.toString());
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> signInWithNaver() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userCredential = await _authService.signInWithNaver();
      if (userCredential == null) {
        // 사용자가 네이버 로그인 취소
        state = state.copyWith(isLoading: false);
        return false;
      }
      
      // 신규 유저인지 확인
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser && userCredential.user != null) {
        // 신규 유저면 Firestore에 프로필 생성
        await _userRepository.createUserProfile(userCredential.user!);
      }
      
      state = state.copyWith(isLoading: false, user: userCredential.user);
      return true;
    } catch (e) {
      final errorMessage = _getKoreanErrorMessage(e.toString());
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userCredential = await _authService.signInWithApple();
      if (userCredential == null) {
        // 사용자가 Apple 로그인 취소
        state = state.copyWith(isLoading: false);
        return false;
      }
      
      // 신규 유저인지 확인
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser && userCredential.user != null) {
        // 신규 유저면 Firestore에 프로필 생성
        await _userRepository.createUserProfile(userCredential.user!);
      }
      
      state = state.copyWith(isLoading: false, user: userCredential.user);
      return true;
    } catch (e) {
      final errorMessage = _getKoreanErrorMessage(e.toString());
      // 취소된 경우(빈 문자열)는 오류로 처리하지 않음
      if (errorMessage.isNotEmpty) {
        state = state.copyWith(isLoading: false, error: errorMessage);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.signOut();
      state = AuthState(isLoading: false, user: null); // 로그아웃 시 초기 상태로
    } catch (e) {
      final errorMessage = _getKoreanErrorMessage(e.toString());
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final errorMessage = _getKoreanErrorMessage(e.toString());
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }
}
