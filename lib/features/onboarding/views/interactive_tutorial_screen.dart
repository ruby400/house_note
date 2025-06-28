import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'interactive_guide_overlay.dart';

class InteractiveTutorialScreen extends StatefulWidget {
  static const routeName = 'interactive-tutorial';
  static const routePath = '/onboarding/tutorial';
  
  const InteractiveTutorialScreen({super.key});

  @override
  State<InteractiveTutorialScreen> createState() => _InteractiveTutorialScreenState();
}

class _InteractiveTutorialScreenState extends State<InteractiveTutorialScreen> {
  // UI 요소들을 참조할 GlobalKey들
  final GlobalKey _startButtonKey = GlobalKey();
  final GlobalKey _skipButtonKey = GlobalKey();
  final GlobalKey _welcomeTextKey = GlobalKey();
  
  // UI 상태 관리
  bool _isStarted = false;
  
  @override
  void initState() {
    super.initState();
    // 화면이 로드되면 자동으로 튜토리얼 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInteractiveTutorial();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 네비게이션
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '하우스노트 튜토리얼',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  TextButton(
                    key: _skipButtonKey,
                    onPressed: _skipTutorial,
                    child: const Text(
                      '건너뛰기',
                      style: TextStyle(
                        color: Color(0xFFFF8A65),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 메인 아이콘
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A65).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.home,
                        size: 60,
                        color: Color(0xFFFF8A65),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // 환영 메시지
                    Text(
                      key: _welcomeTextKey,
                      '하우스노트에 오신 것을\n환영합니다! 🏠',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 설명
                    const Text(
                      '이제 실제 앱 기능들을 직접 체험하면서\n사용법을 배워보겠습니다.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4A5568),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // 시작 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: _startButtonKey,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8A65),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isStarted ? null : _startInteractiveTutorial,
                        child: _isStarted 
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  '튜토리얼 진행 중...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              '🎮 인터렉티브 튜토리얼 시작',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 특징 설명
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFF9866).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.stars,
                                color: Color(0xFFFF9866),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '새로운 튜토리얼 특징',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text('🎯 실제 UI 요소와 상호작용'),
                          SizedBox(height: 6),
                          Text('⚡ 사용자 액션 대기 및 검증'),
                          SizedBox(height: 6),
                          Text('🎪 실시간 가이드와 힌트'),
                          SizedBox(height: 6),
                          Text('✨ 애니메이션과 하이라이트 효과'),
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
  
  void _startInteractiveTutorial() {
    setState(() {
      _isStarted = true;
    });
    
    final steps = [
      // 1단계: 환영 메시지와 앱 소개
      GuideStep(
        title: '환영합니다! 🎉',
        description: '하우스노트는 부동산 매물을 체계적으로 관리하고 비교할 수 있는 스마트한 도구입니다. "다음" 버튼을 눌러 계속 진행하세요.',
        targetKey: _welcomeTextKey,
        tooltipPosition: GuideTooltipPosition.bottom,
        waitForUserAction: false, // 사용자가 직접 다음 버튼을 눌러야 함
      ),
      
      // 2단계: 튜토리얼 방식 설명
      GuideStep(
        title: '새로운 학습 방식 📚',
        description: '이제 실제 버튼을 클릭하고 기능을 체험하면서 배우게 됩니다. 각 단계마다 직접 해보세요! "다음" 버튼을 눌러 계속하세요.',
        waitForUserAction: false,
      ),
      
      // 3단계: 매물 카드 관리 소개
      GuideStep(
        title: '매물 카드로 쉽게 관리 📋',
        description: '사진, 가격, 위치 등 매물의 모든 정보를 카드 형태로 체계적으로 저장할 수 있습니다. "다음" 버튼을 눌러 계속하세요.',
        waitForUserAction: false,
      ),
      
      // 4단계: 스마트 차트 비교
      GuideStep(
        title: '스마트 차트로 한눈에 비교 📊',
        description: '여러 매물을 표 형태로 만들어 항목별로 쉽게 비교 분석할 수 있습니다. "다음" 버튼을 눌러 계속하세요.',
        waitForUserAction: false,
      ),
      
      // 5단계: 지도 기능
      GuideStep(
        title: '지도에서 위치를 한눈에 📍',
        description: '매물 위치를 지도에서 확인하고 주변 편의시설과 교통을 함께 체크하세요. "다음" 버튼을 눌러 계속하세요.',
        waitForUserAction: false,
      ),
      
      // 6단계: 맞춤 설정
      GuideStep(
        title: '나만의 맞춤 설정 ⚙️',
        description: '중요한 항목의 우선순위를 설정하고 프로필을 관리해 더 편리하게 사용하세요. "다음" 버튼을 눌러 계속하세요.',
        waitForUserAction: false,
      ),
      
      // 7단계: 꿀팁 소개
      GuideStep(
        title: '유용한 꿀팁들 💡',
        description: '스와이프로 페이지 이동, 실시간 필터, 다중 이미지 선택 등 편리한 기능들을 활용해보세요. "다음" 버튼을 눌러 계속하세요.',
        waitForUserAction: false,
      ),
      
      // 8단계: 실제 기능 체험 안내
      GuideStep(
        title: '실제 기능 체험 준비! 🚀',
        description: '이제 실제 매물 관리 화면으로 이동해서 직접 기능을 체험해보게습니다. "다음" 버튼을 눌러 계속하세요.',
        waitForUserAction: false,
        onStepExit: () {
          // 튜토리얼 종료 후 카드 목록 화면으로 이동 (인터랙티브 가이드 시작)
          context.go('/cards?guide=true');
        },
      ),
      
      // 9단계: 완료
      GuideStep(
        title: '튜토리얼 완료! 🎊',
        description: '축하합니다! 이제 매물 관리 화면에서 인터랙티브 가이드를 계속 체험해보세요. "완료" 버튼을 눌러 튜토리얼을 마무리하세요.',
        waitForUserAction: false,
      ),
    ];
    
    InteractiveGuideManager.showGuide(
      context,
      steps: steps,
      onCompleted: () {
        setState(() {
          _isStarted = false;
        });
        
        // 튜토리얼 완료 후 우선순위 설정으로 이동
        context.go('/onboarding/priority');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 인터렉티브 튜토리얼이 완료되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      },
      onSkipped: () {
        setState(() {
          _isStarted = false;
        });
        _skipTutorial();
      },
    );
  }
  
  void _skipTutorial() {
    // 튜토리얼 건너뛰기 - 우선순위 설정으로 이동
    context.go('/onboarding/priority');
  }
  
}