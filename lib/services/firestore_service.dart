import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/logger.dart';
import '../data/models/property_chart_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 사용자 ID 가져오기
  String? get currentUserId => _auth.currentUser?.uid;

  // 사용자별 컬렉션 경로
  String get _userChartsPath => 'users/$currentUserId/charts';

  // === 사용자 프로필 관리 ===

  // 사용자 프로필 생성/업데이트
  Future<void> createOrUpdateUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      AppLogger.info('사용자 프로필 생성/업데이트: $userId');
      
      final userData = {
        'email': email,
        'displayName': displayName ?? '',
        'photoURL': photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      };

      await _firestore.collection('users').doc(userId).set(
        userData,
        SetOptions(merge: true), // 기존 데이터와 병합
      );

      AppLogger.info('사용자 프로필 저장 완료');
    } catch (e) {
      AppLogger.error('사용자 프로필 저장 실패', error: e);
      throw '사용자 정보 저장 중 오류가 발생했습니다.';
    }
  }

  // 사용자 프로필 조회
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      AppLogger.error('사용자 프로필 조회 실패', error: e);
      return null;
    }
  }

  // === 차트 관리 ===

  // 차트 저장/업데이트
  Future<String> saveChart(PropertyChartModel chart) async {
    try {
      if (currentUserId == null) {
        throw '로그인이 필요합니다.';
      }

      AppLogger.info('차트 저장 시작: ${chart.title}');

      final chartData = chart.toJson();
      chartData['userId'] = currentUserId;
      chartData['updatedAt'] = FieldValue.serverTimestamp();

      String chartId;
      if (chart.id.isEmpty) {
        // 새 차트 생성
        chartData['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _firestore.collection(_userChartsPath).add(chartData);
        chartId = docRef.id;
        
        // ID 업데이트
        await docRef.update({'id': chartId});
      } else {
        // 기존 차트 업데이트
        chartId = chart.id;
        await _firestore.collection(_userChartsPath).doc(chartId).set(
          chartData,
          SetOptions(merge: true),
        );
      }

      AppLogger.info('차트 저장 완료: $chartId');
      return chartId;
    } catch (e) {
      AppLogger.error('차트 저장 실패', error: e);
      throw '차트 저장 중 오류가 발생했습니다.';
    }
  }

  // 차트 조회
  Future<PropertyChartModel?> getChart(String chartId) async {
    try {
      if (currentUserId == null) {
        throw '로그인이 필요합니다.';
      }

      final doc = await _firestore.collection(_userChartsPath).doc(chartId).get();
      
      if (!doc.exists) {
        AppLogger.warning('차트를 찾을 수 없음: $chartId');
        return null;
      }

      final data = doc.data()!;
      return PropertyChartModel.fromJson(data);
    } catch (e) {
      AppLogger.error('차트 조회 실패: $chartId', error: e);
      return null;
    }
  }

  // 사용자의 모든 차트 조회
  Stream<List<PropertyChartModel>> getUserCharts() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_userChartsPath)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return PropertyChartModel.fromJson(doc.data());
            } catch (e) {
              AppLogger.error('차트 파싱 오류: ${doc.id}', error: e);
              return null;
            }
          })
          .where((chart) => chart != null)
          .cast<PropertyChartModel>()
          .toList();
    });
  }

  // 차트 삭제
  Future<void> deleteChart(String chartId) async {
    try {
      if (currentUserId == null) {
        throw '로그인이 필요합니다.';
      }

      AppLogger.info('차트 삭제: $chartId');
      await _firestore.collection(_userChartsPath).doc(chartId).delete();
      AppLogger.info('차트 삭제 완료');
    } catch (e) {
      AppLogger.error('차트 삭제 실패', error: e);
      throw '차트 삭제 중 오류가 발생했습니다.';
    }
  }

  // 여러 차트 일괄 삭제
  Future<void> deleteCharts(List<String> chartIds) async {
    try {
      if (currentUserId == null) {
        throw '로그인이 필요합니다.';
      }

      AppLogger.info('차트 일괄 삭제: ${chartIds.length}개');
      
      final batch = _firestore.batch();
      for (final chartId in chartIds) {
        final docRef = _firestore.collection(_userChartsPath).doc(chartId);
        batch.delete(docRef);
      }
      
      await batch.commit();
      AppLogger.info('차트 일괄 삭제 완료');
    } catch (e) {
      AppLogger.error('차트 일괄 삭제 실패', error: e);
      throw '차트 삭제 중 오류가 발생했습니다.';
    }
  }

  // === 데이터 동기화 ===

  // 로컬 데이터를 Firestore로 마이그레이션
  Future<void> migrateLocalData(List<PropertyChartModel> localCharts) async {
    try {
      if (currentUserId == null) {
        throw '로그인이 필요합니다.';
      }

      AppLogger.info('로컬 데이터 마이그레이션 시작: ${localCharts.length}개');

      final batch = _firestore.batch();
      
      for (final chart in localCharts) {
        final chartData = chart.toJson();
        chartData['userId'] = currentUserId;
        chartData['createdAt'] = FieldValue.serverTimestamp();
        chartData['updatedAt'] = FieldValue.serverTimestamp();
        chartData['migratedFromLocal'] = true;

        final docRef = _firestore.collection(_userChartsPath).doc();
        chartData['id'] = docRef.id;
        batch.set(docRef, chartData);
      }

      await batch.commit();
      AppLogger.info('로컬 데이터 마이그레이션 완료');
    } catch (e) {
      AppLogger.error('로컬 데이터 마이그레이션 실패', error: e);
      throw '데이터 마이그레이션 중 오류가 발생했습니다.';
    }
  }

  // === 통계 및 메타데이터 ===

  // 사용자 차트 개수 조회
  Future<int> getUserChartCount() async {
    try {
      if (currentUserId == null) return 0;

      final snapshot = await _firestore.collection(_userChartsPath).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('차트 개수 조회 실패', error: e);
      return 0;
    }
  }

  // 사용자 통계 업데이트
  Future<void> updateUserStats() async {
    try {
      if (currentUserId == null) return;

      final chartCount = await getUserChartCount();
      
      await _firestore.collection('users').doc(currentUserId).update({
        'stats.totalCharts': chartCount,
        'stats.lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('사용자 통계 업데이트 실패', error: e);
    }
  }

  // === 오프라인 지원 ===

  // 오프라인 지원 활성화
  void enableOfflineSupport() {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      AppLogger.info('오프라인 지원 활성화 완료');
    } catch (e) {
      AppLogger.error('오프라인 지원 활성화 실패', error: e);
    }
  }

  // 네트워크 상태 확인
  Future<bool> isConnected() async {
    try {
      await _firestore.enableNetwork();
      return true;
    } catch (e) {
      return false;
    }
  }

  // === 사용자 데이터 완전 삭제 ===

  // 사용자의 모든 데이터 삭제 (계정 삭제 시)
  Future<void> deleteAllUserData(String userId) async {
    try {
      AppLogger.info('사용자 모든 데이터 삭제: $userId');

      // 차트 컬렉션 삭제
      final chartsQuery = _firestore.collection('users/$userId/charts');
      final chartsSnapshot = await chartsQuery.get();
      
      final batch = _firestore.batch();
      for (final doc in chartsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 사용자 프로필 삭제
      batch.delete(_firestore.collection('users').doc(userId));

      await batch.commit();
      AppLogger.info('사용자 모든 데이터 삭제 완료');
    } catch (e) {
      AppLogger.error('사용자 데이터 삭제 실패', error: e);
      throw '사용자 데이터 삭제 중 오류가 발생했습니다.';
    }
  }
}

// Riverpod Providers
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// 기존 호환성을 위한 Provider (기존 코드가 사용 중일 수 있음)
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// 사용자 차트 목록 Provider
final userChartsProvider = StreamProvider<List<PropertyChartModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUserCharts();
});

// 특정 차트 Provider
final chartProvider = FutureProvider.family<PropertyChartModel?, String>((ref, chartId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getChart(chartId);
});