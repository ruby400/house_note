# Firebase 설정 가이드

이 가이드는 House Note 앱을 위한 Firebase 설정 방법을 안내합니다.

## 1. Firebase 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/)에 접속합니다.
2. "프로젝트 추가"를 클릭합니다.
3. 프로젝트 이름을 입력합니다 (예: "house-note")
4. Google Analytics 설정 (선택사항)
5. "프로젝트 만들기"를 클릭합니다.

## 2. Firebase Authentication 설정

1. Firebase 콘솔에서 "Authentication" 메뉴를 선택합니다.
2. "시작하기"를 클릭합니다.
3. "Sign-in method" 탭에서 다음 로그인 방법을 활성화합니다:
   - **이메일/비밀번호**: 사용 설정
   - **Google**: 사용 설정 (프로젝트 지원 이메일 입력 필요)

## 3. Cloud Firestore 설정

1. Firebase 콘솔에서 "Firestore Database" 메뉴를 선택합니다.
2. "데이터베이스 만들기"를 클릭합니다.
3. **테스트 모드**로 시작 (개발 중)
4. 위치 선택 (asia-northeast3 - 서울 권장)
5. "완료"를 클릭합니다.

### Firestore 보안 규칙 설정

"규칙" 탭에서 다음 규칙을 설정합니다:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자 문서 - 인증된 사용자만 자신의 데이터 읽기/쓰기 가능
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 카드 문서 - 인증된 사용자만 자신의 데이터 읽기/쓰기 가능
    match /cards/{cardId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
    }
  }
}
```

## 4. Android 앱 설정

1. Firebase 콘솔에서 Android 아이콘을 클릭합니다.
2. 패키지 이름 입력: `com.example.house_note`
3. 앱 닉네임 입력: `House Note`
4. 디버그 서명 인증서 SHA-1 (선택사항, Google 로그인 시 필요)
5. "앱 등록"을 클릭합니다.
6. `google-services.json` 파일을 다운로드합니다.
7. 파일을 `android/app/` 폴더에 복사합니다.

### Android 설정 파일 수정

#### `android/build.gradle` (프로젝트 레벨)
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

#### `android/app/build.gradle` (앱 레벨)
```gradle
apply plugin: 'com.google.gms.google-services'

android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
        multiDexEnabled true
    }
}

dependencies {
    implementation 'com.google.firebase:firebase-bom:32.7.0'
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.firebase:firebase-firestore'
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
}
```

## 5. iOS 앱 설정

1. Firebase 콘솔에서 iOS 아이콘을 클릭합니다.
2. 번들 ID 입력: `com.example.houseNote`
3. 앱 닉네임 입력: `House Note`
4. 앱 스토어 ID (선택사항)
5. "앱 등록"을 클릭합니다.
6. `GoogleService-Info.plist` 파일을 다운로드합니다.
7. Xcode에서 `ios/Runner/` 폴더에 파일을 추가합니다.

### iOS 설정 파일 수정

#### `ios/Runner/Info.plist`
```xml
<!-- 기존 내용 끝에 추가 -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

> `YOUR_REVERSED_CLIENT_ID`는 `GoogleService-Info.plist` 파일의 `REVERSED_CLIENT_ID` 값으로 교체하세요.

## 6. 웹 앱 설정

1. Firebase 콘솔에서 웹 아이콘 (`</>`)을 클릭합니다.
2. 앱 닉네임 입력: `House Note Web`
3. Firebase Hosting 설정 (선택사항)
4. "앱 등록"을 클릭합니다.
5. Firebase 설정 정보를 복사합니다.

### 웹 설정 파일 생성

`lib/firebase_options.dart` 파일을 생성하고 Firebase CLI로 생성한 설정을 붙여넣습니다:

```bash
flutterfire configure
```

## 7. Flutter 패키지 설정

`pubspec.yaml` 파일에 다음 의존성이 포함되어 있는지 확인하세요:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  google_sign_in: ^6.1.6
  flutter_riverpod: ^2.4.9
  go_router: ^12.1.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

## 8. 초기화 코드 확인

`lib/main.dart` 파일에서 Firebase 초기화가 되어 있는지 확인하세요:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

## 9. 테스트

1. 앱을 실행합니다: `flutter run`
2. 회원가입/로그인 기능을 테스트합니다.
3. Firebase 콘솔에서 사용자 생성을 확인합니다.
4. Firestore에서 사용자 데이터 저장을 확인합니다.

## 10. 프로덕션 배포 시 주의사항

### Firestore 보안 규칙 강화
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == userId
        && isValidUserData(request.resource.data);
    }
    
    function isValidUserData(data) {
      return data.keys().hasAll(['email', 'displayName']) 
        && data.keys().hasOnly(['email', 'displayName', 'photoURL', 'onboardingCompleted', 'priorities', 'createdAt', 'updatedAt']);
    }
  }
}
```

### Android 릴리즈 키 설정
릴리즈용 SHA-1 지문을 Firebase 콘솔에 추가하세요:

```bash
keytool -list -v -keystore release-key.keystore -alias release
```

### iOS App Store 배포
Xcode에서 프로덕션 빌드 설정을 확인하세요.

## 문제 해결

### 자주 발생하는 오류

1. **Google 로그인 실패**
   - SHA-1 지문이 올바르게 설정되었는지 확인
   - `google-services.json` 파일이 최신인지 확인

2. **Firestore 권한 오류**
   - 보안 규칙이 올바르게 설정되었는지 확인
   - 사용자 인증 상태 확인

3. **iOS 빌드 오류**
   - `GoogleService-Info.plist` 파일이 올바른 위치에 있는지 확인
   - Info.plist의 URL 스키마 설정 확인

### 로그 확인
Firebase 콘솔의 각 서비스 탭에서 실시간 로그를 확인할 수 있습니다.

## 추가 리소스

- [Firebase 문서](https://firebase.google.com/docs)
- [FlutterFire 문서](https://firebase.flutter.dev/)
- [Flutter 공식 Firebase 가이드](https://docs.flutter.dev/development/data-and-backend/firebase)