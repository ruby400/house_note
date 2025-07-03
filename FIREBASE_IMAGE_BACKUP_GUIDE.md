# Firebase Storage 이미지 백업 시스템 가이드

## 🔥 주요 기능

### ✅ **완성된 기능들**
- **Firebase Storage 자동 백업**: 모든 이미지가 클라우드에 안전하게 저장
- **사용자별 폴더 구조**: `/users/{userId}/images/` 구조로 격리된 저장
- **로컬 + 클라우드 이중 저장**: 로컬 캐시 + Firebase Storage 백업
- **자동 동기화**: 네트워크 연결 시 자동으로 미동기화 이미지 업로드
- **실패 이미지 재시도**: 업로드 실패 시 자동 재시도 (최대 3회)
- **오프라인 지원**: 오프라인에서도 로컬 이미지 사용 가능
- **기존 API 호환성**: 기존 코드 수정 없이 사용 가능

### 🔄 **마이그레이션 시스템**
- **점진적 마이그레이션**: 기존 이미지들을 새로운 시스템으로 자동 변환
- **데이터 안전성**: 마이그레이션 중에도 기존 데이터 유지
- **호환성 보장**: 기존 `Map<String, List<String>>` 형식과 새로운 `EnhancedImageData` 형식 동시 지원

---

## 🚀 빠른 시작

### 1. 기본 사용법 (기존 코드와 동일)

```dart
import 'package:house_note/services/image_service_adapter.dart';

// 기존 방식 - 계속 작동함
final imagePath = await ImageServiceAdapter.takePicture();
final images = await ImageServiceAdapter.pickMultipleImagesFromGallery();
```

### 2. Firebase 백업 포함 사용법

```dart
// 새로운 방식 - Firebase 백업 포함
final imageData = await ImageServiceAdapter.takePictureWithBackup();
print('로컬 경로: ${imageData['localPath']}');
print('Firebase URL: ${imageData['firebaseUrl']}');
print('동기화 상태: ${imageData['syncStatus']}');
```

### 3. PropertyData에 이미지 추가

```dart
// PropertyData에 이미지 추가 (Firebase 백업 자동)
final result = await ImageServiceAdapter.addImageToProperty(
  propertyData: myProperty,
  cellId: 'address', // 주소 셀에 이미지 추가
  useCamera: true,   // true: 카메라, false: 갤러리
);

if (result['success']) {
  final updatedProperty = result['propertyData'] as PropertyData;
  final imageData = result['imageData'] as EnhancedImageData;
  print('이미지 추가 성공: ${imageData.localPath}');
}
```

---

## 📊 동기화 모니터링

### 동기화 상태 실시간 모니터링

```dart
import 'package:house_note/services/image_service_adapter.dart';

// 동기화 상태 스트림 구독
ImageServiceAdapter.syncStatusStream.listen((status) {
  print('동기화 상태: ${status.friendlyMessage}');
  print('진행률: ${(status.progress * 100).toStringAsFixed(1)}%');
  
  if (status.isActive) {
    // 동기화 진행 중 UI 업데이트
    showProgressIndicator(status.progress);
  } else {
    // 동기화 완료/실패/취소 처리
    hideProgressIndicator();
    
    switch (status.status) {
      case 'completed':
        showSuccessMessage('동기화 완료!');
        break;
      case 'failed':
        showErrorMessage('동기화 실패: ${status.error}');
        break;
      case 'cancelled':
        showInfoMessage('동기화가 취소되었습니다');
        break;
    }
  }
});
```

### 수동 동기화 실행

```dart
// 단일 PropertyData 동기화
final syncedProperty = await ImageServiceAdapter.syncPropertyImages(myProperty);

// 전체 차트 동기화
final syncedChart = await ImageServiceAdapter.syncChartImages(myChart);

// 여러 차트 일괄 동기화
final syncedCharts = await ImageServiceAdapter.syncMultipleCharts(allCharts);

// 실패한 이미지들만 재동기화
final retriedChart = await ImageServiceAdapter.retrySyncFailedImages(myChart);
```

### 동기화 취소

```dart
// 진행 중인 동기화 취소
ImageServiceAdapter.cancelSync();
```

---

## 📈 백업 상태 확인

### 전체 백업 상태 보고서

```dart
// 모든 차트의 백업 상태 확인
final report = ImageServiceAdapter.checkBackupStatus(allCharts);

print('총 이미지: ${report['summary']['totalImages']}개');
print('백업된 이미지: ${report['summary']['backedUpImages']}개');
print('백업률: ${(report['summary']['backupRate'] * 100).toStringAsFixed(1)}%');

// 권장사항 출력
final recommendations = report['recommendations'] as List<String>;
for (final recommendation in recommendations) {
  print(recommendation);
}
```

