import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppTutorialScreen extends StatefulWidget {
  static const routeName = 'app-tutorial';
  static const routePath = '/onboarding/tutorial';
  
  const AppTutorialScreen({super.key});

  @override
  State<AppTutorialScreen> createState() => _AppTutorialScreenState();
}

class _AppTutorialScreenState extends State<AppTutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<TutorialPage> _pages = [
    TutorialPage(
      title: '하우스노트에 오신 것을 환영합니다!',
      description: '부동산 매물을 체계적으로 관리하고\n비교할 수 있는 스마트한 도구입니다.',
      details: [
        '📋 매물 정보를 카드 형태로 쉽게 관리',
        '📊 표 형태로 여러 매물 한눈에 비교',
        '📍 지도에서 위치와 주변 환경 확인',
        '⭐ 나만의 우선순위로 맞춤 관리',
      ],
      icon: Icons.home,
      color: Color(0xFFFF8A65),
    ),
    TutorialPage(
      title: '매물 카드로 쉽게 관리하세요',
      description: '사진, 가격, 위치 등 매물의 모든 정보를\n카드 형태로 체계적으로 저장할 수 있습니다.',
      details: [
        '📱 카드 탭하기: 매물 상세 정보 보기',
        '📝 편집 모드: 모든 정보 수정 가능',
        '📸 이미지 추가: 매물 사진 여러 장 첨부',
        '⭐ 별점 평가: 1~5점으로 매물 평가',
        '🔍 실시간 검색: 이름, 가격으로 빠른 찾기',
        '📂 차트별 분류: 원하는 차트에 매물 등록',
      ],
      icon: Icons.credit_card,
      color: Color(0xFF4CAF50),
    ),
    TutorialPage(
      title: '스마트 차트로 한눈에 비교',
      description: '여러 매물을 표 형태로 만들어\n항목별로 쉽게 비교 분석할 수 있습니다.',
      details: [
        '📊 차트 생성: 비교할 매물들을 모아 차트 생성',
        '👆 셀 터치: 각 항목 바로 편집 가능',
        '📷 이미지 셀: 각 셀에 관련 사진 첨부',
        '🔄 헤더 탭: 컬럼별 정렬 및 필터링',
        '➕ 행/열 추가: 매물과 비교 항목 자유롭게 추가',
        '📤 내보내기: PDF, PNG 형태로 저장 및 공유',
        '☑️ 다중 선택: 여러 차트 한번에 관리',
      ],
      icon: Icons.table_chart,
      color: Color(0xFF2196F3),
    ),
    TutorialPage(
      title: '지도에서 위치를 한눈에',
      description: '매물 위치를 지도에서 확인하고\n주변 편의시설과 교통을 함께 체크하세요.',
      details: [
        '📍 위치 확인: 등록된 모든 매물 위치 표시',
        '🔍 장소 검색: 주소나 장소명으로 빠른 검색',
        '📱 내 위치: 현재 위치로 빠른 이동',
        '🏪 주변 시설: 편의점, 지하철역 등 확인',
        '📏 거리 측정: 직장, 학교까지 거리 계산',
        '🗺️ 지도 옵션: 다양한 지도 타입 선택',
      ],
      icon: Icons.map,
      color: Color(0xFF9C27B0),
    ),
    TutorialPage(
      title: '나만의 맞춤 설정으로 스마트하게',
      description: '중요한 항목의 우선순위를 설정하고\n프로필을 관리해 더 편리하게 사용하세요.',
      details: [
        '⚙️ 우선순위 설정: 교통, 가격 등 중요도 설정',
        '👤 프로필 편집: 사진과 개인정보 관리',
        '📖 사용법 가이드: 언제든 자세한 도움말 확인',
        '🎯 인터랙티브 가이드: 각 화면별 실시간 가이드',
        '🔐 로그인 관리: 안전한 계정 관리',
        '📤 로그아웃: 다른 계정으로 쉽게 전환',
      ],
      icon: Icons.settings,
      color: Color(0xFFFF9800),
    ),
    TutorialPage(
      title: '꿀팁! 이런 기능도 있어요',
      description: '알아두면 더욱 편리한\n숨겨진 기능들을 소개합니다.',
      details: [
        '📱 스와이프: 좌우로 밀어서 페이지 이동',
        '🔍 실시간 필터: 타이핑하는 즉시 결과 표시',
        '📸 다중 이미지: 한번에 여러 사진 선택 가능',
        '💾 자동 저장: 입력하는 즉시 자동으로 저장',
        '🎨 테마 색상: 앱 전체에 일관된 디자인',
        '❓ 도움말 버튼: 각 화면 우상단 물음표 아이콘',
        '📊 정렬 추가: 원하는 정렬 방식 직접 추가',
        '🖼️ 풀스크린: 이미지 탭하여 크게 보기',
      ],
      icon: Icons.lightbulb,
      color: Color(0xFFFF9866),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      context.go('/onboarding/priority');
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void _skipTutorial() {
    context.go('/onboarding/priority');
  }

  void _goToUserGuide() {
    context.go('/user-guide');
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
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text(
                        '이전',
                        style: TextStyle(
                          color: Color(0xFFFF8A65),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 60),
                  
                  // 페이지 인디케이터
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index
                              ? const Color(0xFFFF8A65)
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                  
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.grey,
                    ),
                    onSelected: (value) {
                      if (value == 'skip') {
                        _skipTutorial();
                      } else if (value == 'guide') {
                        _goToUserGuide();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'guide',
                        child: Row(
                          children: [
                            Icon(Icons.help_outline, size: 20),
                            SizedBox(width: 8),
                            Text('상세 가이드'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'skip',
                        child: Row(
                          children: [
                            Icon(Icons.skip_next, size: 20),
                            SizedBox(width: 8),
                            Text('건너뛰기'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 페이지 뷰
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildTutorialPage(_pages[index]);
                },
              ),
            ),
            
            // 하단 버튼
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF8A65),
                          side: const BorderSide(color: Color(0xFFFF8A65)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _previousPage,
                        child: const Text(
                          '이전',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  
                  if (_currentPage > 0) const SizedBox(width: 16),
                  
                  Expanded(
                    flex: _currentPage > 0 ? 1 : 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A65),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _nextPage,
                      child: Text(
                        _currentPage == _pages.length - 1 ? '시작하기' : '다음',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialPage(TutorialPage page) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // 아이콘
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.color.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 50,
              color: page.color,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 제목
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // 설명
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // 상세 기능 리스트
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: page.color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.stars,
                      color: page.color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '주요 기능',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: page.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...page.details.map((detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 12),
                        decoration: BoxDecoration(
                          color: page.color.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          detail,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class TutorialPage {
  final String title;
  final String description;
  final List<String> details;
  final IconData icon;
  final Color color;

  TutorialPage({
    required this.title,
    required this.description,
    required this.details,
    required this.icon,
    required this.color,
  });
}