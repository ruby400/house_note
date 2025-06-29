import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:house_note/data/models/user_model.dart'; // 사용되지 않으므로 제거
import 'package:house_note/providers/auth_providers.dart';
import 'package:house_note/core/utils/logger.dart';
import 'package:house_note/core/widgets/guest_mode_banner.dart';
import 'package:house_note/core/widgets/login_prompt_dialog.dart';
import 'package:house_note/features/card_list/views/card_detail_screen.dart';
import 'package:house_note/data/models/property_chart_model.dart';
import 'package:house_note/providers/property_chart_providers.dart';
import 'package:house_note/providers/firebase_chart_providers.dart';
import 'package:house_note/features/onboarding/views/interactive_guide_overlay.dart';

class CardListScreen extends ConsumerStatefulWidget {
  static const routeName = 'card-list';
  static const routePath = '/cards';

  const CardListScreen({super.key});

  @override
  ConsumerState<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends ConsumerState<CardListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSort = '최신순'; // 기본 정렬 방식
  String? _selectedChartId; // 선택된 차트 ID

  // 차트별 색상 매핑
  final Map<String, Color> _chartColors = {};

  // 차트 색상 팔레트 - 원색 계열
  final List<Color> _colorPalette = [
    const Color(0xFFFF0000),  // 빨강
    const Color(0xFF0000FF),  // 파랑
    const Color(0xFF00FF00),  // 초록
    const Color(0xFFFF6600),  // 주황
    const Color(0xFF9900FF),  // 보라
    const Color(0xFF00FFFF),  // 시안
    const Color(0xFFFF0099),  // 마젠타
    const Color(0xFF6600FF),  // 인디고
    const Color(0xFFFFFF00),  // 노랑
    const Color(0xFF00FF99),  // 연두
  ];

  // 차트에 색상 할당
  Color _getChartColor(String chartId) {
    if (!_chartColors.containsKey(chartId)) {
      final colorIndex = _chartColors.length % _colorPalette.length;
      _chartColors[chartId] = _colorPalette[colorIndex];
    }
    return _chartColors[chartId]!;
  }

  String _searchQuery = ''; // 검색어
  // 재할당되지 않으므로 final로 변경
  final List<String> _customSortOptions = ['최신순', '거리순', '월세순']; // 사용자 정의 정렬 옵션

  // 가이드용 GlobalKey들 (디버그 라벨 추가로 충돌 방지)
  final GlobalKey _addButtonKey = GlobalKey(debugLabel: 'CardList_AddButton');
  final GlobalKey _searchKey = GlobalKey(debugLabel: 'CardList_Search');
  final GlobalKey _filterKey = GlobalKey(debugLabel: 'CardList_Filter');
  final GlobalKey _newCardButtonKey = GlobalKey(debugLabel: 'CardList_NewCard');
  final GlobalKey _chartFilterKey = GlobalKey(debugLabel: 'CardList_ChartFilter');
  final GlobalKey _sortAddButtonKey = GlobalKey(debugLabel: 'CardList_SortAdd');
  final GlobalKey _clearButtonKey = GlobalKey(debugLabel: 'CardList_Clear');

  // 동적 UI 요소용 GlobalKey들 (필요시 활성화)
  // final GlobalKey _popupMenuKey = GlobalKey(); // 팝업 메뉴 전체용
  // final List<GlobalKey> _sortOptionKeys = []; // 정렬 옵션들용

  // 실제 인터렉티브 튜토리얼 상태 변수들
  // bool _isSearching = false; // 현재 사용하지 않음
  bool _isFilterOpen = false;
  bool _hasAddedCard = false;

  // 포커스 관리를 위한 FocusNode
  final FocusNode _searchFocusNode = FocusNode();
  
  // Timer 관리 (메모리 누수 방지)
  final List<Timer> _timers = [];

  @override
  void dispose() {
    // Timer 정리
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 인터랙티브 가이드 자동 실행 완전히 비활성화
    // (환영 다이얼로그 전에 나타나는 구멍뚫린 화면 방지)
    /*
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 자동 가이드 실행 비활성화됨
    });
    */
  }

