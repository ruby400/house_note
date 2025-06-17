import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/data/repositories/user_repository.dart';
import 'package:house_note/services/firebase_auth_service.dart';

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

  AuthViewModel(this._authService, this._userRepository)
      : super(AuthState(user: _authService.currentUser)) {
    // 초기 사용자 상태 설정
    _authService.authStateChanges.listen((user) {
      state = state.copyWith(user: user, isLoading: false);
    });
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
    } else {
      // 디버깅을 위해 실제 오류 메시지도 포함
      return '로그인 중 오류가 발생했습니다.\n오류: $errorMessage';
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userCredential =
          await _authService.signInWithEmailAndPassword(email, password);
      state = state.copyWith(isLoading: false, user: userCredential?.user);
      return userCredential != null;
    } catch (e) {
      final errorMessage = _getKoreanErrorMessage(e.toString());
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userCredential =
          await _authService.createUserWithEmailAndPassword(email, password);
      
      if (userCredential != null && userCredential.user != null) {
        // Firestore에 사용자 프로필 생성
        await _userRepository.createUserProfile(userCredential.user!);
        state = state.copyWith(isLoading: false, user: userCredential.user);
        return true;
      }
      
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
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
}
