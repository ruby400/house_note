import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_note/features/auth/views/auth_screen.dart';
import 'package:house_note/features/card_list/views/card_list_screen.dart';
import 'package:house_note/features/onboarding/views/priority_setting_screen.dart';
import 'package:house_note/providers/auth_providers.dart';
// ❗️TODO 해결: 주석을 해제하고 실제 userProvider를 사용합니다.
import 'package:house_note/providers/user_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  static const routeName = 'splash';
  static const routePath = '/';

  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500), // 애니메이션 시간 조정
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    // 애니메이션 시간과 화면 전환 시간을 맞춥니다.
    await Future.delayed(const Duration(seconds: 2));

    // 비동기 작업 후에는 항상 mounted를 확인하는 것이 안전합니다.
    if (!mounted) return;

    final user = ref.read(authStateChangesProvider).value;

    // ❗️ Dead Code 및 투두 해결:
    // 실제 사용자 정보에서 온보딩 완료 여부를 가져옵니다.
    final bool isOnboardingCompleted =
        ref.read(userModelProvider).value?.onboardingCompleted ?? false;

    if (user != null) {
      // 로그인된 사용자
      if (isOnboardingCompleted) {
        // 온보딩 완료 시 카드 목록 화면으로 이동
        context.go(CardListScreen.routePath);
      } else {
        // 온보딩 미완료 시 우선순위 설정 화면으로 이동
        context.go(PrioritySettingScreen.routePath);
      }
    } else {
      // 로그인되지 않은 사용자
      context.go(AuthScreen.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF8A65),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/goyung.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 30),
              const Text(
                'House Note',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      // ❗️ const 오류 해결: .withOpacity() 대신 16진수 코드로 변경
                      color: Color(0x4D000000), // 검은색의 30% 투명도
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
