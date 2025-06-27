import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/core/utils/logger.dart';

/// Firebase 연결 상태 디버깅 유틸리티
class FirebaseDebugger {
  static Future<void> checkConnectionStatus() async {
    try {
      AppLogger.info('🔥 Firebase 연결 상태 확인 시작');
      
      // 1. Firebase Auth 상태 확인
      final currentUser = FirebaseAuth.instance.currentUser;
      AppLogger.info('👤 Firebase Auth 사용자: ${currentUser?.uid ?? "로그인 안됨"}');
      AppLogger.info('📧 이메일: ${currentUser?.email ?? "없음"}');
      
      // 2. Firestore 연결 상태 확인
      final firestore = FirebaseFirestore.instance;
      AppLogger.info('🗄️  Firestore 인스턴스 생성됨');
      
      // 3. 간단한 Firestore 쓰기/읽기 테스트
      if (currentUser != null) {
        AppLogger.info('🧪 Firestore 쓰기/읽기 테스트 시작');
        
        final testDoc = firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('charts')
            .doc('test');
        
        // 테스트 데이터 쓰기
        await testDoc.set({
          'test': true,
          'timestamp': FieldValue.serverTimestamp(),
          'message': 'Firebase 연결 테스트',
        });
        AppLogger.info('✅ Firestore 쓰기 성공');
        
        // 테스트 데이터 읽기
        final snapshot = await testDoc.get();
        if (snapshot.exists) {
          AppLogger.info('✅ Firestore 읽기 성공: ${snapshot.data()}');
        } else {
          AppLogger.error('❌ Firestore 읽기 실패: 문서 없음');
        }
        
        // 테스트 데이터 삭제
        await testDoc.delete();
        AppLogger.info('✅ Firestore 삭제 성공');
        
      } else {
        AppLogger.warning('⚠️  로그인 상태가 아니어서 Firestore 테스트 생략');
      }
      
      AppLogger.info('🎉 Firebase 연결 상태 확인 완료');
      
    } catch (e) {
      AppLogger.error('❌ Firebase 연결 상태 확인 실패', error: e);
    }
  }
  
  static Future<void> checkChartsData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.warning('⚠️  로그인 상태가 아님');
        return;
      }
      
      AppLogger.info('📊 사용자 차트 데이터 확인 시작');
      
      final chartsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('charts');
      
      final snapshot = await chartsCollection.get();
      AppLogger.info('📈 저장된 차트 개수: ${snapshot.docs.length}개');
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        AppLogger.info('📋 차트 ID: ${doc.id}');
        AppLogger.info('📋 차트 제목: ${data['title'] ?? "제목 없음"}');
        AppLogger.info('📋 부동산 개수: ${(data['properties'] as List?)?.length ?? 0}개');
      }
      
    } catch (e) {
      AppLogger.error('❌ 차트 데이터 확인 실패', error: e);
    }
  }
}

// Provider로 사용할 수 있도록
final firebaseDebuggerProvider = Provider<FirebaseDebugger>((ref) {
  return FirebaseDebugger();
});