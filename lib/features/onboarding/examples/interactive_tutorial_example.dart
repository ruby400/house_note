import 'package:flutter/material.dart';
import '../views/interactive_guide_overlay.dart';

// 실제 앱에서 사용할 수 있는 인터랙티브 튜토리얼 예시
class InteractiveTutorialExample extends StatefulWidget {
  const InteractiveTutorialExample({super.key});

  @override
  State<InteractiveTutorialExample> createState() => _InteractiveTutorialExampleState();
}

class _InteractiveTutorialExampleState extends State<InteractiveTutorialExample> {
  // UI 요소들을 참조할 GlobalKey들
  final GlobalKey _menuButtonKey = GlobalKey();
  final GlobalKey _addButtonKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  
  // UI 상태 관리
  bool _isBottomSheetOpen = false;
  bool _isMenuOpen = false;
  bool _isCardAdded = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('인터랙티브 튜토리얼 예시'),
        actions: [
          IconButton(
            key: _settingsKey,
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 설정 페이지로 이동하는 로직
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('설정 페이지로 이동!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 튜토리얼 시작 버튼
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _startInteractiveTutorial,
              child: const Text('🎮 게임식 튜토리얼 시작'),
            ),
          ),
          
          const Expanded(
            child: Center(
              child: Text(
                '여기는 메인 컨텐츠 영역입니다.\n튜토리얼을 시작해보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      
      // 바텀 네비게이션
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              key: _menuButtonKey,
              icon: const Icon(Icons.menu),
              onPressed: _toggleMenu,
            ),
            IconButton(
              key: _addButtonKey,
              icon: const Icon(Icons.add),
              onPressed: _showAddBottomSheet,
            ),
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {},
            ),
          ],
        ),
      ),
      
      // 사이드 메뉴 (Drawer)
      drawer: _isMenuOpen ? Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('메뉴', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('홈'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('설정'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ) : null,
    );
  }
  
  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
    
    if (_isMenuOpen) {
      Scaffold.of(context).openDrawer();
    } else {
      Navigator.of(context).pop();
    }
  }
  
  void _showAddBottomSheet() {
    setState(() {
      _isBottomSheetOpen = true;
    });
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('새 항목 추가', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isCardAdded = true;
                  _isBottomSheetOpen = false;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('새 카드가 추가되었습니다!')),
                );
              },
              child: const Text('카드 추가'),
            ),
          ],
        ),
      ),
    ).then((_) {
      setState(() {
        _isBottomSheetOpen = false;
      });
    });
  }
  
  void _startInteractiveTutorial() {
    // 상태 초기화
    setState(() {
      _isBottomSheetOpen = false;
      _isMenuOpen = false;
      _isCardAdded = false;
    });
    
    final steps = [
      // 1단계: 환영 메시지
      GuideStep(
        title: '환영합니다! 🎉',
        description: '이제 실제 앱 기능들을 직접 체험해보는 튜토리얼을 시작하겠습니다.',
        autoNext: true,
        autoNextDelay: const Duration(seconds: 3),
      ),
      
      // 2단계: 메뉴 버튼 클릭하도록 유도
      GuideStep(
        title: '메뉴 열기',
        description: '먼저 앱의 메뉴를 열어보겠습니다.',
        targetKey: _menuButtonKey,
        tooltipPosition: GuideTooltipPosition.top,
        waitForUserAction: true,
        actionHint: '하단의 메뉴 버튼을 눌러주세요',
        actionValidator: () => _isMenuOpen,
        forceUIAction: () {
          // 자동으로 메뉴를 열어주는 대신 사용자가 직접 클릭하도록 유도
          // 실제로는 하이라이트만 표시
        },
      ),
      
      // 3단계: 메뉴가 열린 상태에서 설명
      GuideStep(
        title: '메뉴 탐색',
        description: '훌륭합니다! 메뉴가 열렸네요. 여기서 다양한 기능에 접근할 수 있습니다.',
        autoNext: true,
        autoNextDelay: const Duration(seconds: 3),
        onStepExit: () {
          // 메뉴 닫기
          if (_isMenuOpen) {
            Navigator.of(context).pop();
            setState(() {
              _isMenuOpen = false;
            });
          }
        },
      ),
      
      // 4단계: 바텀시트 열기
      GuideStep(
        title: '새 항목 추가',
        description: '이제 새로운 항목을 추가해보겠습니다.',
        targetKey: _addButtonKey,
        tooltipPosition: GuideTooltipPosition.top,
        waitForUserAction: true,
        actionHint: '+ 버튼을 눌러 새 항목을 추가해보세요',
        actionValidator: () => _isBottomSheetOpen,
      ),
      
      // 5단계: 바텀시트에서 실제 액션
      GuideStep(
        title: '카드 추가하기',
        description: '바텀시트가 열렸습니다! 이제 실제로 카드를 추가해보세요.',
        waitForUserAction: true,
        actionHint: '"카드 추가" 버튼을 눌러주세요',
        actionValidator: () => _isCardAdded,
        autoNext: false, // 사용자가 직접 액션을 완료해야 함
      ),
      
      // 6단계: 설정 버튼 소개
      GuideStep(
        title: '설정 접근',
        description: '마지막으로 앱 설정에 접근하는 방법을 알아보겠습니다.',
        targetKey: _settingsKey,
        tooltipPosition: GuideTooltipPosition.bottom,
        autoNext: true,
        autoNextDelay: const Duration(seconds: 3),
      ),
      
      // 7단계: 완료
      GuideStep(
        title: '튜토리얼 완료! 🎊',
        description: '축하합니다! 모든 주요 기능을 체험해보셨습니다. 이제 자유롭게 앱을 사용해보세요.',
        autoNext: true,
        autoNextDelay: const Duration(seconds: 3),
      ),
    ];
    
    InteractiveGuideManager.showGuide(
      context,
      steps: steps,
      onCompleted: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 인터랙티브 튜토리얼이 완료되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      },
      onSkipped: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('튜토리얼을 건너뛰었습니다.')),
        );
      },
    );
  }
}

// 사용법 예시를 보여주는 위젯
class TutorialUsageExample extends StatelessWidget {
  const TutorialUsageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('튜토리얼 사용법')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎮 게임식 인터랙티브 튜토리얼',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '주요 특징:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• 실제 UI 요소들과 상호작용'),
            Text('• 사용자 액션 대기 및 검증'),
            Text('• 자동 UI 조작 (바텀시트, 메뉴 등)'),
            Text('• 액션 힌트 및 진행 상태 표시'),
            Text('• 단계별 애니메이션 효과'),
            SizedBox(height: 16),
            Text(
              '구현 방법:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('1. GuideStep에 waitForUserAction: true 설정'),
            Text('2. actionValidator로 사용자 액션 검증'),
            Text('3. forceUIAction으로 UI 자동 조작'),
            Text('4. actionHint로 사용자 가이드'),
            Text('5. InteractiveGuideManager로 실행'),
          ],
        ),
      ),
    );
  }
}