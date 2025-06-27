# 네이버 로그인 구현 가이드 📱

## 📋 **현재 상태**
- ✅ **Google 로그인**: 완전 구현 및 테스트 완료
- ✅ **네이버 로그인**: UI 및 백엔드 연동 완료, 실제 Client ID 설정 필요
- ✅ **패키지 호환성**: `flutter_naver_login ^2.1.1` 패키지 성공적으로 빌드 완료

## 🛠️ **네이버 로그인 완전 구현 방법**

### **1단계: 네이버 개발자센터 설정**

#### 1.1 네이버 개발자센터 등록
1. [네이버 개발자센터](https://developers.naver.com/main/) 접속
2. 로그인 후 **애플리케이션 등록**
3. 애플리케이션 정보 입력:
   - **애플리케이션 이름**: HouseNote
   - **사용 API**: 네이버 로그인
   - **환경 추가**: Android
   - **패키지명**: `com.example.house_note`
   - **마켓 URL**: 추후 입력

#### 1.2 Client ID/Secret 발급
```
Client ID: YOUR_NAVER_CLIENT_ID
Client Secret: YOUR_NAVER_CLIENT_SECRET
```

### **2단계: 호환 가능한 패키지 선택**

#### 옵션 1: 더 최신 패키지 사용
```yaml
dependencies:
  flutter_naver_login: ^2.1.1  # 최신 버전 시도
```

#### 옵션 2: 웹뷰 기반 구현
```yaml
dependencies:
  webview_flutter: ^4.4.2
  url_launcher: ^6.2.1
```

#### 옵션 3: HTTP 직접 구현
```yaml
dependencies:
  http: ^1.1.0
  crypto: ^3.0.3
```

### **3단계: Android 설정**

#### 3.1 AndroidManifest.xml 업데이트
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<application>
    <!-- 기존 Activity들... -->
    
    <!-- 네이버 로그인 설정 -->
    <meta-data
        android:name="com.naver.nid.CLIENT_ID"
        android:value="YOUR_NAVER_CLIENT_ID" />
    <meta-data
        android:name="com.naver.nid.CLIENT_SECRET"
        android:value="YOUR_NAVER_CLIENT_SECRET" />
    <meta-data
        android:name="com.naver.nid.CLIENT_NAME"
        android:value="HouseNote" />
        
    <!-- URL Scheme 처리 -->
    <activity
        android:name="com.nhn.android.naverlogin.ui.OAuthLoginActivity"
        android:theme="@android:style/Theme.Translucent.NoTitleBar" />
</application>
```

#### 3.2 ProGuard 설정
```
# android/app/proguard-rules.pro
-keep class com.nhn.android.naverlogin.** { *; }
```

### **4단계: iOS 설정 (필요시)**

#### 4.1 Info.plist 업데이트
```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>naverlogin</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_NAVER_CLIENT_ID</string>
        </array>
    </dict>
</array>

<key>NaverThirdPartyLogin</key>
<dict>
    <key>NaverConsumerKey</key>
    <string>YOUR_NAVER_CLIENT_ID</string>
    <key>NaverConsumerSecret</key>
    <string>YOUR_NAVER_CLIENT_SECRET</string>
    <key>NaverAppName</key>
    <string>HouseNote</string>
</dict>
```

### **5단계: 실제 Client ID/Secret 설정**

#### 5.1 패키지 설치 (✅ 완료)
```yaml
# pubspec.yaml
dependencies:
  flutter_naver_login: ^2.1.1  # ✅ 이미 설치됨
```

#### 5.2 NaverAuthService 설정 (✅ 대부분 완료)
```dart
// lib/services/naver_auth_service.dart에서 실제 값으로 교체
class NaverAuthService {
  static const String _clientId = 'YOUR_NAVER_CLIENT_ID';        // ⚠️ 실제 값으로 교체 필요
  static const String _clientSecret = 'YOUR_NAVER_CLIENT_SECRET'; // ⚠️ 실제 값으로 교체 필요
  static const String _clientName = 'HouseNote';
  
  // ✅ 모든 메서드 활성화 완료
}
```

#### 5.3 Android 매니페스트 설정 (✅ 완료)
```xml
<!-- android/app/src/main/AndroidManifest.xml에서 실제 값으로 교체 -->
<meta-data
    android:name="com.naver.nid.CLIENT_ID"
    android:value="YOUR_NAVER_CLIENT_ID" />  <!-- ⚠️ 실제 값으로 교체 필요 -->
<meta-data
    android:name="com.naver.nid.CLIENT_SECRET"
    android:value="YOUR_NAVER_CLIENT_SECRET" />  <!-- ⚠️ 실제 값으로 교체 필요 -->
```

#### 5.4 UI 업데이트 (✅ 완료)
```dart
// lib/features/auth/views/auth_screen.dart
// ✅ 네이버 버튼 스타일 복구 완료
decoration: const BoxDecoration(
  color: Color(0xFF03C75A),  // 네이버 그린
  shape: BoxShape.circle,
),
label: const Text(
  '네이버로 계속하기',      // ✅ "(개발 중)" 제거 완료
  style: TextStyle(
    color: Color(0xFF03C75A),
  ),
),
```

### **6단계: Firebase 연동 개선**

#### 6.1 서버 기반 인증 (권장)
```dart
// 실제 운영 환경에서는 서버에서 Custom Token 생성
class NaverFirebaseAuth {
  static Future<UserCredential?> signInWithNaver() async {
    // 1. 네이버 로그인
    final naverResult = await NaverAuthService.signInWithNaver();
    
    // 2. 서버에 네이버 토큰 전송하여 Firebase Custom Token 받기
    final customToken = await _getCustomTokenFromServer(naverResult.accessToken);
    
    // 3. Custom Token으로 Firebase 인증
    return await FirebaseAuth.instance.signInWithCustomToken(customToken);
  }
  
  static Future<String> _getCustomTokenFromServer(String naverToken) async {
    // 서버 API 호출하여 Custom Token 받기
    final response = await http.post(
      Uri.parse('https://your-server.com/auth/naver'),
      body: {'naver_token': naverToken},
    );
    return jsonDecode(response.body)['custom_token'];
  }
}
```

#### 6.2 클라이언트 기반 인증 (개발용)
```dart
// 현재 구현된 방식 (개발/테스트용)
// 실제 운영에서는 보안상 권장하지 않음
static Future<UserCredential?> signInWithNaverToFirebase() async {
  final naverResult = await signInWithNaver();
  final email = naverResult.account.email;
  
  // 이메일 기반 임시 계정 생성/로그인
  // 실제로는 서버에서 처리해야 함
}
```

## 🚀 **구현 우선순위**

### 높은 우선순위
1. **네이버 개발자센터 등록** ← 시작점
2. **최신 호환 패키지 찾기**
3. **Android 설정 완료**

### 보통 우선순위
4. **기본 네이버 로그인 구현**
5. **Firebase 연동 (임시 방식)**
6. **에러 처리 개선**

### 낮은 우선순위
7. **iOS 지원 추가**
8. **서버 기반 인증 구현**
9. **보안 강화**

## 🛡️ **보안 고려사항**

### 중요 사항
- ❌ **Client Secret을 앱에 하드코딩하지 말 것**
- ✅ **서버에서 토큰 검증 및 Custom Token 생성**
- ✅ **HTTPS 통신만 사용**
- ✅ **토큰 만료 처리**

### 권장 아키텍처
```
앱 → 네이버 로그인 → 네이버 토큰 → 서버 → Firebase Custom Token → Firebase Auth
```

## 📞 **문의 및 지원**

### 패키지 관련
- [flutter_naver_login GitHub](https://github.com/yello-tree/flutter_naver_login)
- [네이버 개발자센터 문서](https://developers.naver.com/docs/login/api/)

### Firebase 관련  
- [Firebase Custom Token 문서](https://firebase.google.com/docs/auth/admin/create-custom-tokens)
- [Firebase Flutter 문서](https://firebase.flutter.dev/)

---

**현재 구현 상태**: Google 로그인 완전 작동 ✅, 네이버 로그인 구현 완료 (실제 Client ID 설정만 필요) ✅