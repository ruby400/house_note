import 'package:package_info_plus/package_info_plus.dart';

/// 앱 정보 관리 유틸리티
class AppInfo {
  static PackageInfo? _packageInfo;

  /// 앱 정보 초기화 (앱 시작시 한번 호출)
  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// 앱 이름
  static String get appName => _packageInfo?.appName ?? 'House Note';

  /// 패키지 이름
  static String get packageName => _packageInfo?.packageName ?? '';

  /// 버전 (예: "1.0.0")
  static String get version => _packageInfo?.version ?? '1.0.0';

  /// 빌드 번호 (예: "1")
  static String get buildNumber => _packageInfo?.buildNumber ?? '1';

  /// 전체 버전 정보 (예: "1.0.0 (1)")
  static String get fullVersion => '$version ($buildNumber)';

  /// 빌드 정보 (예: "v1.0.0+1")
  static String get buildInfo => 'v$version+$buildNumber';

  /// 개발 버전인지 확인 (빌드 번호가 낮은 경우)
  static bool get isDevelopment => (int.tryParse(buildNumber) ?? 0) < 10;

  /// 베타 버전인지 확인 (버전에 "beta" 포함)
  static bool get isBeta => version.toLowerCase().contains('beta');

  /// 디버그 모드인지 확인
  static bool get isDebug {
    bool inDebugMode = false;
    assert(() {
      inDebugMode = true;
      return true;
    }());
    return inDebugMode;
  }

  /// 앱 정보 출력용 맵
  static Map<String, String> get infoMap => {
    '앱 이름': appName,
    '버전': version,
    '빌드 번호': buildNumber,
    '패키지 이름': packageName,
    '디버그 모드': isDebug ? '예' : '아니오',
  };

  /// 앱 정보를 문자열로 반환
  static String get infoString {
    final buffer = StringBuffer();
    buffer.writeln('$appName $fullVersion');
    if (isDebug) buffer.writeln('(디버그 모드)');
    if (isDevelopment) buffer.writeln('(개발 버전)');
    if (isBeta) buffer.writeln('(베타 버전)');
    return buffer.toString().trim();
  }
}