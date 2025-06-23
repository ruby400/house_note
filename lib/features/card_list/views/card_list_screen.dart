import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:house_note/data/models/user_model.dart'; // 사용되지 않으므로 제거
import 'package:house_note/providers/user_providers.dart';
import 'package:house_note/core/utils/logger.dart';
import 'package:house_note/features/card_list/views/card_detail_screen.dart';
import 'package:house_note/data/models/property_chart_model.dart';
import 'package:house_note/providers/property_chart_providers.dart';
import 'package:house_note/features/onboarding/views/interactive_guide_overlay.dart';

class CardListScreen extends ConsumerStatefulWidget {
  static const routeName = 'card-list';
  static const routePath = '/cards';
  static final GlobalKey bottomNavKey = GlobalKey(); // 하단바용 GlobalKey

  const CardListScreen({super.key});

  @override
  ConsumerState<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends ConsumerState<CardListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSort = '최신순'; // 기본 정렬 방식
  String? _selectedChartId; // 선택된 차트 ID
  String _searchQuery = ''; // 검색어
  // 재할당되지 않으므로 final로 변경
  final List<String> _customSortOptions = ['최신순', '거리순', '월세순']; // 사용자 정의 정렬 옵션
  
  // 가이드용 GlobalKey들
  final GlobalKey _addButtonKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _filterKey = GlobalKey();
  final GlobalKey _newCardButtonKey = GlobalKey();
  final GlobalKey _chartFilterKey = GlobalKey();
  final GlobalKey _sortAddButtonKey = GlobalKey();
  final GlobalKey _cardItemKey = GlobalKey();
  final GlobalKey _clearButtonKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showInteractiveGuide() {
    final steps = [
      GuideStep(
        title: '매물 추가',
        description: '+ 버튼 눌러서 매물 추가 가능',
        targetKey: _addButtonKey,
        icon: Icons.add_circle,
        tooltipPosition: GuideTooltipPosition.top,
      ),
      GuideStep(
        title: '새카드 만들기',
        description: '버튼 눌러서 새 차트에 매물 추가 가능',
        targetKey: _newCardButtonKey,
        icon: Icons.add_card,
        tooltipPosition: GuideTooltipPosition.bottom,
      ),
      GuideStep(
        title: '매물 편집',
        description: '카드 눌러서 상세정보 편집 가능',
        targetKey: _cardItemKey,
        icon: Icons.edit,
        tooltipPosition: GuideTooltipPosition.bottom,
      ),
      GuideStep(
        title: '이미지 추가',
        description: '상세화면에서 이미지 추가/삭제 가능',
        targetKey: _cardItemKey,
        icon: Icons.photo_library,
        tooltipPosition: GuideTooltipPosition.bottom,
      ),
      GuideStep(
        title: '실시간 검색',
        description: '검색창에서 매물명, 가격, 위치 검색 가능',
        targetKey: _searchKey,
        icon: Icons.search,
        tooltipPosition: GuideTooltipPosition.bottom,
      ),
      GuideStep(
        title: '검색 초기화',
        description: 'X 버튼 눌러서 검색어 지우기 가능',
        targetKey: _clearButtonKey,
        icon: Icons.clear,
        tooltipPosition: GuideTooltipPosition.bottom,
      ),
      GuideStep(
        title: '정렬 기능',
        description: '최신순, 월세순 등 정렬 옵션 선택 가능',
        targetKey: _filterKey,
        icon: Icons.sort,
        tooltipPosition: GuideTooltipPosition.bottom,
      ),
      GuideStep(
        title: '정렬 추가',
        description: '사용자 정의 정렬 방식 추가 가능',
        targetKey: _sortAddButtonKey,
        icon: Icons.add_box,
        tooltipPosition: GuideTooltipPosition.bottom,
      ),
      GuideStep(
        title: '차트 필터',
        description: '원하는 차트만 선택해서 보기 가능',
        targetKey: _chartFilterKey,
        icon: Icons.filter_alt,
        tooltipPosition: GuideTooltipPosition.bottom,
      ),
      GuideStep(
        title: '탭 이동',
        description: '하단 탭 눌러서 다른 화면 이동 가능',
        targetKey: CardListScreen.bottomNavKey,
        icon: Icons.navigation,
        tooltipPosition: GuideTooltipPosition.top,
      ),
    ];

    InteractiveGuideManager.showGuide(
      context,
      steps: steps,
      onCompleted: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('가이드가 완료되었습니다!'),
            backgroundColor: Color(0xFFFF8A65),
          ),
        );
      },
      onSkipped: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('가이드를 건너뛰었습니다.'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
            onPressed: () => _showInteractiveGuide(),
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
                        key: _filterKey,
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
                              });
                            }
                          }
                        },
                        child: Container(
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
                                color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
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
                          _showChartSelectionDialog();
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
                                color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
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
                  propertyList.addAll(selectedChart.properties);
                } else {
                  // 모든 차트의 부동산 데이터를 하나의 리스트로 합치기
                  for (final chart in chartList) {
                    propertyList.addAll(chart.properties);
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

                // 선택된 정렬 방식에 따라 정렬
                _sortPropertyList(propertyList);

                if (propertyList.isEmpty) {
                  return _searchQuery.isNotEmpty
                      ? _buildNoSearchResults()
                      : _buildEmptyState();
                }
                return _buildCardList(propertyList);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: _addButtonKey,
        onPressed: () {
          _showChartSelectionDialog();
        },
        backgroundColor: const Color(0xFFFF8A65),
        child: const Icon(
          Icons.add,
          color: Colors.white,
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

  Widget _buildCardList(List<PropertyData> properties) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: properties.length,
      shrinkWrap: false,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final property = properties[index];
        return _buildCardItem(property);
      },
    );
  }

  Widget _buildCardItem(PropertyData property) {
    return Consumer(
      builder: (context, ref, child) {
        final userPriorities = ref.watch(userPrioritiesProvider);

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
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
                                      : '부동산 ${property.order}',
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
                      if (userPriorities.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildPriorityTags(property),
                      ],
                    ],
                  ),
                ),
                if (property.order.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '순번: ${property.order}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
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

        List<Widget> tags = [];
        Set<String> addedTags = {};

        const fixedItems = {'집 이름', '월세', '보증금', '순'};

        final visibilityMap = currentChart?.columnVisibility;

        if (visibilityMap != null && visibilityMap.isNotEmpty) {
          final visibleColumns = visibilityMap.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key)
              .where((column) => !fixedItems.contains(column))
              .take(6)
              .toList();

          for (String column in visibleColumns) {
            if (addedTags.contains(column)) continue;

            String? value = _getColumnValueForProperty(column, property);

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
    switch (columnName) {
      case '집 이름':
        return property.name.isNotEmpty
            ? property.name
            : '부동산 ${property.order}';
      case '보증금':
        return property.deposit;
      case '월세':
        return property.rent;
      case '재계/방향':
        return property.direction;
      case '집주인 환경':
        return property.landlordEnvironment;
      case '별점':
        return property.rating > 0 ? property.rating.toString() : null;
      case '주거형태':
      case '건축물용도':
      case '임차권 등기명령 이력여부':
      case '수도 수납':
      case '공광비':
      case '재산/방화':
      case '소음':
      case '편의점':
      default:
        return _getAdditionalDataByColumnName(columnName, property);
    }
  }

  String? _getAdditionalDataByColumnName(
      String columnName, PropertyData property) {
    const columnIndexMap = {
      '집 이름': 1,
      '보증금': 2,
      '월세': 3,
      '주거형태': 4,
      '건축물용도': 5,
      '임차권 등기명령 이력여부': 6,
      '재계/방향': 7,
      '집주인 환경': 8,
      '별점': 9,
      '수도 수납': 10,
      '공광비': 11,
      '재산/방화': 12,
      '소음': 13,
      '편의점': 14,
    };

    final columnIndex = columnIndexMap[columnName];
    if (columnIndex != null && columnIndex >= 7) {
      final dataKey = 'col_$columnIndex';
      return property.additionalData[dataKey];
    }

    return property.additionalData[columnName];
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
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    _createNewChart(titleController.text.trim());
                    Navigator.of(ctx).pop(); // 새 차트 만들기 다이얼로그 닫기
                    
                    // 잠시 후 차트 선택 다이얼로그 다시 열기
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _showChartSelectionDialog();
                    });
                    
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

  void _createNewChart(String title) {
    final newChart = PropertyChartModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: DateTime.now(),
      properties: [],
    );

    ref.read(propertyChartListProvider.notifier).addChart(newChart);

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
            height: 450,
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
                            style: TextStyle(fontSize: 14, color: Color(0xFF6D4C41)),
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
                          color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
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
                              color: Colors.white, fontWeight: FontWeight.bold)),
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
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFECE0),
                                    borderRadius: BorderRadius.circular(8),
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
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Colors.grey),
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('취소',
                            style: TextStyle(
                                color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600)),
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
      order: '1',
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
