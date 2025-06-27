import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:house_note/core/utils/logger.dart';
import 'package:house_note/services/naver_auth_service.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService(this._firebaseAuth, this._googleSignIn);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      AppLogger.info('🔐 로그인 시도: $email');
      final result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      AppLogger.info('✅ 로그인 성공: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Firebase Auth 오류: ${e.code}', error: e);
      // Firebase 오류 코드를 포함하여 던지기
      throw Exception('${e.code}: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ 로그인 일반 오류', error: e);
      throw Exception('로그인 중 예상치 못한 오류: $e');
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      AppLogger.info('📝 회원가입 시도: $email');
      final result = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      AppLogger.info('✅ 회원가입 성공: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Firebase Auth 오류 (회원가입): ${e.code}', error: e);
      throw Exception('${e.code}: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ 회원가입 일반 오류', error: e);
      throw Exception('회원가입 중 예상치 못한 오류: $e');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 사용자가 구글 로그인을 취소한 경우
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception('${e.code}: ${e.message}');
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  /// 네이버 로그인
  Future<UserCredential?> signInWithNaver() async {
    try {
      AppLogger.info('🟢 네이버 로그인 시도');
      final result = await NaverAuthService.signInWithNaverToFirebase();
      
      if (result != null) {
        AppLogger.info('✅ 네이버 로그인 성공: ${result.user?.email}');
        return result;
      } else {
        AppLogger.warning('⚠️ 네이버 로그인 취소 또는 실패');
        return null;
      }
    } catch (e) {
      AppLogger.error('❌ 네이버 로그인 오류', error: e);
      throw Exception('네이버 로그인 중 오류: $e');
    }
  }

  Future<void> signOut() async {
    try {
      AppLogger.info('🚪 로그아웃 시도');
      
      // 모든 로그인 방식에서 로그아웃
      await _googleSignIn.signOut();
      await NaverAuthService.signOut();
      await _firebaseAuth.signOut();
      
      AppLogger.info('✅ 로그아웃 성공');
    } catch (e) {
      AppLogger.error('❌ 로그아웃 오류', error: e);
      throw Exception('로그아웃 중 오류: $e');
    }
  }

  // 프로필 업데이트
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // 이메일 업데이트
  Future<void> updateEmail(String email) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }
      await user.verifyBeforeUpdateEmail(email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // 비밀번호 업데이트
  Future<void> updatePassword(String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }
      await user.updatePassword(password);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // 계정 삭제
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }
}
