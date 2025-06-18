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
      duration: const Duration(milliseconds: 1100), // 애니메이션 시간 조정
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF9575), // 앱 테마와 맞는 주황색
              Color.fromARGB(255, 255, 133, 96), // 메인 주황색
              Color.fromARGB(255, 254, 130, 102), // 따뜻한 주황색
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      // 후광 효과 - 바깥쪽 큰 글로우
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 80,
                        spreadRadius: 60,
                        offset: const Offset(0, 0),
                      ),
                      // 안쪽 소프트 글로우
                      BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/goyung.png',
                    width: 140,
                    height: 140,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'House Note',
                  style: TextStyle(
                    fontSize: 43,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.white,
                    shadows: [
                      // 후광 효과 - 바깥쪽 큰 글로우
                      Shadow(
                        offset: const Offset(0, 0),
                        blurRadius: 20,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      // 중간 글로우
                      Shadow(
                        offset: const Offset(0, 0),
                        blurRadius: 10,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      // 기본 그림자
                      const Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 4,
                        color: Color(0x40000000),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '당신의 완벽한 집을 찾아보세요',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color.fromARGB(255, 255, 252, 252)
                        .withOpacity(0.9),
                    letterSpacing: 0.5,
                    shadows: const [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        color: Color(0x30000000),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
