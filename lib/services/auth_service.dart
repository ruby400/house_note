import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 현재 사용자 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 현재 사용자
  User? get currentUser => _auth.currentUser;

  // 로그인 상태 확인
  bool get isSignedIn => _auth.currentUser != null;

  // 이메일로 회원가입
  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      AppLogger.info('이메일 회원가입 시도: $email');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 사용자 프로필 업데이트
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();

      AppLogger.info('이메일 회원가입 성공: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('이메일 회원가입 실패', error: e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('회원가입 중 예기치 못한 오류', error: e);
      throw '회원가입 중 오류가 발생했습니다.';
    }
  }

  // 이메일로 로그인
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('이메일 로그인 시도: $email');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      AppLogger.info('이메일 로그인 성공: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('이메일 로그인 실패', error: e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('로그인 중 예기치 못한 오류', error: e);
      throw '로그인 중 오류가 발생했습니다.';
    }
  }

  // 구글 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      AppLogger.info('구글 로그인 시도');
      
      // 구글 로그인 트리거
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        AppLogger.info('구글 로그인 취소됨');
        return null;
      }

      // 구글 인증 정보 얻기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase 자격 증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase로 로그인
      final userCredential = await _auth.signInWithCredential(credential);
      
      AppLogger.info('구글 로그인 성공: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('구글 로그인 실패', error: e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('구글 로그인 중 예기치 못한 오류', error: e);
      throw '구글 로그인 중 오류가 발생했습니다.';
    }
  }

  // 비밀번호 재설정
  Future<void> resetPassword(String email) async {
    try {
      AppLogger.info('비밀번호 재설정 이메일 전송: $email');
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger.info('비밀번호 재설정 이메일 전송 완료');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('비밀번호 재설정 실패', error: e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('비밀번호 재설정 중 오류', error: e);
      throw '비밀번호 재설정 중 오류가 발생했습니다.';
    }
  }

  // 비밀번호 변경
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw '로그인된 사용자가 없습니다.';

      AppLogger.info('비밀번호 업데이트 시도');
      await user.updatePassword(newPassword);
      AppLogger.info('비밀번호 업데이트 완료');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('비밀번호 업데이트 실패', error: e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('비밀번호 업데이트 중 오류', error: e);
      throw '비밀번호 변경 중 오류가 발생했습니다.';
    }
  }

  // 프로필 업데이트
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw '로그인된 사용자가 없습니다.';

      AppLogger.info('프로필 업데이트 시도');
      
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      
      await user.reload();
      AppLogger.info('프로필 업데이트 완료');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('프로필 업데이트 실패', error: e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('프로필 업데이트 중 오류', error: e);
      throw '프로필 업데이트 중 오류가 발생했습니다.';
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      AppLogger.info('로그아웃 시도');
      
      // 구글 로그인 상태 확인 후 로그아웃
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      await _auth.signOut();
      AppLogger.info('로그아웃 완료');
    } catch (e) {
      AppLogger.error('로그아웃 중 오류', error: e);
      throw '로그아웃 중 오류가 발생했습니다.';
    }
  }

  // 계정 삭제
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw '로그인된 사용자가 없습니다.';

      AppLogger.info('계정 삭제 시도');
      await user.delete();
      AppLogger.info('계정 삭제 완료');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('계정 삭제 실패', error: e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('계정 삭제 중 오류', error: e);
      throw '계정 삭제 중 오류가 발생했습니다.';
    }
  }

  // Firebase Auth 예외 처리
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return '비밀번호가 너무 약합니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'user-not-found':
        return '등록되지 않은 이메일입니다.';
      case 'wrong-password':
        return '잘못된 비밀번호입니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'too-many-requests':
        return '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
      case 'operation-not-allowed':
        return '현재 사용할 수 없는 로그인 방법입니다.';
      case 'requires-recent-login':
        return '보안을 위해 다시 로그인해주세요.';
      default:
        return e.message ?? '인증 중 오류가 발생했습니다.';
    }
  }
}

// Riverpod Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// 현재 사용자 Provider
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// 로그인 상태 Provider
final isSignedInProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isSignedIn;
});