### 실시간 통계

```dart
// 동기화 통계 정보
final stats = await ImageServiceAdapter.getSyncStats(allCharts);

print('Firebase 연결 상태: ${stats['isFirebaseConnected']}');
print('동기화 필요: ${stats['needsSync']}');
print('대기 중인 이미지: ${stats['pendingImages']}개');
print('실패한 이미지: ${stats['failedImages']}개');
```

---

## 🔧 고급 기능

### 마이그레이션

```dart
// 단일 PropertyData 마이그레이션
final migratedProperty = ImageServiceAdapter.migratePropertyData(myProperty);

// 단일 차트 마이그레이션
final migratedChart = ImageServiceAdapter.migrateChart(myChart);

// 전체 차트 마이그레이션
final migratedCharts = ImageServiceAdapter.migrateAllCharts(allCharts);
```

### Firebase Storage 연결 확인

```dart
// Firebase Storage 연결 상태 확인
final isConnected = await ImageServiceAdapter.isFirebaseConnected();
if (!isConnected) {
  showErrorMessage('인터넷 연결을 확인해주세요');
}
```

### 이미지 복구

```dart
// Firebase에서 이미지 복구
final recoveredPath = await ImageServiceAdapter.recoverImageFromFirebase(
  firebaseUrl,
  fileName: 'recovered_image.jpg',
);

if (recoveredPath != null) {
  print('이미지 복구 성공: $recoveredPath');
}
```

### 사용자의 모든 Firebase 이미지 조회

```dart
// 사용자가 업로드한 모든 Firebase 이미지 URL 목록
final userImages = await ImageServiceAdapter.getUserFirebaseImages();
print('사용자 이미지 ${userImages.length}개 발견');
```

---

## 🛡️ 데이터 안전성

### 이중 백업 시스템
1. **로컬 저장**: 즉시 접근 가능, 오프라인 지원
2. **Firebase Storage**: 클라우드 백업, 기기 간 동기화

### 자동 복구
- 로컬 파일이 없으면 Firebase에서 자동 다운로드
- 네트워크 오류 시 자동 재시도 (최대 3회)
- 업로드 실패 시 'pending' 상태로 대기 후 다음 동기화 시 재시도

### 사용자별 격리
```
Firebase Storage 구조:
users/
  ├── {user_id_1}/
  │   └── images/
  │       ├── IMG_1234567890.jpg
  │       └── IMG_9876543210.jpg
  ├── {user_id_2}/
  │   └── images/
  │       └── IMG_5555555555.jpg
  └── anonymous/
      └── images/
          └── IMG_0000000000.jpg
```

---

## 🔄 동기화 상태

### 상태 설명
- `synced`: 로컬과 Firebase 모두 동기화됨 ✅
- `pending`: Firebase 업로드 대기 중 ⏳
- `failed`: Firebase 업로드 실패 ❌
- `local_only`: 로컬에만 존재 📱

### 상태 전환
```
local_only → pending → synced (성공)
local_only → pending → failed (실패)
failed → pending → synced (재시도 성공)
```

---

## 🎛️ 설정 및 최적화

### Firebase Storage 규칙 설정
```javascript
// Firebase Console > Storage > Rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 사용자별 폴더 접근 권한
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 익명 사용자 폴더 접근 권한
    match /anonymous/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 업로드 최적화 설정
- **이미지 압축**: 품질 80%, 최대 1920x1080
- **배치 업로드**: 500ms 간격으로 순차 업로드
- **재시도 로직**: 5초 간격으로 최대 3회 재시도
- **네트워크 오류 감지**: 네트워크 관련 오류 자동 재시도

---

## 🚨 문제 해결

### 자주 발생하는 문제

#### 1. Firebase 연결 오류
```dart
final isConnected = await ImageServiceAdapter.isFirebaseConnected();
if (!isConnected) {
  // 인터넷 연결 확인
  // Firebase 설정 확인
}
```

#### 2. 권한 오류
```dart
final hasPermissions = await ImageServiceAdapter.checkAndRequestPermissions();
if (!hasPermissions) {
  // 카메라/갤러리 권한 재요청
  await ImageServiceAdapter.openSettings();
}
```

#### 3. 동기화 실패
```dart
// 실패한 이미지들 재시도
final retriedChart = await ImageServiceAdapter.retrySyncFailedImages(myChart);

// 또는 전체 재동기화
final syncedChart = await ImageServiceAdapter.syncChartImages(myChart);
```

#### 4. 저장 공간 부족
```dart
// 로컬 캐시 정리 (30일 이상 된 파일)
await FirebaseImageService.cleanupLocalCache(keepDays: 30);
```

---

## 📝 마이그레이션 가이드

### 기존 코드 호환성
기존의 `ImageService`를 사용하는 코드는 **수정 없이** 계속 작동합니다:

```dart
// 기존 코드 - 그대로 사용 가능
import 'package:house_note/services/image_service.dart';