  void _showInteractiveGuide() {
    // 이미 가이드가 실행 중이면 중복 실행 방지
    if (InteractiveGuideManager.isShowing) {
      return;
    }
    
    // 상태 초기화
    setState(() {
      // _isSearching = false; // 현재 사용하지 않음
      _isFilterOpen = false;
      _hasAddedCard = false;
      _searchController.clear();
    });

    final steps = [
      // 1단계: 검색 기능 체험 (환영 단계 제거)
      GuideStep(
        title: '검색 기능 체험하기 🔍',
        description: '검색창에 텍스트를 입력하면 실시간으로 매물이 필터링됩니다. 다음 버튼을 눌러 계속하세요.',
        targetKey: _searchKey,
        tooltipPosition: GuideTooltipPosition.bottom,
        waitForUserAction: false,
        autoNext: true,
        forceUIAction: () {
          // 검색창에 포커스 주기 (안전한 방식)
          final timer = Timer(const Duration(milliseconds: 500), () {
            if (mounted) {
              _searchFocusNode.requestFocus();
            }
          });
          _timers.add(timer);
        },
      ),

      // 3단계: 검색 결과 확인
      GuideStep(
        title: '검색 결과 확인 ✅',
        description: '훌륭해요! 검색어가 입력되면 실시간으로 매물이 필터링됩니다. "다음" 버튼을 눌러 계속하세요.',
        waitForUserAction: false,
        onStepExit: () {
          // 검색어 초기화 (안전한 방식)
          if (mounted) {
            setState(() {
              _searchController.clear();
            });
          }
        },
      ),

      // 4단계: 정렬 필터 열기
      GuideStep(
        title: '정렬 필터 사용하기 📊',
        description: '정렬 버튼을 눌러서 매물을 다양한 방식으로 정렬할 수 있습니다. 다음 버튼을 눌러 계속하세요.',
        targetKey: _filterKey,
        tooltipPosition: GuideTooltipPosition.bottom,
        waitForUserAction: false,
        autoNext: true,
        shouldHighlightPopup: () => _isFilterOpen, // 팝업이 열렸을 때만 하이라이트
        shouldAvoidDynamicArea: () => _isFilterOpen, // 팝업이 열렸을 때 말풍선 위치 조정
        getDynamicArea: () {
          // 정렬 팝업이 나타났을 때의 영역
          if (_isFilterOpen) {
            // 정렬 버튼 아래쪽 팝업 영역
            return Rect.fromLTWH(0, 200, 300, 250); // 대략적인 팝업 영역
          }
          return Rect.zero;
        },
        forceUIAction: () {
          // 잠시 후 자동으로 정렬 메뉴를 열어줌 (사용자가 클릭하지 않을 경우를 대비)
          final timer1 = Timer(const Duration(seconds: 3), () {
            if (mounted && !_isFilterOpen) {
              setState(() {
                _isFilterOpen = true;
              });
              // 3초 후 자동으로 닫기
              final timer2 = Timer(const Duration(seconds: 2), () {
                if (mounted && _isFilterOpen) {
                  setState(() {
                    _isFilterOpen = false;
                  });
                }
              });
              _timers.add(timer2);
            }
          });
          _timers.add(timer1);
        },
      ),

      // 5단계: 정렬 옵션 선택
      GuideStep(
        title: '정렬 옵션 선택 ⚡',
        description: '정렬 메뉴가 열렸습니다! 원하는 정렬 방식을 선택할 수 있습니다. "다음" 버튼을 눌러 계속하세요.',
        waitForUserAction: false,
        onStepExit: () {
          // 정렬 메뉴 닫기 (안전한 방식)
          if (mounted) {
            setState(() {
              _isFilterOpen = false;
            });
          }
        },
      ),

      // 6단계: 매물 추가 기능
      GuideStep(
        title: '새 매물 추가하기 ➕',
        description: '"새카드 만들기" 버튼을 눌러서 새로운 매물을 추가할 수 있습니다. 다음 버튼을 눌러 계속하세요.',
        targetKey: _newCardButtonKey,
        tooltipPosition: GuideTooltipPosition.top,
        waitForUserAction: false,
        autoNext: true,
        shouldAvoidDynamicArea: () => _hasAddedCard, // 바텀시트가 나타났을 때 말풍선 위치 조정
        getDynamicArea: () {
          // 바텀시트가 나타났을 때의 영역 (더 정확한 계산)
          if (_hasAddedCard && mounted) {
            try {
              final screenHeight = MediaQuery.of(context).size.height;
              final screenWidth = MediaQuery.of(context).size.width;
              // 바텀시트는 보통 화면 하단 70% 정도를 차지함
              return Rect.fromLTWH(
                0,
                screenHeight * 0.25, // 화면 상단 25%부터 시작
                screenWidth,
                screenHeight * 0.75, // 화면 하단 75% 영역
              );
            } catch (e) {
              // MediaQuery 접근 실패시 기본값 반환
              return Rect.zero;
            }
          }
          return Rect.zero;
        },
      ),

      // 7단계: 완료
      GuideStep(
        title: '튜토리얼 완료! 🎉',
        description:
            '훌륭합니다! 이제 매물 카드 관리의 주요 기능들을 모두 체험해보셨습니다. 다른 화면들도 각각 ❓ 버튼으로 가이드를 볼 수 있습니다. "완료" 버튼을 눌러 마무리하세요.',
        waitForUserAction: false,
      ),
    ];

    InteractiveGuideManager.showGuide(
      context,
      steps: steps,
      onCompleted: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 인터렉티브 가이드가 완료되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      onSkipped: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('가이드를 건너뛰었습니다.'),
            ),
          );
        }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('카드 목록',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline,
              color: Colors.white,
              size: 24,
            ),
            onPressed: _showInteractiveGuide,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF9575), // 좋은 중간조 주황색 (왼쪽 위)
                Color(0xFFFF8A65), // 메인 주황색 (중간)
                Color(0xFFFF8064), // 따뜻한 주황색 (오른쪽 아래)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 게스트 모드 배너 (로그인하지 않은 사용자에게만 표시)
          Consumer(
            builder: (context, ref, child) {
              final isAuthenticated = ref.watch(authStateChangesProvider).value != null;
              if (!isAuthenticated) {
                return const GuestModeBanner();
              }
              return const SizedBox.shrink();
            },
          ),
          // 검색 바 및 필터 영역
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                // 검색 바
                Container(
                  key: _searchKey,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: '카드 이름, 위치, 가격으로 검색...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              key: _clearButtonKey,
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // 필터 버튼들 - 스크롤 가능하게 수정
                SizedBox(
                  height: 43,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // 정렬 드롭다운
                      PopupMenuButton<String>(
                        offset: const Offset(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Colors.white,
                        elevation: 16,
                        shadowColor: Colors.black.withValues(alpha: 0.25),
                        surfaceTintColor: Colors.white,
                        constraints: const BoxConstraints(
                          minWidth: 200,
                          maxWidth: 280,
                        ),
                        itemBuilder: (context) => [
                          ..._customSortOptions
                              .map((option) => PopupMenuItem<String>(
                                    value: option,
                                    height: 48,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _selectedSort == option
                                            ? const Color(0xFFFF8A65)
                                                .withValues(alpha: 0.1)
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _selectedSort == option
                                              ? const Color(0xFFFF8A65)
                                                  .withValues(alpha: 0.3)
                                              : Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _selectedSort == option
                                                ? Icons.check_circle
                                                : Icons.sort,
                                            color: _selectedSort == option
                                                ? const Color(0xFFFF8A65)
                                                : const Color(0xFF718096),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            option,
                                            style: TextStyle(
                                              fontWeight:
                                                  _selectedSort == option
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                              fontSize: 14,
                                              color: _selectedSort == option
                                                  ? const Color(0xFFFF8A65)
                                                  : const Color(0xFF2D3748),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                          PopupMenuItem<String>(
                            enabled: false,
                            height: 16,
                            child: Container(
                              height: 1,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.grey[300]!,
                                    Colors.transparent
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'ADD_NEW',
                            height: 48,
                            child: Container(
                              key: _sortAddButtonKey,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.grey[200]!, width: 1),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.add,
                                      size: 18, color: Color(0xFF718096)),
                                  SizedBox(width: 8),
                                  Text(
                                    '새 정렬 방식 추가',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onSelected: (String value) {
                          if (value == 'ADD_NEW') {
                            _showAddSortOptionDialog();
                          } else {
                            if (mounted) {
                              setState(() {
                                _selectedSort = value;
                                _isFilterOpen = false; // 튜토리얼 상태 추적
                              });
                            }
                          }
                        },
                        onOpened: () {
                          setState(() {
                            _isFilterOpen = true; // 튜토리얼 상태 추적 - 필터 메뉴 열림
                          });
                        },
                        onCanceled: () {
                          setState(() {
                            _isFilterOpen = false; // 튜토리얼 상태 추적 - 필터 메뉴 닫힘
                          });
                        },
                        child: Container(
                          key: _filterKey, // GlobalKey를 child Container에 설정
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8A65)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedSort,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 차트 선택 드롭다운
                      Consumer(
                        builder: (context, ref, child) {
                          final chartList =
                              ref.watch(propertyChartListProvider);
                          final String displayText = _selectedChartId == null
                              ? '모든 차트'
                              : chartList
                                      .firstWhere(
                                        (chart) => chart.id == _selectedChartId,
                                        orElse: () => PropertyChartModel(
                                          id: '',
                                          title: '모든 차트',
                                          date: DateTime.now(),
                                        ),
                                      )
                                      .title
                                      .isNotEmpty
                                  ? chartList
                                      .firstWhere(
                                        (chart) => chart.id == _selectedChartId,
                                        orElse: () => PropertyChartModel(
                                          id: '',
                                          title: '모든 차트',
                                          date: DateTime.now(),
                                        ),
                                      )
                                      .title
                                  : '차트 $_selectedChartId';

                          return PopupMenuButton<String?>(
                            key: _chartFilterKey,
                            offset: const Offset(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            color: Colors.white,
                            elevation: 16,
                            shadowColor: Colors.black.withValues(alpha: 0.25),
                            surfaceTintColor: Colors.white,
                            constraints: const BoxConstraints(
                              minWidth: 200,
                              maxWidth: 300,
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem<String?>(
                                value: 'ALL_CHARTS',
                                height: 48,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedChartId == null
                                        ? const Color(0xFFFF8A65)
                                            .withValues(alpha: 0.1)
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _selectedChartId == null
                                          ? const Color(0xFFFF8A65)
                                              .withValues(alpha: 0.3)
                                          : Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _selectedChartId == null
                                            ? Icons.check_circle
                                            : Icons.grid_view,
                                        color: _selectedChartId == null
                                            ? const Color(0xFFFF8A65)
                                            : const Color(0xFF718096),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '모든 차트',
                                        style: TextStyle(
                                          fontWeight: _selectedChartId == null
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: 14,
                                          color: _selectedChartId == null
                                              ? const Color(0xFFFF8A65)
                                              : const Color(0xFF2D3748),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ...chartList.map((chart) => PopupMenuItem<String>(
                                    value: chart.id,
                                    height: 48,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _selectedChartId == chart.id
                                            ? const Color(0xFFFF8A65)
                                                .withValues(alpha: 0.1)
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _selectedChartId == chart.id
                                              ? const Color(0xFFFF8A65)
                                                  .withValues(alpha: 0.3)
                                              : Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _selectedChartId == chart.id
                                                ? Icons.check_circle
                                                : Icons.bar_chart,
                                            color: _selectedChartId == chart.id
                                                ? const Color(0xFFFF8A65)
                                                : const Color(0xFF718096),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              chart.title.isNotEmpty
                                                  ? chart.title
                                                  : '차트 ${chart.id}',
                                              style: TextStyle(
                                                fontWeight:
                                                    _selectedChartId == chart.id
                                                        ? FontWeight.w600
                                                        : FontWeight.w500,
                                                fontSize: 14,
                                                color: _selectedChartId ==
                                                        chart.id
                                                    ? const Color(0xFFFF8A65)
                                                    : const Color(0xFF2D3748),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                            ],
                            onSelected: (String? value) {
                              if (mounted) {
                                setState(() {
                                  if (value == 'ALL_CHARTS') {
                                    _selectedChartId = null;
                                  } else {
                                    _selectedChartId = value;
                                  }
                                });
                              }
                            },
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF8A65),
                                    Color(0xFFFF7043)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF8A65)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      // 새카드 만들기 버튼
                      GestureDetector(
                        onTap: () {
                          // 로그인 상태 확인
                          final isAuthenticated = ref.read(authStateChangesProvider).value != null;
                          
                          if (!isAuthenticated) {
                            // 게스트 사용자는 로그인 프롬프트 표시
                            LoginPromptDialog.show(
                              context,
                              title: '카드 생성',
                              message: '현재 둘러보기 모드입니다.\n데이터를 저장하려면 로그인이 필요합니다.\n\n지금 로그인하시겠습니까?',
                              icon: Icons.add_card,
                            );
                            return;
                          }
                          
                          setState(() {
                            _hasAddedCard = true; // 튜토리얼 상태 업데이트
                          });
                          // 바텀시트를 열기 전에 잠시 대기 (말풍선 위치 조정을 위해)
                          final timer = Timer(const Duration(milliseconds: 100), () {
                            _showChartSelectionDialog();
                          });
                          _timers.add(timer);
                        },
                        child: Container(
                          key: _newCardButtonKey,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8A65)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_chart,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '새카드 만들기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16), // 마지막 여백
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 카드 리스트 (차트 데이터 기반)
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final chartList = ref.watch(propertyChartListProvider);
                final propertyList = <PropertyData>[];
                final propertyChartMap =
                    <String, String>{}; // property.id -> chart.id 매핑

                // 선택된 차트에 따라 필터링
                if (_selectedChartId != null) {
                  final selectedChart = chartList.firstWhere(
                    (chart) => chart.id == _selectedChartId,
                    orElse: () => PropertyChartModel(
                      id: '',
                      title: '',
                      date: DateTime.now(),
                      properties: [],
                    ),
                  );
                  // 특정 차트에서는 빈 카드도 표시 (사용자가 어떤 차트인지 알 수 있게)
                  propertyList.addAll(selectedChart.properties);

                  // 차트 매핑 추가
                  for (final property in selectedChart.properties) {
                    propertyChartMap[property.id] = selectedChart.id;
                  }
                } else {
                  // 차트별로 그룹화해서 순서대로 표시
                  for (final chart in chartList) {
                    // 각 차트의 모든 카드를 순서대로 추가
                    for (final property in chart.properties) {
                      propertyList.add(property);
                      propertyChartMap[property.id] = chart.id;
                    }
                  }
                }

                // 검색어로 필터링
                if (_searchQuery.isNotEmpty) {
                  propertyList.removeWhere((property) {
                    final name = property.name.toLowerCase();
                    final deposit = property.deposit.toLowerCase();
                    final rent = property.rent.toLowerCase();
                    final direction = property.direction.toLowerCase();
                    final landlordEnv =
                        property.landlordEnvironment.toLowerCase();

                    // 추가 데이터에서도 검색
                    final additionalValues = property.additionalData.values
                        .map((v) => v.toLowerCase())
                        .join(' ');

                    return !(name.contains(_searchQuery) ||
                        deposit.contains(_searchQuery) ||
                        rent.contains(_searchQuery) ||
                        direction.contains(_searchQuery) ||
                        landlordEnv.contains(_searchQuery) ||
                        additionalValues.contains(_searchQuery));
                  });
                }

                // 선택된 정렬 방식에 따라 정렬 (특정 차트 선택 시에만)
                if (_selectedChartId != null) {
                  _sortPropertyList(propertyList);
                }

                if (propertyList.isEmpty) {
                  return _searchQuery.isNotEmpty
                      ? _buildNoSearchResults()
                      : _buildEmptyState();
                }
                return _buildCardList(propertyList, propertyChartMap);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          key: _addButtonKey,
          onPressed: () {
            // 로그인 상태 확인
            final isAuthenticated = ref.read(authStateChangesProvider).value != null;
            
            if (!isAuthenticated) {
              // 게스트 사용자는 로그인 프롬프트 표시
              LoginPromptDialog.show(
                context,
                title: '카드 생성',
                message: '현재 둘러보기 모드입니다.\n데이터를 저장하려면 로그인이 필요합니다.\n\n지금 로그인하시겠습니까?',
                icon: Icons.add_card,
              );
              return;
            }
            
            setState(() {
              _hasAddedCard = true; // 튜토리얼 상태 추적
            });
            _showChartSelectionDialog();
          },
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  void _showAddSortOptionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 8,
          title: Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFFFFECE0), width: 2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.sort, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                const Text(
                  '정렬 옵션 추가',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242)),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECE0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '새로운 정렬 방식을 추가하여 사용할 수 있습니다.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6D4C41)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: '정렬 방식 이름',
                  labelStyle: const TextStyle(color: Color(0xFFFF8A65)),
                  hintText: '예: 별점순, 방향순 등',
                  hintStyle: const TextStyle(color: Color(0xFFBCAAA4)),
                  prefixIcon: const Icon(Icons.add, color: Color(0xFFFF8A65)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFFFFCCBC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide:
                        const BorderSide(color: Color(0xFFFF8A65), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFFFFCCBC)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFF8F5),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('취소',
                  style: TextStyle(
                      color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    if (mounted) {
                      setState(() {
                        _customSortOptions.add(controller.text.trim());
                      });
                    }
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '"${controller.text.trim()}" 정렬 방식이 추가되었습니다.',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        backgroundColor: const Color(0xFFFF8A65),
                        duration: const Duration(milliseconds: 1000),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(16),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('추가',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _sortPropertyList(List<PropertyData> properties) {
    switch (_selectedSort) {
      case '최신순':
        properties.sort((a, b) => b.id.compareTo(a.id));
        break;
      case '거리순':
        properties.sort((a, b) => a.name.compareTo(b.name));
        break;
      case '월세순':
        properties.sort((a, b) {
          final rentA = _extractNumberFromString(a.rent);
          final rentB = _extractNumberFromString(b.rent);
          return rentA.compareTo(rentB);
        });
        break;
      case '별점순':
        properties.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case '보증금순':
        properties.sort((a, b) {
          final depositA = _extractNumberFromString(a.deposit);
          final depositB = _extractNumberFromString(b.deposit);
          return depositA.compareTo(depositB);
        });
        break;
      case '이름순':
        properties.sort((a, b) => a.name.compareTo(b.name));
        break;
      default:
        if (_selectedSort.contains('순')) {
          final sortField = _selectedSort.replaceAll('순', '');
          properties.sort((a, b) {
            final valueA = _getPropertyValueForPriority(sortField, a) ?? '';
            final valueB = _getPropertyValueForPriority(sortField, b) ?? '';
            return valueA.compareTo(valueB);
          });
        }
        break;
    }
  }

  int _extractNumberFromString(String text) {
    final regex = RegExp(r'\d+');
    final match = regex.firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 0;
    }
    return 0;
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('등록된 카드가 없습니다.',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          SizedBox(height: 8),
          Text('첫 번째 카드를 추가해보세요!',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('\'$_searchQuery\'에 대한 검색 결과가 없습니다.',
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('다른 검색어를 시도해보세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCardList(
      List<PropertyData> properties, Map<String, String> propertyChartMap) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: properties.length,
      shrinkWrap: false,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final property = properties[index];
        return _buildCardItem(property, propertyChartMap[property.id]);
      },
    );
  }

  Widget _buildCardItem(PropertyData property, String? chartId) {
    return Consumer(
      builder: (context, ref, child) {
        // final userPriorities = ref.watch(userPrioritiesProvider); // 현재 사용하지 않음

        return GestureDetector(
            onTap: () {
              context.goNamed(
                CardDetailScreen.routeName,
                pathParameters: {'cardId': property.id},
                extra: property,
              );
            },
            child: Card(
              key: ValueKey('card_item_${property.id}'),
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0, // 기본 elevation 제거
              color: Colors.transparent, // 기본 카드 색상 투명
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  border: Border.all(
                    color: (_selectedChartId == null && chartId != null && chartId.isNotEmpty)
                        ? _getChartColor(chartId).withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.04),
                    width: (_selectedChartId == null && chartId != null && chartId.isNotEmpty) ? 1.0 : 0.5,
                  ),
                  boxShadow: [
                    // 메인 그림자 - 더 강화
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    // 서브 그림자 - 더 부드럽게
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    // 디테일 그림자
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      property.name.isNotEmpty
                                          ? property.name
                                          : '부동산 정보',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (property.rating > 0) ...[
                                      Row(
                                        children: List.generate(5, (starIndex) {
                                          return Icon(
                                            starIndex < property.rating
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 20,
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (property.rent.isNotEmpty ||
                                        property.deposit.isNotEmpty) ...[
                                      Text(
                                        '월세: ${property.rent.isNotEmpty ? property.rent : '-'} | 보증금: ${property.deposit.isNotEmpty ? property.deposit : '-'}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              _buildPropertyThumbnail(property),
                            ],
                          ),
                          // 추가 정보 태그들을 항상 표시 (userPriorities 조건 제거)
                          const SizedBox(height: 8),
                          _buildPriorityTags(property),
                        ],
                      ),
                    ),
                    // 순번 필드 제거됨
                  ],
                ),
              ),
            ));
      },
    );
  }

  Widget _buildPriorityTags(PropertyData property) {
    return Consumer(
      builder: (context, ref, child) {
        final realtimeChartList = ref.watch(propertyChartListProvider);

        PropertyChartModel? currentChart;
        for (var chart in realtimeChartList) {
          if (chart.properties.any((p) => p.id == property.id)) {
            currentChart = chart;
            break;
          }
        }
        
        // 디버깅용 로그
        AppLogger.d('PropertyData ID: ${property.id}');
        AppLogger.d('Found chart: ${currentChart?.title ?? "없음"}');
        AppLogger.d('Chart columnVisibility: ${currentChart?.columnVisibility}');

        List<Widget> tags = [];
        Set<String> addedTags = {};

        const fixedItems = {'집 이름', '월세', '보증금', '순'};

        final visibilityMap = currentChart?.columnVisibility;
        
        List<String> visibleColumns = [];
        
        if (visibilityMap != null && visibilityMap.isNotEmpty) {
          visibleColumns = visibilityMap.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key)
              .where((column) => !fixedItems.contains(column))
              .take(6)
              .toList();
        } else {
          // 기본 표시 컬럼들 (columnVisibility가 설정되지 않은 경우)
          final defaultColumns = ['주거 형태', '재계/방향', '집주인 환경', '주소'];
          visibleColumns = defaultColumns
              .where((column) => !fixedItems.contains(column))
              .take(6)
              .toList();
          AppLogger.d('기본 컬럼 사용: $visibleColumns');
        }

        for (String column in visibleColumns) {
          if (addedTags.contains(column)) continue;

          String? value = _getColumnValueForProperty(column, property);
          AppLogger.d('컬럼: $column, 값: $value');

          final displayValue =
              (value != null && value.isNotEmpty && value != '-')
                  ? value
                  : '미입력';

          addedTags.add(column);
          tags.add(
            Text(
              '$column: $displayValue',
              style: TextStyle(
                fontSize: 14,
                color: (value != null && value.isNotEmpty && value != '-')
                    ? Colors.grey[600]
                    : Colors.orange[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          );
        }

        if (tags.isEmpty) return const SizedBox.shrink();

        final tagTexts = <String>[];

        for (int i = 0; i < tags.length; i++) {
          final tag = tags[i] as Text;
          final text = tag.data!;
          tagTexts.add(text);
        }

        final combinedText = tagTexts.join(' | ');

        return Text(
          combinedText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          maxLines: 3,
          overflow: TextOverflow.visible,
        );
      },
    );
  }

  String? _getColumnValueForProperty(String columnName, PropertyData property) {
    final columnKey = _getColumnDataKey(columnName);
    
    if (columnKey['type'] == 'base') {
      // Handle base columns directly from PropertyData fields
      switch (columnKey['key']) {
        case 'name':
          return property.name.isNotEmpty ? property.name : '부동산 정보';
        case 'deposit':
          return property.deposit;
        case 'rent':
          return property.rent;
        case 'address':
          return property.address;
        case 'direction':
          return property.direction;
        case 'landlordEnvironment':
          return property.landlordEnvironment;
        case 'rating':
          return property.rating > 0 ? property.rating.toString() : null;
        default:
          return null;
      }
    } else {
      // Handle additional columns from additionalData
      return property.additionalData[columnKey['key']];
    }
  }


  // Column data key mapping - copied from chart screen
  Map<String, String> _getColumnDataKey(String columnName) {
    // Base columns map directly to PropertyData fields
    const baseColumnKeys = {
      '집 이름': 'name',
      '보증금': 'deposit',
      '월세': 'rent',
      '주소': 'address',
      '재계/방향': 'direction',
      '집주인 환경': 'landlordEnvironment',
      '별점': 'rating',
    };

    // Standard columns stored in additionalData with fixed keys
    const standardColumnKeys = {
      '주거 형태': 'housing_type',
      '건축물용도': 'building_use',
      '임차권등기명령 이력': 'lease_registration',
      '근저당권': 'mortgage',
      '가압류, 압류, 경매 이력': 'seizure_history',
      '계약 조건': 'contract_conditions',
      '등기부등본(말소사항 포함으로)': 'property_register',
      '입주 가능일': 'move_in_date',
      '전입신고': 'resident_registration',
      '관리비': 'maintenance_fee',
      '주택보증보험': 'housing_insurance',
      '특약': 'special_terms',
      '특이사항': 'special_notes',
      '평수': 'area',
      '방개수': 'room_count',
      '방구조': 'room_structure',
      '창문 뷰': 'window_view',
      '방향(나침반)': 'compass_direction',
      '채광': 'lighting',
      '층수': 'floor',
      '엘리베이터': 'elevator',
      '에어컨 방식': 'air_conditioning',
      '난방방식': 'heating',
      '베란다': 'veranda',
      '발코니': 'balcony',
      '주차장': 'parking',
      '화장실': 'bathroom',
      '가스': 'gas_type',
      '지하철 거리': 'subway_distance',
      '버스 정류장': 'bus_distance',
      '편의점 거리': 'convenience_store',
      '위치': 'location_type',
      'cctv 여부': 'cctv',
      '창문 상태': 'window_condition',
      '문 상태': 'door_condition',
      '집주인 성격': 'landlord_environment',
      '집주인 거주': 'landlord_residence',
      '집근처 술집': 'nearby_bars',
      '저층 방범창': 'security_bars',
      '집주변 낮분위기': 'day_atmosphere',
      '집주변 밤분위기': 'night_atmosphere',
      '2종 잠금장치': 'double_lock',
      '집 근처 소음원': 'noise_source',
      '실내소음': 'indoor_noise',
      '이중창(소음, 외풍)': 'double_window',
      '창문 밀폐(미세먼지)': 'window_seal',
      '수압': 'water_pressure',
      '누수': 'water_leak',
      '에어컨 내부 곰팡이': 'ac_mold',
      '에어컨 냄새': 'ac_smell',
      '환기(공기순환)': 'ventilation',
      '곰팡이(벽,화장실,베란다)': 'mold',
      '냄새': 'smell',
      '벌레(바퀴똥)': 'insects',
      '몰딩': 'molding',
      '창문': 'window_film',
      '관련 링크': 'related_links',
      '부동산 정보': 'real_estate_info',
      '집주인 정보': 'landlord_info',
      '집보여준자': 'agent_check',
      '메모': 'memo',
    };

    if (baseColumnKeys.containsKey(columnName)) {
      return {'type': 'base', 'key': baseColumnKeys[columnName]!};
    } else if (standardColumnKeys.containsKey(columnName)) {
      return {'type': 'additional', 'key': standardColumnKeys[columnName]!};
    } else {
      // Custom columns use custom_ prefix
      final safeKey = columnName.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '_');
      return {'type': 'additional', 'key': 'custom_$safeKey'};
    }
  }

  String? _getPropertyValueForPriority(String priority, PropertyData property) {
    switch (priority) {
      case '월세':
      case '월세비용':
        return property.rent;
      case '보증금':
        return property.deposit;
      case '방향':
      case '재계/방향':
        return property.direction;
      case '집주인 환경':
      case '환경':
        return property.landlordEnvironment;
      case '별점':
      case '평점':
        return property.rating > 0 ? property.rating.toString() : null;
      case '집 이름':
      case '이름':
        return property.name;
      default:
        return property.additionalData[priority];
    }
  }

  void _showCreateChartDialog() {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 8,
          title: Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFFFFECE0), width: 2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_chart,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                const Text(
                  '새 차트 만들기',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242)),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECE0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '새 차트를 만든 후, 카드를 추가하여 부동산 정보를 입력할 수 있습니다.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6D4C41)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '차트 제목',
                  labelStyle: const TextStyle(color: Color(0xFFFF8A65)),
                  hintText: '예: 강남구 원룸, 2024년 부동산 목록',
                  hintStyle: const TextStyle(color: Color(0xFFBCAAA4)),
                  prefixIcon: const Icon(Icons.title, color: Color(0xFFFF8A65)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFFFFCCBC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide:
                        const BorderSide(color: Color(0xFFFF8A65), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFFFFCCBC)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFF8F5),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('취소',
                  style: TextStyle(
                      color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isNotEmpty) {
                    await _createNewChart(titleController.text.trim());
                    if (ctx.mounted) Navigator.of(ctx).pop(); // 새 차트 만들기 다이얼로그 닫기

                    // 잠시 후 차트 선택 다이얼로그 다시 열기
                    final timer = Timer(const Duration(milliseconds: 300), () {
                      _showChartSelectionDialog();
                    });
                    _timers.add(timer);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '"${titleController.text.trim()}" 차트가 생성되었습니다.',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        backgroundColor: const Color(0xFFFF8A65),
                        duration: const Duration(milliseconds: 1000),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(16),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('만들기',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewChart(String title) async {
    // 기본 컬럼 가시성 설정 (필수 컬럼만 true로 설정)
    final Map<String, bool> defaultColumnVisibility = {
      '집 이름': true,
      '월세': true,
      '보증금': true,
      // 다른 모든 컬럼은 false로 기본 설정됨
    };

    final newChart = PropertyChartModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: DateTime.now(),
      properties: [],
      columnVisibility: defaultColumnVisibility,
    );

    final integratedService = ref.read(integratedChartServiceProvider);
    await integratedService.saveChart(newChart);

    // 새로 만든 차트를 선택된 상태로 설정
    setState(() {
      _selectedChartId = newChart.id;
    });
  }

  void _showChartSelectionDialog() {
    final chartList = ref.watch(propertyChartListProvider);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          elevation: 8,
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 400,
            height: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // 헤더
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF8A65),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.white, size: 22),
                      SizedBox(width: 16),
                      Text(
                        '차트 선택',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECE0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '카드를 추가할 차트를 선택하거나 새 차트를 만드세요.',
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF6D4C41)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 새 차트 만들기 버튼
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8A65)
                                    .withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _showCreateChartDialog();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('새 차트 만들기',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        // 기존 차트 목록
                        Expanded(
                          child: chartList.isEmpty
                              ? const Center(
                                  child: Text(
                                    '차트가 없습니다.\n새 차트를 만들어보세요!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: chartList.length,
                                  itemBuilder: (context, index) {
                                    final chart = chartList[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFECE0),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.analytics,
                                              color: Color(0xFFFF8A65)),
                                        ),
                                        title: Text(
                                          chart.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          '${chart.properties.length}개 카드 • ${chart.date.year}.${chart.date.month}.${chart.date.day}',
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                        trailing: const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey),
                                        onTap: () {
                                          Navigator.of(ctx).pop();
                                          _navigateToCardDetail(chart.id);
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 하단 버튼
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('취소',
                            style: TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToCardDetail(String chartId) {
    // 새로운 부동산 데이터 생성
    final newProperty = PropertyData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '',
      deposit: '',
      rent: '',
      direction: '',
      landlordEnvironment: '',
      rating: 0,
      additionalData: {},
    );

    // 카드 상세페이지로 이동
    context.goNamed(
      CardDetailScreen.routeName,
      pathParameters: {'cardId': newProperty.id},
      extra: {
        'property': newProperty,
        'chartId': chartId,
        'isNewProperty': true,
      },
    );
  }

  Widget _buildPropertyThumbnail(PropertyData property) {
    // 갤러리 이미지 가져오기
    List<String> allImages = property.cellImages['gallery'] ?? [];

    // cellImages Map에서 차트 셀 이미지들 추가
    final Map<String, List<String>> cellImages = property.cellImages;
    cellImages.forEach((key, images) {
      if (key != 'gallery' && key.endsWith('_images') && images.isNotEmpty) {
        allImages.addAll(images);
      }
    });

    // additionalData에서 차트 셀 이미지들도 추가 (JSON 디코딩)
    final Map<String, String> additionalData = property.additionalData;
    additionalData.forEach((key, value) {
      if (key.endsWith('_images') && value.isNotEmpty) {
        try {
          final List<dynamic> imageList = jsonDecode(value);
          final List<String> images = imageList.cast<String>();
          allImages.addAll(images);
        } catch (e) {
          // JSON 디코딩 실패시 무시
        }
      }
    });

    // 중복 제거
    allImages = allImages.toSet().toList();

    // 디버깅을 위한 로그
    AppLogger.d('Property ${property.id} - All images: $allImages');
    AppLogger.d('Property cellImages keys: ${property.cellImages.keys}');

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: allImages.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.file(
                File(allImages[0]),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[400],
                      size: 32,
                    ),
                  );
                },
              ),
            )
          : Icon(
              Icons.home,
              color: Colors.grey[400],
              size: 38,
            ),
    );
  }
}
