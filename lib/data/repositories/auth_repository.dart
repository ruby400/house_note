import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/services/firebase_auth_service.dart';
import 'package:house_note/providers/auth_providers.dart';

// AuthRepository를 제공하는 Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // FirebaseAuthService를 주입받아 AuthRepository 인스턴스를 생성
  return AuthRepository(ref.watch(firebaseAuthServiceProvider));
});

class AuthRepository {
  final FirebaseAuthService _authService;

  AuthRepository(this._authService);

  // 인증 상태 변경 스트림 가져오기
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  // 현재 사용자 정보 가져오기
  User? get currentUser => _authService.currentUser;

  // 이메일/비밀번호로 로그인
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) {
    // Repository에서는 단순히 Service의 메서드를 호출하고 결과를 반환합니다.
    // 만약 여기서 추가적인 데이터 가공이 필요하다면 이 부분에 로직을 추가할 수 있습니다.
    return _authService.signInWithEmailAndPassword(email, password);
  }

  // 이메일/비밀번호로 회원가입
  Future<UserCredential?> createUserWithEmailAndPassword(
      String email, String password) {
    return _authService.createUserWithEmailAndPassword(email, password);
  }

  // 구글로 로그인
  Future<UserCredential?> signInWithGoogle() {
    return _authService.signInWithGoogle();
  }

  // 로그아웃
  Future<void> signOut() {
    return _authService.signOut();
  }

  // 프로필 업데이트
  Future<void> updateProfile({String? displayName, String? photoURL}) {
    return _authService.updateProfile(displayName: displayName, photoURL: photoURL);
  }

  // 이메일 업데이트
  Future<void> updateEmail(String email) {
    return _authService.updateEmail(email);
  }

  // 비밀번호 업데이트
  Future<void> updatePassword(String password) {
    return _authService.updatePassword(password);
  }

  // 계정 삭제
  Future<void> deleteAccount() {
    return _authService.deleteAccount();
  }
}
