import 'dart:developer' as developer;

// 클래스 이름을 AppLogger로 명확히 하여 사용합니다.
class AppLogger {
  // 기본 로그 함수
  static void log(String message,
      {String? name, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: name ?? 'HouseNote', // 기본 앱 이름 설정
      error: error,
      stackTrace: stackTrace,
    );
  }

  // 디버그용 로그
  static void d(String message) {
    log('DEBUG: $message');
  }

  // 정보 로그
  static void info(String message) {
    log('INFO: $message');
  }

  // 경고 로그
  static void warning(String message) {
    log('WARNING: $message');
  }

  // 에러 로그
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    log('ERROR: $message', error: error, stackTrace: stackTrace);
  }
}
