import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserGuideScreen extends StatefulWidget {
  static const routeName = 'user-guide';
  static const routePath = '/user-guide';
  
  const UserGuideScreen({super.key});

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<GuideSection> _sections = [
    GuideSection(
      title: '매물 카드 관리',
      description: '부동산 매물을 카드 형태로 체계적으로 관리하는 방법',
      icon: Icons.credit_card,
      color: Color(0xFFFF8A65),
      steps: [
        GuideStep(
          title: '매물 카드 추가하기',
          description: '카드 목록 화면에서 + 버튼을 눌러 새로운 매물을 추가할 수 있습니다.',
          details: '• 플로팅 액션 버튼(+) 또는 "새카드 만들기" 버튼 탭\n• 차트 선택 다이얼로그에서 원하는 차트 선택\n• 새 차트가 없으면 "새 차트 만들기" 선택\n• 차트 제목 입력 후 매물 정보 입력 시작',
          tips: '💡 꿀팁: 한 차트에 비슷한 조건의 매물들을 모아두면 비교하기 편해요!',
        ),
        GuideStep(
          title: '매물 정보 상세 입력',
          description: '매물 카드를 탭하면 상세 정보를 확인하고 편집할 수 있습니다.',
          details: '• 카드 탭 → 상세 화면 진입\n• "편집" 버튼으로 편집 모드 전환\n• 텍스트 필드: 직접 입력 (이름, 가격 등)\n• 드롭다운: 미리 정의된 옵션 선택\n• 별점: 1~5점으로 매물 평가\n• "저장" 버튼으로 변경사항 저장',
          tips: '💡 꿀팁: 편집 중에도 자동저장되니 안심하고 입력하세요!',
        ),
        GuideStep(
          title: '이미지 관리하기',
          description: '매물 사진을 여러 장 첨부하고 갤러리 형태로 관리할 수 있습니다.',
          details: '• 갤러리 섹션에서 "이미지 추가" 버튼 탭\n• 카메라 촬영 또는 갤러리에서 선택\n• 여러 장 동시 선택 가능\n• 이미지 탭하여 풀스크린 보기\n• 길게 누르기로 삭제 옵션',
          tips: '💡 꿀팁: 방 구조, 주변 환경, 교통편 등 다양한 각도에서 찍어두세요!',
        ),
        GuideStep(
          title: '검색과 필터링',
          description: '원하는 매물을 빠르게 찾을 수 있는 다양한 검색 기능을 제공합니다.',
          details: '• 검색바: 매물 이름, 가격, 위치로 실시간 검색\n• 정렬 필터: 최신순, 거리순, 월세순 등\n• 차트별 필터: 특정 차트의 매물만 보기\n• 사용자 정의 정렬: 원하는 정렬 방식 추가\n• 클리어 버튼으로 검색어 쉽게 제거',
          tips: '💡 꿀팁: 자주 사용하는 정렬 방식은 직접 추가해서 사용하세요!',
        ),
      ],
    ),
    GuideSection(
      title: '스마트 차트 비교',
      description: '여러 매물을 표로 비교하고 분석하는 고급 기능',
      icon: Icons.table_chart,
      color: Color(0xFF2196F3),
      steps: [
        GuideStep(
          title: '차트 생성과 관리',
          description: '비교할 매물들을 모아서 차트를 만들고 관리할 수 있습니다.',
          details: '• 차트 화면에서 "차트목록 추가" 선택\n• 차트 제목과 날짜 설정\n• 체크박스로 여러 차트 동시 선택\n• 선택한 차트들 일괄 삭제 가능\n• 차트 탭하여 상세 비교표 열기',
          tips: '💡 꿀팁: 지역별, 가격대별로 차트를 나누면 비교가 더 효율적이에요!',
        ),
        GuideStep(
          title: '테이블 셀 편집하기',
          description: '차트의 각 셀을 직접 편집하여 상세한 비교 정보를 입력할 수 있습니다.',
          details: '• 셀 한 번 탭: 텍스트 편집 모드\n• 드롭다운 셀: 옵션 선택 메뉴\n• 이미지 셀: 사진 첨부 및 관리\n• 실시간 저장: 입력 즉시 자동 저장\n• ESC 또는 다른 셀 탭으로 편집 완료',
          tips: '💡 꿀팁: 이미지 셀에 방 사진, 주변 환경 사진을 넣으면 비교가 한눈에!',
        ),
        GuideStep(
          title: '컬럼 정렬과 필터링',
          description: '컬럼 헤더를 탭하여 데이터를 정렬하고 필터링할 수 있습니다.',
          details: '• 컬럼 헤더 탭: 정렬/필터 메뉴 열기\n• 오름차순/내림차순 정렬\n• 빠른 정렬: 가격순, 평점순 원클릭\n• 컬럼 이름 변경 가능\n• 컬럼 삭제 및 추가\n• 컬럼 표시/숨김 토글',
          tips: '💡 꿀팁: 가격 컬럼을 정렬하면 예산에 맞는 매물을 쉽게 찾을 수 있어요!',
        ),
        GuideStep(
          title: '차트 내보내기와 공유',
          description: 'PDF나 PNG 형태로 차트를 저장하고 다른 사람과 공유할 수 있습니다.',
          details: '• 차트 선택 후 내보내기 메뉴 열기\n• PDF 내보내기: 인쇄 가능한 문서 형태\n• PNG 내보내기: 이미지 형태로 갤러리 저장\n• 여러 차트 동시 내보내기 가능\n• 공유 버튼으로 메신저, 이메일 등 전송',
          tips: '💡 꿀팁: 부동산 중개사나 가족과 공유할 때 PDF가 깔끔해요!',
        ),
        GuideStep(
          title: '행과 열 관리하기',
          description: '매물과 비교 항목을 자유롭게 추가하고 삭제할 수 있습니다.',
          details: '• 행 추가: 새로운 매물 추가\n• 열 추가: 새로운 비교 항목 추가\n• 행/열 삭제: 불필요한 항목 제거\n• 드래그 앤 드롭으로 순서 변경\n• 기본 컬럼: 집 이름, 보증금, 월세, 별점 등',
          tips: '💡 꿀팁: 나만의 중요한 비교 항목을 추가해서 맞춤형 차트를 만들어보세요!',
        ),
      ],
    ),
    GuideSection(
      title: '지도 위치 확인',
      description: '지도를 통해 매물 위치와 주변 정보를 확인하는 방법',
      icon: Icons.map,
      color: Color(0xFF4CAF50),
      steps: [
        GuideStep(
          title: '매물 위치 확인하기',
          description: '지도에서 등록된 모든 매물의 위치를 한눈에 확인할 수 있습니다.',
          details: '• 지도 탭에서 전체 매물 위치 표시\n• 매물 마커 탭하여 기본 정보 확인\n• 핀치 줌으로 지도 확대/축소\n• 드래그로 지도 이동\n• 현재 위치 버튼으로 내 위치 이동',
          tips: '💡 꿀팁: 지도에서 여러 매물의 위치를 비교하면 최적의 위치를 찾을 수 있어요!',
        ),
        GuideStep(
          title: '장소 검색하기',
          description: '주소나 장소명으로 원하는 위치를 빠르게 검색할 수 있습니다.',
          details: '• 검색바에 주소 또는 장소명 입력\n• 자동완성으로 정확한 주소 선택\n• 검색 결과 지도에 표시\n• 즐겨찾기 장소 저장 가능\n• 최근 검색 기록 확인',
          tips: '💡 꿀팁: 직장이나 학교 주소를 검색해서 매물과의 거리를 확인해보세요!',
        ),
        GuideStep(
          title: '주변 편의시설 확인',
          description: '매물 주변의 편의점, 지하철역, 학교 등을 확인할 수 있습니다.',
          details: '• 편의시설 레이어 활성화\n• 편의점, 마트, 병원 등 표시\n• 대중교통 정보 확인\n• 학교, 공원 등 생활시설\n• 거리 정보와 도보 시간 제공',
          tips: '💡 꿀팁: 생활 패턴에 맞는 편의시설이 가까이 있는지 꼭 확인하세요!',
        ),
        GuideStep(
          title: '거리 측정과 경로',
          description: '매물 간의 거리나 특정 장소까지의 거리를 측정할 수 있습니다.',
          details: '• 두 지점 간 직선 거리 측정\n• 도보, 자전거, 대중교통 경로\n• 예상 소요 시간 표시\n• 여러 경로 옵션 비교\n• 교통비 예상 계산',
          tips: '💡 꿀팁: 출근 경로와 시간을 미리 확인해서 교통비와 시간을 계산해보세요!',
        ),
      ],
    ),
    GuideSection(
      title: '개인화와 설정',
      description: '나만의 우선순위와 프로필로 앱을 개인화하는 방법',
      icon: Icons.settings,
      color: Color(0xFF9C27B0),
      steps: [
        GuideStep(
          title: '우선순위 설정하기',
          description: '중요하게 생각하는 항목의 우선순위를 설정할 수 있습니다.',
          details: '• 마이페이지 > 우선순위 설정 접근\n• 6개 기본 항목 중요도 설정\n• 낮음/보통/높음 3단계 선택\n• 설정한 우선순위에 따라 카드에 표시\n• 언제든 재설정 가능',
          tips: '💡 꿀팁: 나의 라이프스타일에 맞는 우선순위를 설정하면 더 스마트한 비교가 가능해요!',
        ),
        GuideStep(
          title: '프로필 관리하기',
          description: '프로필 사진과 기본 정보를 관리할 수 있습니다.',
          details: '• 프로필 편집 버튼으로 수정 페이지 이동\n• 프로필 사진: 카메라 촬영 또는 갤러리 선택\n• 이름, 닉네임, 이메일 정보 수정\n• 비밀번호 변경 가능\n• 변경사항 저장 후 즉시 반영',
          tips: '💡 꿀팁: 프로필 사진을 설정하면 앱 사용이 더 개인화된 느낌이에요!',
        ),
        GuideStep(
          title: '사용법 가이드 활용',
          description: '언제든 자세한 사용법과 도움말을 확인할 수 있습니다.',
          details: '• 마이페이지에서 사용법 가이드 접근\n• 각 화면별 도움말 버튼 (❓)\n• 인터랙티브 가이드로 실시간 학습\n• 앱 튜토리얼 다시 보기\n• 단계별 상세 설명 제공',
          tips: '💡 꿀팁: 새로운 기능이 추가될 때마다 가이드를 확인해보세요!',
        ),
        GuideStep(
          title: '계정 관리와 보안',
          description: '로그인 정보를 안전하게 관리하고 계정을 전환할 수 있습니다.',
          details: '• 구글 계정 연동 로그인\n• 이메일/비밀번호 로그인\n• 로그아웃 후 다른 계정 로그인\n• 데이터 동기화 및 백업\n• 개인정보 보호 설정',
          tips: '💡 꿀팁: 구글 계정으로 로그인하면 데이터가 안전하게 보관돼요!',
        ),
      ],
    ),
    GuideSection(
      title: '고급 활용 팁',
      description: '앱을 더욱 효율적으로 사용할 수 있는 고급 기능들',
      icon: Icons.lightbulb,
      color: Color(0xFFFFC107),
      steps: [
        GuideStep(
          title: '키보드 단축키와 제스처',
          description: '빠른 조작을 위한 터치 제스처와 단축 방법들을 익혀보세요.',
          details: '• 좌우 스와이프: 페이지/탭 이동\n• 핀치 줌: 이미지 확대/축소\n• 길게 누르기: 삭제/옵션 메뉴\n• 더블 탭: 빠른 편집 모드\n• 드래그 앤 드롭: 순서 변경',
          tips: '💡 꿀팁: 제스처를 익히면 앱 사용 속도가 2배 빨라져요!',
        ),
        GuideStep(
          title: '데이터 관리 전략',
          description: '매물 데이터를 체계적으로 관리하는 효율적인 방법들입니다.',
          details: '• 지역별로 차트 분리 생성\n• 가격대별 매물 분류\n• 정기적인 데이터 백업\n• 불필요한 매물 정리\n• 이미지 용량 최적화',
          tips: '💡 꿀팁: 매주 한 번씩 데이터를 정리하면 앱이 더 빠르게 동작해요!',
        ),
        GuideStep(
          title: '협업과 공유 활용',
          description: '가족이나 친구들과 함께 매물을 비교하고 의견을 나눌 수 있습니다.',
          details: '• PDF/PNG 형태로 차트 공유\n• 메신저, 이메일로 빠른 전송\n• 인쇄 가능한 형태로 출력\n• 부동산 중개사와 정보 공유\n• 가족 회의 자료로 활용',
          tips: '💡 꿀팁: 중요한 결정은 가족과 함께! 차트를 공유해서 의견을 들어보세요.',
        ),
        GuideStep(
          title: '문제 해결과 최적화',
          description: '앱 사용 중 문제가 생겼을 때 해결하는 방법들입니다.',
          details: '• 앱 재시작으로 오류 해결\n• 저장공간 확보로 성능 향상\n• 네트워크 연결 상태 확인\n• 최신 버전으로 업데이트\n• 백업 데이터 복원',
          tips: '💡 꿀팁: 정기적인 앱 업데이트로 새로운 기능과 버그 수정을 받으세요!',
        ),
        GuideStep(
          title: '화면별 도움말 활용하기',
          description: '각 화면에서 제공되는 실시간 도움말 기능을 활용해보세요.',
          details: '• 각 화면 상단의 물음표(❓) 버튼 탭\n• 해당 화면의 기능별 상세 가이드 제공\n• 실제 UI 요소를 하이라이트하여 설명\n• 단계별 인터랙티브 튜토리얼 진행\n• 언제든 건너뛰기 또는 종료 가능\n• 새로운 기능 업데이트 시 자동 안내',
          tips: '💡 꿀팁: 새로운 화면에 처음 들어갔을 때는 꼭 물음표를 눌러보세요! 숨겨진 기능들을 발견할 수 있어요.',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _sections.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '사용법 가이드',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFF8A65),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // 페이지 인디케이터
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _sections.length,
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
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                return _buildGuidePage(_sections[index]);
              },
            ),
          ),
          
          // 네비게이션 버튼
          Container(
            padding: const EdgeInsets.all(20),
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
                
                if (_currentPage > 0 && _currentPage < _sections.length - 1)
                  const SizedBox(width: 16),
                
                if (_currentPage < _sections.length - 1)
                  Expanded(
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
                      child: const Text(
                        '다음',
                        style: TextStyle(
                          fontSize: 16,
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
    );
  }

  Widget _buildGuidePage(GuideSection section) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  section.color.withValues(alpha: 0.1),
                  section.color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: section.color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        section.color,
                        section.color.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: section.color.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    section.icon,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  section.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // 단계별 가이드
          ...section.steps.asMap().entries.map((entry) {
            int index = entry.key;
            GuideStep step = entry.value;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 단계 헤더
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              section.color,
                              section.color.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 설명
                  Text(
                    step.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 상세 설명
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: section.color,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '상세 방법',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: section.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.details,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 팁
                  if (step.tips.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFFE082),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        step.tips,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFE65100),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class GuideSection {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<GuideStep> steps;

  GuideSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.steps,
  });
}

class GuideStep {
  final String title;
  final String description;
  final String details;
  final String tips;

  GuideStep({
    required this.title,
    required this.description,
    required this.details,
    this.tips = '',
  });
}