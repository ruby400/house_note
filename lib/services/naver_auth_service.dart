import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/logger.dart';

/// 네이버 로그인 서비스
class NaverAuthService {
  // 네이버 개발자센터에서 발급받은 정보로 교체 필요
  // 실제 운영시에는 네이버 개발자 센터에서 발급받은 실제 값으로 교체하세요
  // static const String _clientId = 'TEST_CLIENT_ID'; 
  // static const String _clientSecret = 'TEST_CLIENT_SECRET';
  // static const String _clientName = 'HouseNote';

  /// 네이버 로그인 초기화
  static Future<void> initialize() async {
    try {
      await FlutterNaverLogin.logOut();
      AppLogger.info('네이버 로그인 초기화 완료');
    } catch (e) {
      AppLogger.error('네이버 로그인 초기화 실패', error: e);
    }
  }

  /// 네이버 로그인 수행
  static Future<dynamic> signInWithNaver() async {
    try {
      AppLogger.info('네이버 로그인 시작');
      
      final NaverLoginResult result = await FlutterNaverLogin.logIn();
      
      if (result.status == NaverLoginStatus.loggedIn) {
        AppLogger.info('네이버 로그인 성공: ${result.account?.email}');
        return result.account; // NaverAccountResult 반환
      } else {
        AppLogger.warning('네이버 로그인 실패: ${result.status}');
        return null;
      }
    } catch (e) {
      AppLogger.error('네이버 로그인 오류', error: e);
      return null;
    }
  }

  /// 네이버 로그인으로 Firebase 인증
  static Future<UserCredential?> signInWithNaverToFirebase() async {
    try {
      final naverAccount = await signInWithNaver();
      if (naverAccount == null) {
        return null;
      }
      
      final email = naverAccount.email;
      final displayName = naverAccount.name;
      
      // 이메일이 없는 경우 처리
      if (email == null || email.isEmpty) {
        throw '네이버 계정에서 이메일 정보를 가져올 수 없습니다.';
      }
      
      // 임시 비밀번호로 Firebase 계정 생성/로그인
      // 실제 운영 환경에서는 서버에서 Custom Token을 생성하는 것이 보안상 안전합니다.
      final tempPassword = 'naver_${email.hashCode}';
      
      try {
        // 기존 계정으로 로그인 시도
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: tempPassword,
        );
        
        AppLogger.info('네이버 Firebase 로그인 성공: $email');
        return credential;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // 계정이 없으면 새로 생성
          final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: tempPassword,
          );
          
          // 프로필 정보 업데이트
          await credential.user?.updateDisplayName(displayName);
          
          AppLogger.info('네이버 Firebase 계정 생성 성공: $email');
          return credential;
        } else {
          rethrow;
        }
      }
    } catch (e) {
      AppLogger.error('네이버 Firebase 인증 실패', error: e);
      return null;
    }
  }

  /// 네이버 로그아웃
  static Future<void> signOut() async {
    try {
      await FlutterNaverLogin.logOut();
      AppLogger.info('네이버 로그아웃 완료');
    } catch (e) {
      AppLogger.error('네이버 로그아웃 실패', error: e);
    }
  }

  /// 현재 네이버 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    try {
      final result = await FlutterNaverLogin.getCurrentAccount();
      return result.email != null; // NaverAccountResult에서 직접 이메일 확인
    } catch (e) {
      AppLogger.error('네이버 로그인 상태 확인 실패', error: e);
      return false;
    }
  }

  /// 현재 네이버 계정 정보 가져오기
  static Future<dynamic> getCurrentAccount() async {
    try {
      return await FlutterNaverLogin.getCurrentAccount();
    } catch (e) {
      AppLogger.error('네이버 계정 정보 가져오기 실패', error: e);
      return null;
    }
  }

  /// 네이버 로그인 에러 메시지를 한국어로 변환
  static String getKoreanErrorMessage(String status) {
    switch (status) {
      case 'NaverLoginStatus.loggedIn':
        return '로그인 성공';
      case 'NaverLoginStatus.cancelled':
        return '로그인이 취소되었습니다.';
      case 'NaverLoginStatus.error':
        return '로그인 중 오류가 발생했습니다.';
      default:
        return '알 수 없는 오류가 발생했습니다.';
    }
  }
}