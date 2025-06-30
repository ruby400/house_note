import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_note/core/widgets/browse_mode_intro_dialog.dart';
import 'package:house_note/features/card_list/views/card_list_screen.dart';
import 'package:house_note/features/main_navigation/views/main_navigation_screen.dart';
import 'package:house_note/providers/auth_providers.dart';
// import 'package:house_note/features/onboarding/views/priority_setting_screen.dart'; // 일시적으로 비활성화
// import 'package:house_note/providers/app_state_providers.dart'; // 일시적으로 비활성화
// import 'package:house_note/providers/user_providers.dart'; // 일시적으로 비활성화

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
  bool _hasShownWelcomeDialog = false;
  Timer? _delayTimer;

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
    _delayTimer?.cancel();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    // 애니메이션 시간과 화면 전환 시간을 맞춥니다.
    await Future.delayed(const Duration(seconds: 2));

    // 비동기 작업 후에는 항상 mounted를 확인하는 것이 안전합니다.
    if (!mounted) return;

    try {
      // 카드 목록 화면으로 이동하고 하단바 상태 초기화
      ref.read(selectedPageIndexProvider.notifier).state = 0; // 카드목록 탭 (0번)
      context.go(CardListScreen.routePath);
      
      // 로그인하지 않은 사용자에게만 환영 팝업 표시 (중복 방지)
      _delayTimer = Timer(const Duration(milliseconds: 1000), () {
        if (!mounted || _hasShownWelcomeDialog) return;
        
        final authState = ref.read(authStateChangesProvider);
        authState.when(
          data: (user) {
            // 로그인하지 않은 사용자에게만 환영 팝업 표시
            if (user == null && !_hasShownWelcomeDialog && mounted) {
              _hasShownWelcomeDialog = true;
              BrowseModeIntroDialog.show(context);
            }
          },
          loading: () {
            // 로딩 중일 때는 잠시 후 다시 확인
            _delayTimer = Timer(const Duration(milliseconds: 500), () {
              if (!mounted || _hasShownWelcomeDialog) return;
              
              final currentAuthState = ref.read(authStateChangesProvider);
              currentAuthState.whenData((user) {
                if (user == null && !_hasShownWelcomeDialog && mounted) {
                  _hasShownWelcomeDialog = true;
                  BrowseModeIntroDialog.show(context);
                }
              });
            });
          },
          error: (error, stackTrace) {
            // 에러 시에도 환영 팝업 표시 (게스트 모드로 간주)
            if (!_hasShownWelcomeDialog && mounted) {
              _hasShownWelcomeDialog = true;
              BrowseModeIntroDialog.show(context);
            }
          },
        );
      });
    } catch (e) {
      debugPrint('네비게이션 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 255, 158, 117), // 위쪽 밝은 주황색
              Color.fromARGB(255, 255, 132, 95), // 앱의 메인 주황색
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // 도시 실루엣 배경
            Positioned.fill(
              child: CustomPaint(
                painter: CitySilhouettePainter(),
                size: Size.infinite,
              ),
            ),
            // 메인 콘텐츠 (파동 효과)
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          // 고정된 강한 빛 효과
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.7),
                            blurRadius: 160,
                            spreadRadius: 80,
                            offset: const Offset(0, 0),
                          ),
                          // 내부 소프트 글로우
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.9),
                            blurRadius: 40,
                            spreadRadius: 24,
                            offset: const Offset(0, 0),
                          ),
                          // 가장 내부 강한 빛
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            blurRadius: 15,
                            spreadRadius: 3,
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
                        fontSize: 45,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.white,
                        shadows: [
                          // 후광 효과 - 바깥쪽 큰 글로우
                          Shadow(
                            offset: const Offset(0, 0),
                            blurRadius: 26,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          // 중간 글로우
                          Shadow(
                            offset: const Offset(0, 0),
                            blurRadius: 10,
                            color: Colors.white.withValues(alpha: 0.7),
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
                    const SizedBox(height: 13),
                    Text(
                      '당신의 완벽한 집을 찾아보세요',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 255, 252, 252)
                            .withValues(alpha: 0.95),
                        letterSpacing: 0.5,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 5,
                            color: Color(0x40000000),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 도시 실루엣을 그리는 페인터
class CitySilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15) // 더 진하게
      ..style = PaintingStyle.fill;

    final path = Path();

    // 도시 실루엣 그리기
    path.moveTo(0, size.height);

    // 촘촘한 빌딩들 - 더 많은 건물과 다양한 크기
    final buildingWidths = [
      25.0,
      18.0,
      35.0,
      12.0,
      28.0,
      45.0,
      22.0,
      38.0,
      15.0,
      30.0,
      20.0,
      42.0,
      16.0,
      33.0,
      24.0,
      40.0,
      19.0,
      27.0,
      36.0,
      14.0,
      31.0,
      23.0,
      29.0,
      17.0,
      34.0,
      21.0,
      26.0,
      39.0,
      13.0,
      32.0
    ];
    final buildingHeights = [
      0.12,
      0.08,
      0.18,
      0.06,
      0.15,
      0.25,
      0.11,
      0.20,
      0.07,
      0.16,
      0.10,
      0.22,
      0.09,
      0.17,
      0.13,
      0.21,
      0.08,
      0.14,
      0.19,
      0.06,
      0.16,
      0.12,
      0.15,
      0.09,
      0.18,
      0.11,
      0.14,
      0.23,
      0.07,
      0.17
    ]; // 다양한 높이

    double currentX = 0;

    for (int i = 0; i < buildingWidths.length && currentX < size.width; i++) {
      double width = buildingWidths[i];
      final height = size.height * buildingHeights[i];

      // 마지막 건물이 화면을 벗어나면 크기 조정
      if (currentX + width > size.width) {
        width = size.width - currentX;
      }

      // 건물 그리기
      path.lineTo(currentX, size.height - height);
      path.lineTo(currentX + width, size.height - height);
      currentX += width;

      // 화면 끝에 도달하면 중단
      if (currentX >= size.width) break;

      // 가끔씩 작은 틈을 넣어서 자연스럽게
      if (i % 5 == 4 && currentX + 2.0 < size.width) {
        currentX += 2.0; // 작은 간격
      }
    }

    // 화면 끝까지 더 많은 건물들로 채우기 (들쭉날쭉하게)
    while (currentX < size.width) {
      // 건물 너비를 다양하게 만들기
      final buildingWidth = [15.0, 18.0, 25.0, 12.0, 22.0, 28.0, 16.0, 20.0]
          [(currentX / 40).floor() % 8];
      
      // 진짜 들쭉날쭉한 높이 만들기 - 더 랜덤하고 불규칙하게
      final baseVariations = [0.05, 0.08, 0.12, 0.06, 0.15, 0.09, 0.18, 0.07, 0.14, 0.11, 0.20, 0.10, 0.16, 0.13, 0.19, 0.04];
      final randomOffset = ((currentX * 3.7) % 16).floor(); // 더 불규칙한 인덱스
      final baseHeight = baseVariations[randomOffset];
      
      // 추가 변동성을 위한 미세 조정
      final microVariation = ((currentX * 7.3) % 100) / 1000; // 0.000 ~ 0.099
      final buildingHeight = size.height * (baseHeight + microVariation);
      
      // 마지막 건물인지 확인
      if (currentX + buildingWidth + 8 >= size.width) {
        // 마지막 건물 - 중간 정도 높이로
        final lastHeight = size.height * 0.12;
        path.lineTo(currentX, size.height - lastHeight);
        path.lineTo(size.width, size.height - lastHeight);
        break;
      }
      
      // 건물 그리기 (위쪽만 분리, 아래는 완전히 연결)
      path.lineTo(currentX, size.height - buildingHeight);
      path.lineTo(currentX + buildingWidth, size.height - buildingHeight);
      
      // 다음 건물로 이동 (간격 없이 바로 붙여서)
      currentX += buildingWidth;
    }
    
    // 하단 라인 연결
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // 빌딩 창문 그리기
    _drawBuildingWindows(canvas, size);
  }

  void _drawBuildingWindows(Canvas canvas, Size size) {
    final windowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final lightWindowPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // 창문 그리기용 건물 데이터 재생성
    final buildingWidths = [
      25.0,
      18.0,
      35.0,
      12.0,
      28.0,
      45.0,
      22.0,
      38.0,
      15.0,
      30.0,
      20.0,
      42.0,
      16.0,
      33.0,
      24.0,
      40.0,
      19.0,
      27.0,
      36.0,
      14.0,
      31.0,
      23.0,
      29.0,
      17.0,
      34.0,
      21.0,
      26.0,
      39.0,
      13.0,
      32.0
    ];
    final buildingHeights = [
      0.12,
      0.08,
      0.18,
      0.06,
      0.15,
      0.25,
      0.11,
      0.20,
      0.07,
      0.16,
      0.10,
      0.22,
      0.09,
      0.17,
      0.13,
      0.21,
      0.08,
      0.14,
      0.19,
      0.06,
      0.16,
      0.12,
      0.15,
      0.09,
      0.18,
      0.11,
      0.14,
      0.23,
      0.07,
      0.17
    ];

    double currentX = 0;

    for (int i = 0; i < buildingWidths.length && currentX < size.width; i++) {
      double width = buildingWidths[i];
      final height = size.height * buildingHeights[i];

      // 마지막 건물이 화면을 벗어나면 크기 조정
      if (currentX + width > size.width) {
        width = size.width - currentX;
      }

      // 창문 크기 설정 (더 크게)
      final windowWidth = 5.0; // 더 크게
      final windowHeight = 6.0; // 더 크게

      // 이 건물에 창문을 그릴지 결정 (더 작은 건물도 포함)
      if (width > 20 && height > size.height * 0.10) {
        // 위쪽 영역에만 창문 (상위 50% 영역)
        final topArea = size.height - height + 8;
        final windowArea = (height * 0.5); // 건물 높이의 상위 50%

        // 더 많은 창문 배치 (조정된 너비에 맞춰)
        final windowCount = (width / 8).floor().clamp(1, 18); // 건물당 1~18개

        for (int w = 0; w < windowCount; w++) {
          // 가로세로 그리드로 배치
          final col = w % 3; // 3열로 배치
          final row = w ~/ 3; // 행 계산

          final x = currentX + 6 + (col * (width - 12) / 2);
          final y = topArea + (row * 12); // 12px 간격으로 행 배치

          // 창문이 건물 범위 내에 있고 화면 범위 내에 있는지 확인
          if (x < currentX + width - 6 && 
              y < topArea + windowArea && 
              x + windowWidth <= size.width) {
            // 랜덤하게 불 켜진 창문과 꺼진 창문
            final isLit = (i + w + col).toInt() % 4 == 0; // 25% 확률로 불 켜진 창문

            canvas.drawRect(
              Rect.fromLTWH(x, y, windowWidth, windowHeight),
              isLit ? lightWindowPaint : windowPaint,
            );
          }
        }
      }

      currentX += width;
      
      // 화면 끝에 도달하면 중단
      if (currentX >= size.width) break;
      
      if (i % 5 == 4 && currentX + 2.0 < size.width) {
        currentX += 2.0;
      }
    }

    // 추가 건물들에 창문 그리기 (수정된 간격 반영)
    double additionalX = currentX;
    int additionalBuildingIndex = 0;
    
    while (additionalX < size.width) {
      // 동일한 건물 크기 계산 로직
      final buildingWidth = [15.0, 18.0, 25.0, 12.0, 22.0, 28.0, 16.0, 20.0]
          [(additionalX / 40).floor() % 8];
      
      // 창문 그리기용 높이도 동일한 랜덤 로직 사용
      final baseVariations = [0.05, 0.08, 0.12, 0.06, 0.15, 0.09, 0.18, 0.07, 0.14, 0.11, 0.20, 0.10, 0.16, 0.13, 0.19, 0.04];
      final randomOffset = ((additionalX * 3.7) % 16).floor();
      final baseHeight = baseVariations[randomOffset];
      final microVariation = ((additionalX * 7.3) % 100) / 1000;
      final buildingHeight = size.height * (baseHeight + microVariation);
      
      // 마지막 건물 처리
      if (additionalX + buildingWidth + 8 >= size.width) {
        final actualWidth = size.width - additionalX;
        if (actualWidth > 10) {
          _drawBuildingWindowsForAdditional(canvas, additionalX, actualWidth, buildingHeight, size, additionalBuildingIndex, windowPaint, lightWindowPaint);
        }
        break;
      }
      
      // 창문 그리기
      if (buildingWidth > 12) {
        _drawBuildingWindowsForAdditional(canvas, additionalX, buildingWidth, buildingHeight, size, additionalBuildingIndex, windowPaint, lightWindowPaint);
      }
      
      // 다음 건물로 이동 (간격 없이 연결)
      additionalX += buildingWidth;
      
      additionalBuildingIndex++;
    }
  }

  void _drawBuildingWindowsForAdditional(Canvas canvas, double x, double width, double height, Size size, int buildingIndex, Paint windowPaint, Paint lightWindowPaint) {
    if (height > size.height * 0.08) {
      final topArea = size.height - height + 6;
      final windowArea = height * 0.6;
      
      final windowCount = (width / 12).floor().clamp(1, 6);
      
      for (int w = 0; w < windowCount; w++) {
        final col = w % 2;
        final row = w ~/ 2;
        
        final windowX = x + 4 + (col * (width - 8) / 1.5);
        final windowY = topArea + (row * 10);
        
        if (windowX < x + width - 4 && 
            windowY < topArea + windowArea && 
            windowX + 4.0 <= size.width) {
          final isLit = (buildingIndex + w + col) % 3 == 0;
          
          canvas.drawRect(
            Rect.fromLTWH(windowX, windowY, 4.0, 5.0),
            isLit ? lightWindowPaint : windowPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 떠다니는 집을 그리는 페인터
class FloatingHousePainter extends CustomPainter {
  final double opacity;

  FloatingHousePainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final housePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.8)
      ..style = PaintingStyle.fill;

    final roofPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.9)
      ..style = PaintingStyle.fill;

    // 집 몸체 (사각형)
    final houseRect = Rect.fromLTWH(size.width * 0.2, size.height * 0.4,
        size.width * 0.6, size.height * 0.6);
    canvas.drawRect(houseRect, housePaint);

    // 지붕 (삼각형)
    final roofPath = Path();
    roofPath.moveTo(size.width * 0.1, size.height * 0.4); // 왼쪽 아래
    roofPath.lineTo(size.width * 0.5, size.height * 0.1); // 꼭대기
    roofPath.lineTo(size.width * 0.9, size.height * 0.4); // 오른쪽 아래
    roofPath.close();
    canvas.drawPath(roofPath, roofPaint);

    // 문 (작은 사각형)
    final doorPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.6)
      ..style = PaintingStyle.fill;

    final doorRect = Rect.fromLTWH(size.width * 0.4, size.height * 0.7,
        size.width * 0.2, size.height * 0.3);
    canvas.drawRect(doorRect, doorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