final imagePath = await ImageService.takePicture();
final exists = await ImageService.imageExists(imagePath);
await ImageService.deleteImage(imagePath);
```

### 새로운 백업 기능 사용
Firebase 백업을 사용하려면 `ImageServiceAdapter`로 변경:

```dart
// 새로운 코드 - Firebase 백업 포함
import 'package:house_note/services/image_service_adapter.dart';

// 기존 API와 동일하게 사용
final imagePath = await ImageServiceAdapter.takePicture();

// 또는 Firebase 백업 포함
final imageData = await ImageServiceAdapter.takePictureWithBackup();
```

### 점진적 마이그레이션
1. **1단계**: `ImageServiceAdapter` 임포트 변경
2. **2단계**: 백업 기능이 필요한 곳만 새로운 API 사용
3. **3단계**: 전체 차트 마이그레이션 실행
4. **4단계**: 정기적 동기화 설정

---

## 🎯 성능 최적화

### 메모리 사용량 최소화
- 이미지 압축: 원본 대비 약 60-80% 크기 감소
- 로컬 캐시 관리: 30일 이상 된 캐시 자동 삭제
- 점진적 로딩: 필요한 이미지만 다운로드

### 네트워크 사용량 최적화
- 중복 업로드 방지: 이미 동기화된 이미지는 재업로드하지 않음
- 배치 처리: 여러 이미지를 효율적으로 순차 업로드
- 압축 전송: 최적화된 이미지만 업로드

### 배터리 사용량 최적화
- 백그라운드 동기화: 사용자가 앱을 사용하지 않을 때만 실행
- 네트워크 상태 감지: WiFi 연결 시에만 대용량 동기화
- 지능형 재시도: 지수 백오프 알고리즘으로 배터리 절약

---

## 📊 모니터링 및 분석

### 사용량 통계
```dart
final stats = await ImageServiceAdapter.getSyncStats(allCharts);

// 개발자용 로그
AppLogger.info('=== 이미지 백업 통계 ===');
AppLogger.info('총 이미지: ${stats['totalImages']}개');
AppLogger.info('동기화율: ${(stats['syncRate'] * 100).toStringAsFixed(1)}%');
AppLogger.info('대기 중: ${stats['pendingImages']}개');
AppLogger.info('실패: ${stats['failedImages']}개');
```

### 오류 추적
- 모든 업로드/다운로드 작업 로깅
- 실패 원인 분석 및 자동 분류
- 성능 메트릭 수집 (업로드 시간, 성공률 등)

---

## 🔮 향후 계획

### 예정된 기능들
1. **이미지 압축 레벨 조정**: 사용자가 품질/용량 선택 가능
2. **자동 백업 스케줄링**: 정해진 시간에 자동 동기화
3. **이미지 태그 및 메타데이터**: 검색 및 분류 기능
4. **공유 기능**: 다른 사용자와 이미지 공유
5. **버전 관리**: 이미지 수정 이력 추적

### 성능 개선 계획
1. **CDN 연동**: 전 세계 빠른 이미지 액세스
2. **WebP 지원**: 더 작은 파일 크기
3. **지연 로딩**: 화면에 보이는 이미지만 로드
4. **프리페치**: 사용자가 볼 가능성이 높은 이미지 미리 로드

---

## 🆘 지원 및 문의

### 문제 신고
이슈가 발생하면 다음 정보와 함께 제보해주세요:

1. **앱 버전**: `package_info_plus` 패키지로 확인
2. **기기 정보**: `device_info_plus` 패키지로 확인
3. **오류 로그**: AppLogger에서 출력된 오류 메시지
4. **재현 단계**: 오류가 발생한 상황의 상세한 설명

### 로그 수집
```dart
// 디버그 정보 수집
final deviceInfo = await DeviceInfoPlugin().androidInfo; // 또는 iosInfo
final packageInfo = await PackageInfo.fromPlatform();
final stats = await ImageServiceAdapter.getSyncStats(allCharts);

print('=== 디버그 정보 ===');
print('앱 버전: ${packageInfo.version}');
print('기기: ${deviceInfo.model}');
print('이미지 통계: $stats');
```

---

**🔐 데이터 보안**: 모든 이미지는 Firebase Storage의 보안 규칙에 따라 보호되며, 사용자별로 격리되어 저장됩니다.

**🚀 지속적 개선**: 사용자 피드백을 바탕으로 지속적으로 기능을 개선하고 있습니다.

**💝 소중한 이미지를 안전하게 보호합니다!**