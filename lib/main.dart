import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // FlutterFire CLI로 자동 생성
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'providers/general_providers.dart'; // appRouterProvider 포함

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    AppLogger.info('🚀 Firebase 초기화 중...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('✅ Firebase 초기화 완료');
  } catch (e) {
    AppLogger.error('❌ Firebase 초기화 실패', error: e);
  }

  runApp(
    const ProviderScope(
      // Riverpod 사용을 위한 ProviderScope
      child: TripleOApp(),
    ),
  );
}

class TripleOApp extends ConsumerWidget {
  const TripleOApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(appRouterProvider); // GoRouter 인스턴스

    return MaterialApp.router(
      title: 'house_note',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme, // 다크 모드 지원시
      themeMode: ThemeMode.system, // 시스템 설정 따름
      routerConfig: goRouter, // GoRouter 설정
      debugShowCheckedModeBanner: false,
    );
  }
}
