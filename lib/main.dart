import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'providers/general_providers.dart'; // appRouterProvider 포함
import 'firebase_options.dart';
import 'services/naver_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 네이버 로그인 초기화
  await NaverAuthService.initialize();

  debugPrint('🚀 앱 시작 (단순 모드)...');
  runApp(
    const ProviderScope(
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
