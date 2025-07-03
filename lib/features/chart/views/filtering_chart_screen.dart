import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/core/utils/logger.dart';
import 'package:house_note/data/models/property_chart_model.dart';
import 'package:house_note/providers/property_chart_providers.dart';
import 'package:house_note/providers/firebase_chart_providers.dart';
import 'package:house_note/features/chart/views/image_manager_widgets.dart';
import 'package:house_note/features/chart/views/column_sort_filter_bottom_sheet.dart';
import 'package:house_note/features/onboarding/views/interactive_guide_overlay.dart';
import 'dart:convert';

// 업데이트 결과를 위한 헬퍼 클래스
class _UpdateResult {
  final bool success;
  final PropertyChartModel? updatedChart;
  final String? errorMessage;

  _UpdateResult.success(this.updatedChart)
      : success = true,
        errorMessage = null;

  _UpdateResult.failure(this.errorMessage)
      : success = false,
        updatedChart = null;
}

class FilteringChartScreen extends ConsumerStatefulWidget {
  static const routeName = 'filtering-chart';
  static const routePath = ':chartId';

  final String chartId;

  const FilteringChartScreen({
    super.key,
    required this.chartId,
  });

  @override
  ConsumerState<FilteringChartScreen> createState() =>
      _FilteringChartScreenState();
}

class _FilteringChartScreenState extends ConsumerState<FilteringChartScreen> {
  // 튜토리얼 관련
  final GlobalKey _tableKey = GlobalKey();
  final GlobalKey _addColumnKey = GlobalKey();
  final GlobalKey _addRowKey = GlobalKey();
  final GlobalKey _filterKey = GlobalKey();
  final GlobalKey _titleKey = GlobalKey();
  
  // 실제 체험형 튜토리얼 상태 추적
  bool _hasClickedCell = false;
  bool _hasAddedColumn = false;
  bool _hasAddedRow = false;
  bool _hasUsedSort = false;
  bool _hasEditedTitle = false;
  
  // 바텀시트 상태 추적 (충돌 회피용)
  bool _isBottomSheetVisible = false;

  // 각 컬럼별 기본 메뉴 옵션 정의 (카드 상세페이지와 동일하게 수정)
  final Map<String, List<String>> _columnDefaultOptions = {
    '주거 형태': ['빌라', '오피스텔', '아파트', '근린생활시설'],
    '건축물용도': ['주거용', '상업용', '혼용'],
    '임차권등기명령 이력': ['있음', '없음'],
    '근저당권': ['있음', '없음'],
    '가압류, 압류, 경매 이력': ['있음', '없음'],
    '계약 조건': ['월세', '전세', '반전세'],
    '등기부등본(말소사항 포함으로)': ['확인완료', '미확인'],
    '입주 가능일': ['즉시', '협의', '1주일후', '2주일후', '1개월후'],
    '전입신고': ['가능', '불가능'],
    '관리비': ['없음', '3만원', '5만원', '7만원', '10만원', '15만원', '20만원'],
    '주택보증보험': ['가능', '불가능'],
    '특약': ['있음', '없음'],
    '특이사항': ['없음', '있음'],
    '평수': ['10평대', '15평대', '20평대', '25평대', '30평대 이상'],
    '방개수': ['원룸', '1개', '2개', '3개', '4개 이상'],
    '방구조': ['원룸', '1.5룸', '다각형방', '복도형'],
    '창문 뷰': ['뻥뷰', '막힘', '옆건물 가까움', '마주보는 건물', '벽뷰'],
    '방향(나침반)': ['정남', '정동', '정서', '정북', '남서', '남동', '동남', '동북', '북동', '북서'],
    '채광': ['매우좋음', '좋음', '보통', '어두움', '매우어두움'],
    '층수': ['지하', '반지하', '1층', '2층', '3층', '4층', '5층이상'],
    '엘리베이터': ['있음', '없음'],
    '에어컨 방식': ['천장형', '벽걸이', '중앙냉방'],
    '난방방식': ['보일러', '심야전기', '중앙난방'],
    '베란다': ['있음', '없음'],
    '발코니': ['있음', '없음'],
    '주차장': ['기계식', '지하주차장', '지상주차장', '노상주차'],
    '화장실': ['독립', '공용'],
    '가스': ['도시가스', 'lpg가스'],
    '지하철 거리': ['5분거리', '10분거리', '15분거리', '20분거리'],
    '버스 정류장': ['5분거리', '10분거리', '15분거리', '20분거리'],
    '편의점 거리': ['5분거리', '10분거리', '15분거리', '20분거리'],
    '위치': ['차도', '대로변', '골목길'],
    'cctv 여부': ['1층만', '각층', '없음'],
    '창문 상태': ['철제창', '나무창'],
    '문 상태': ['삐그덕댐', '잘안닫침', '잘닫침'],
    '집주인 성격': ['이상함', '별로', '좋은것같음'],
    '집주인 거주': ['있음', '없음'],
    '집근처 술집': ['있음', '없음'],
    '저층 방범창': ['있음', '없음'],
    '집주변 낮분위기': ['을씨년스러움', '사람들 많이다님', '사람들 안다님', '평범함', '분위기 좋음', '따뜻함'],
    '집주변 밤분위기': ['을씨년스러움', '무서움', '스산함', '평범함', '사람들 많이다님', '사람들 안다님'],
    '2종 잠금장치': ['있음', '없음', '설치해준다함'],
    '집 근처 소음원': ['공장', '공사장', '폐기장', '고물상', '큰 도로', '없음'],
    '실내소음': ['있음', '없음', '가벽'],
    '이중창(소음, 외풍)': ['있음', '없음'],
    '창문 밀폐(미세먼지)': ['있음', '없음'],
    '수압': ['약함', '보통', '강함'],
    '누수': ['없음', '있음'],
    '에어컨 내부 곰팡이': ['있음', '없음'],
    '에어컨 냄새': ['있음', '없음'],
    '환기(공기순환)': ['됨', '안됨'],
    '곰팡이(벽,화장실,베란다)': ['있음', '없음'],
    '냄새': ['이상함', '퀘퀘함', '담배냄새', '없음'],
    '벌레(바퀴똥)': ['서랍', '씽크대 하부장 모서리', '씽크대 상부장', '없음'],
    '몰딩': ['체리몰딩', '화이트몰딩', '없음', '나무'],
    '창문': ['난초그림시트', '격자무늬 시트지', '네모패턴시트지', '없음'],
    '관련 링크': ['있음', '없음'],
    '부동산 정보': ['확인완료', '미확인'],
    '집주인 정보': ['확인완료', '미확인'],
    '집보여준자': ['중개사', '중개보조인', '미확인'],
    '메모': ['없음', '있음'],
  };

  // 확장된 컬럼 정의 (카드 상세페이지와 완전히 동일하게) - 제목은 고정 컬럼이므로 제외
  List<String> _columns = [
    '집 이름',
    '보증금',
    '월세',
    '주소',
    '주거 형태',
    '건축물용도',
    '임차권등기명령 이력',
    '근저당권',
    '가압류, 압류, 경매 이력',
    '계약 조건',
    '등기부등본(말소사항 포함으로)',
    '입주 가능일',
    '전입신고',
    '관리비',
    '주택보증보험',
    '특약',
    '특이사항',
    '평수',
    '방개수',
    '방구조',
    '창문 뷰',
    '방향(나침반)',
    '채광',
    '층수',
    '엘리베이터',
    '에어컨 방식',
    '난방방식',
    '베란다',
    '발코니',
    '주차장',
    '화장실',
    '가스',
    '지하철 거리',
    '버스 정류장',
    '편의점 거리',
    '위치',
    'cctv 여부',
    '창문 상태',
    '문 상태',
    '집주인 성격',
    '집주인 거주',
    '집근처 술집',
    '저층 방범창',
    '집주변 낮분위기',
    '집주변 밤분위기',
    '2종 잠금장치',
    '집 근처 소음원',
    '실내소음',
    '이중창(소음, 외풍)',
    '창문 밀폐(미세먼지)',
    '수압',
    '누수',
    '에어컨 내부 곰팡이',
    '에어컨 냄새',
    '환기(공기순환)',
    '곰팡이(벽,화장실,베란다)',
    '냄새',
    '벌레(바퀴똥)',
    '몰딩',
    '창문',
    '관련 링크',
    '부동산 정보',
    '집주인 정보',
    '집보여준자',
    '별점',
    '메모'
  ];

  // 기본 컬럼 목록 (삭제할 수 없는 컬럼들)
  final Set<String> _baseColumns = {'집 이름', '보증금', '월세', '주소', '별점'};

  // 컬럼명을 데이터 키로 매핑 (인덱스 대신 컬럼명 사용)
  Map<String, String> _getColumnDataKey(String columnName) {
    // 진짜 기본 컬럼들만 base로 처리 (PropertyData의 기본 필드들)
    const baseColumnKeys = {
      '집 이름': 'name',
      '보증금': 'deposit',
      '월세': 'rent',
      '주소': 'address',
      '재계/방향': 'direction',
      '집주인 환경': 'landlordEnvironment',
      '별점': 'rating',
    };

    // 표준 항목들은 additionalData에 저장되지만 고정된 키 사용
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
      // 완전히 새로운 컬럼은 custom_ 접두사 사용
      final safeKey = columnName.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '_');
      return {'type': 'additional', 'key': 'custom_$safeKey'};
    }
  }

  // 현재 차트 데이터 (Provider에서 관리)
  PropertyChartModel? _currentChart;

  // 가로 스크롤 컨트롤러 (헤더와 바디 동기화용)
  late ScrollController _horizontalController;

  // 세로 스크롤 컨트롤러 (순번 컬럼과 데이터 동기화용)
  late ScrollController _verticalController;
  late ScrollController _dataVerticalController;

  // 카테고리 헤더 스크롤 컨트롤러

  // 카테고리 정의 (카드 상세페이지와 완전히 동일하게 수정)
  final Map<String, List<String>> _categoryGroups = {
    '💰 필수정보': [
      '집 이름',
      '보증금',
      '월세',
      '주소',
      '주거 형태',
      '건축물용도',
      '임차권등기명령 이력',
      '근저당권',
      '가압류, 압류, 경매 이력',
      '계약 조건',
      '등기부등본(말소사항 포함으로)',
      '입주 가능일',
      '전입신고',
      '관리비',
      '주택보증보험',
      '특약',
      '특이사항'
    ],
    '🏠 부동산 상세 정보': [
      '평수',
      '방개수',
      '방구조',
      '창문 뷰',
      '방향(나침반)',
      '채광',
      '층수',
      '엘리베이터',
      '에어컨 방식',
      '난방방식',
      '베란다',
      '발코니',
      '주차장',
      '화장실',
      '가스'
    ],
    '🚇 교통 및 편의시설': [
      '지하철 거리',
      '버스 정류장',
      '편의점 거리'
    ],
    '🔒 치안 관련': [
      '위치',
      'cctv 여부',
      '창문 상태',
      '문 상태',
      '집주인 성격',
      '집주인 거주',
      '집근처 술집',
      '저층 방범창',
      '집주변 낮분위기',
      '집주변 밤분위기',
      '2종 잠금장치'
    ],
    '🧽 환경 및 청결': [
      '집 근처 소음원',
      '실내소음',
      '이중창(소음, 외풍)',
      '창문 밀폐(미세먼지)',
      '수압',
      '누수',
      '에어컨 내부 곰팡이',
      '에어컨 냄새',
      '환기(공기순환)',
      '곰팡이(벽,화장실,베란다)',
      '냄새',
      '벌레(바퀴똥)'
    ],
    '🎨 미관 및 기타': [
      '몰딩',
      '창문',
      '관련 링크',
      '부동산 정보',
      '집주인 정보',
      '집보여준자',
      '별점',
      '메모'
    ],
  };

  // 카테고리별 토글 상태 (기본적으로 모두 펼쳐짐)
  final Map<String, bool> _categoryExpanded = {
    '💰 필수정보': true,
    '🏠 부동산 상세 정보': true,
    '🚇 교통 및 편의시설': true,
    '🔒 치안 관련': true,
    '🧽 환경 및 청결': true,
    '🎨 미관 및 기타': true,
  };

  // 컬럼 가시성 상태 관리
  final Map<String, bool> _columnVisibility = {};

  // 정렬 및 필터링 상태 관리
  String? _sortColumn;
  bool _sortAscending = true;
  final Map<String, dynamic> _filters = {};

  // 항목별 가중치 저장 (기본값 3점)
  final Map<String, int> _itemWeights = {};
  final Map<String, List<String>> _customSortOrders = {};

  // 확장된 컬럼별 바텀시트 타입 정의
  final Map<String, String> _columnTypes = {
    '집 이름': 'text',
    '보증금': 'price',
    '월세': 'price',
    '주거형태': 'select',
    '건축물용도': 'select',
    '임차권 등기명령 이력여부': 'select',
    '근저당권여부': 'select',
    '가압류나 압류이력여부': 'select',
    '계약조건': 'text',
    '등기부등본': 'select',
    '입주가능일': 'date',
    '전입신고 가능여부': 'select',
    '관리비': 'price',
    '주택보증보험가능여부': 'select',
    '특약': 'text',
    '특이사항': 'text',
    '재계/방향': 'direction',
    '집주인 환경': 'environment',
    '별점': 'rating',
  };

  // 확장된 컬럼별 미리 설정된 옵션들
  final Map<String, List<String>> _columnOptions = {
    '재계/방향': ['동향', '서향', '남향', '북향', '동남향', '서남향', '동북향', '서북향'],
    '집 이름': ['강남 해피빌', '정우 오피스텔', '파인라인빌', '서라벌 오피스텔'],
    '보증금': ['1000', '2000', '3000', '5000', '10000'],
    '월세': ['30', '40', '50', '60', '70', '80', '90', '100'],
    '주거형태': ['원룸', '투룸', '쓰리룸', '오피스텔', '아파트', '빌라', '단독주택'],
    '평수': ['10평대', '15평대', '20평대', '25평대', '30평대 이상'],
    '방개수': ['원룸', '1개', '2개', '3개', '4개 이상'],
    '건축물용도': ['주거용', '상업용', '업무용', '혼용'],
    '임차권 등기명령 이력여부': ['있음', '없음', '확인중'],
    '근저당권여부': ['있음', '없음', '확인중'],
    '가압류나 압류이력여부': ['있음', '없음', '확인중'],
    '등기부등본': ['확인완료', '미확인', '문제있음'],
    '특약': ['있음', '없음'],
    '특이사항': ['없음', '있음'],
    '관련 링크': ['있음', '없음'],
    '부동산 정보': ['확인완료', '미확인'],
    '집주인 정보': ['확인완료', '미확인'],
    '집보여준자': ['중개사', '중개보조인', '미확인'],
    '메모': ['없음', '있음'],
    '전입신고 가능여부': ['가능', '불가능', '확인중'],
    '계약 조건': ['월세', '전세', '반전세'],
    '관리비': ['없음', '3만원', '5만원', '7만원', '10만원', '15만원', '20만원'],
    '입주 가능일': ['즉시', '협의', '1주일후', '2주일후', '1개월후'],
    '층수': ['지하', '반지하', '1층', '2층', '3층', '4층', '5층이상'],
    '채광': ['매우좋음', '좋음', '보통', '어두움', '매우어두움'],
    '주택보증보험가능여부': ['가능', '불가능', '확인중'],
    '집주인 환경': ['편리함', '보통', '불편함', '매우 좋음', '나쁨', '친절함', '무관심', '까다로움'],
    '별점': ['1', '2', '3', '4', '5'],
  };

  @override
  void initState() {
    super.initState();

    // 스크롤 컨트롤러 초기화
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
    _dataVerticalController = ScrollController();

    // 컬럼 가시성 초기화 (기본 컬럼들은 모두 표시)
    for (String column in _columns) {
      _columnVisibility[column] = true;
    }

    try {
      // 간소화된 차트 로딩
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadChart();
        }
      });
    } catch (e) {
      // 초기화 에러시 기본 차트 생성
      AppLogger.error('초기화 중 오류 발생', error: e);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _createDefaultChart();
        }
      });
    }
  }

  @override
  void dispose() {
    // 스크롤 컨트롤러 정리
    _horizontalController.dispose();
    _verticalController.dispose();
    _dataVerticalController.dispose();
    super.dispose();
  }

  // 스크롤 동기화 메서드
  void _synchronizeScrollOffset() {
    if (_verticalController.hasClients && _dataVerticalController.hasClients) {
      final offset = _verticalController.offset;
      if (_dataVerticalController.offset != offset) {
        _dataVerticalController.jumpTo(offset);
      }
    }
  }

  void _synchronizeDataScrollOffset() {
    if (_verticalController.hasClients && _dataVerticalController.hasClients) {
      final offset = _dataVerticalController.offset;
      if (_verticalController.offset != offset) {
        _verticalController.jumpTo(offset);
      }
    }
  }

  // 가로 스크롤 동기화 메서드 (카테고리 헤더와 메인 테이블)
  void _synchronizeHorizontalScroll() {
    // 카테고리 헤더가 메인 차트와 함께 스크롤되므로 동기화 불필요
  }

  // 카테고리 관련 헬퍼 메서드들
  List<String> _getVisibleColumns() {
    final visibleColumns = <String>[]; // 제목은 고정 컬럼이므로 제외

    // 사용자가 설정한 _columns 순서를 따르되, 카테고리 접기 상태를 고려
    // AppLogger.d('📋 _getVisibleColumns 호출, 현재 _columns: $_columns');
    for (final column in _columns) {

      // 해당 컬럼이 속한 카테고리 찾기
      String? belongsToCategory;
      for (final entry in _categoryGroups.entries) {
        if (entry.value.contains(column)) {
          belongsToCategory = entry.key;
          break;
        }
      }

      if (belongsToCategory != null) {
        final isExpanded = _categoryExpanded[belongsToCategory] ?? true;

        if (isExpanded) {
          // 펼쳐진 경우: 모든 컬럼 표시
          visibleColumns.add(column);
        } else {
          // 접힌 경우: 해당 카테고리의 첫 번째 컬럼만 표시
          final categoryColumns = _categoryGroups[belongsToCategory]!;
          final firstColumnInCategory = categoryColumns
              .firstWhere((col) => col != '제목', orElse: () => '');
          if (column == firstColumnInCategory) {
            visibleColumns.add(column);
          }
        }
      } else {
        // 카테고리에 속하지 않는 컬럼은 항상 표시
        visibleColumns.add(column);
      }
    }

    // AppLogger.d('📋 최종 visibleColumns: $visibleColumns');
    return visibleColumns;
  }

  void _toggleCategory(String categoryName) {
    setState(() {
      final isExpanded = _categoryExpanded[categoryName] ?? true;
      _categoryExpanded[categoryName] = !isExpanded;
      
      // 카테고리가 접혔을 때는 해당 카테고리의 컬럼들을 숨기고,
      // 펼쳐졌을 때는 다시 표시
      if (_categoryGroups.containsKey(categoryName)) {
        final categoryColumns = _categoryGroups[categoryName]!;
        for (final column in categoryColumns) {
          if (!isExpanded) {
            // 카테고리를 펼칠 때: 기본적으로 중요한 컬럼들만 표시
            _columnVisibility[column] = _isRequiredColumn(column);
          } else {
            // 카테고리를 접을 때: 해당 카테고리의 모든 컬럼 숨김
            _columnVisibility[column] = false;
          }
        }
        
        // 차트 업데이트
        if (_currentChart != null) {
          final updatedChart = _currentChart!.copyWith(
            columnVisibility: Map<String, bool>.from(_columnVisibility),
          );
          _currentChart = updatedChart;
          
          // 서버에 저장
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (mounted) {
              final integratedService = ref.read(integratedChartServiceProvider);
              await integratedService.saveChart(updatedChart);
              ref.read(currentChartProvider.notifier).setChart(updatedChart);
            }
          });
        }
      }
    });
  }





  void _loadChart() {
    if (!mounted) return;

    try {
      AppLogger.d('차트 로딩 시작 - chartId: ${widget.chartId}');

      // 입력값 검증
      if (widget.chartId.isEmpty || widget.chartId.trim().isEmpty) {
        AppLogger.warning('차트 ID가 비어있음');
        _createDefaultChart();
        return;
      }

      final chartList = ref.read(propertyChartListProvider);
      AppLogger.d('프로바이더에서 차트 목록 로드 완료 - 개수: ${chartList.length}');

      // 차트 목록 검증
      if (chartList.isEmpty) {
        AppLogger.info('차트 목록이 비어있습니다. 기본 차트를 생성합니다.');
        _createDefaultChart();
        return;
      }

      // 차트 목록에서 직접 검색
      final foundChart = chartList.firstWhere(
        (chart) => chart.id == widget.chartId,
        orElse: () => PropertyChartModel(
          id: '',
          title: '',
          date: DateTime.now(),
          properties: [],
        ),
      );

      if (foundChart.id.isEmpty) {
        AppLogger.warning('차트를 찾지 못함 (ID: ${widget.chartId})');
        AppLogger.d(
            '사용 가능한 차트 목록: ${chartList.map((c) => '${c.id}:${c.title}').toList()}');
        
        // 새로 생성된 차트라면 기본 차트를 생성 (첫 번째 빈 행 포함)
        final newChart = PropertyChartModel(
          id: widget.chartId,
          title: '새 차트',
          date: DateTime.now(),
          properties: [
            PropertyData(
              id: '1',
              name: '',
              deposit: '',
              rent: '',
              direction: '',
              landlordEnvironment: '',
              rating: 0,
              createdAt: DateTime.now(),
              cellImages: {},
            ),
          ], // 첫 번째 빈 행 추가
          columnOptions: _columnOptions,
        );
        
        setState(() {
          _currentChart = newChart;
        });
        
        // Provider에 차트 저장 (중복 추가 방지)
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            final integratedService = ref.read(integratedChartServiceProvider);
            await integratedService.saveChart(newChart);
            ref.read(currentChartProvider.notifier).setChart(newChart);
          }
        });
        return;
      }

      AppLogger.d('차트 발견 - ID: ${foundChart.id}, Title: ${foundChart.title}');

      // 찾은 차트를 그대로 사용 (빈 프로퍼티라도 기본 데이터 추가하지 않음)
      PropertyChartModel chartToUse = foundChart;

      // 안전한 상태 업데이트
      if (mounted) {
        setState(() {
          _currentChart = chartToUse;

          // 저장된 컬럼 순서가 있으면 적용 (제목과 순은 고정 컬럼이므로 제외)
          if (chartToUse.columnOrder != null &&
              chartToUse.columnOrder!.isNotEmpty) {
            // AppLogger.d('🔄 차트 로드 시 저장된 컬럼 순서 적용: ${chartToUse.columnOrder}');
            _columns = chartToUse.columnOrder!.where((column) => column != '제목' && column != '순').toList();
            // AppLogger.d('🔄 적용된 _columns: $_columns');
          } else {
            // AppLogger.d('⚠️ 저장된 컬럼 순서가 없음, 기본 순서 유지: $_columns');
          }

          // 기존 차트를 새로운 구조로 완전히 재구성
          _columnVisibility.clear();
          
          // 컬럼 가시성을 새로운 기준으로 초기화
          for (String column in _columns) {
            _columnVisibility[column] = _isRequiredColumn(column);
          }
          
          // 진짜 예시차트인지 확인 (구식 구조이면서 오래된 차트)
          bool isLegacyExampleChart = false;
          
          // 예시차트 판단 조건: 
          // 1. 컬럼 가시성이 없거나 너무 적음 (구식 구조)
          // 2. 차트가 충분히 오래됨 (새로 만든 차트가 아님)
          // 3. 제목이 기본 제목이거나 비어있음
          final isOldStructure = chartToUse.columnVisibility == null || 
                                chartToUse.columnVisibility!.length < 30;
          final isOldChart = DateTime.now().difference(chartToUse.date).inDays > 1;
          final hasDefaultTitle = chartToUse.title.isEmpty || 
                                 chartToUse.title == '새 차트' || 
                                 chartToUse.title == '새 부동산 차트' ||
                                 chartToUse.title.contains('부동산') ||
                                 chartToUse.title.contains('예시') ||
                                 chartToUse.title.contains('비교');
          
          if (isOldStructure && (isOldChart || hasDefaultTitle)) {
            isLegacyExampleChart = true;
            AppLogger.d('🏠 예시차트로 판단되어 예시 데이터와 함께 재구성합니다');
          }
          
          if (isLegacyExampleChart) {
            // 예시차트에만 예시 집 3개 데이터 생성
            final properties = _createSampleProperties();
            AppLogger.d('✨ 예시차트를 예시 데이터 3개와 함께 완전히 재구성합니다');
            
            final rebuiltChart = PropertyChartModel(
              id: chartToUse.id,
              title: chartToUse.title.isNotEmpty ? chartToUse.title : '부동산 비교 차트',
              date: chartToUse.date,
              properties: properties,
              columnOptions: _columnOptions,
              columnVisibility: Map<String, bool>.from(_columnVisibility),
              columnOrder: _columns,
            );
            
            _currentChart = rebuiltChart;
            
            // 재구성된 차트 저장
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                final integratedService = ref.read(integratedChartServiceProvider);
                await integratedService.saveChart(rebuiltChart);
              }
            });
          } else {
            // 예시차트가 아닌 일반 차트 처리
            if (chartToUse.columnVisibility != null) {
              _columnVisibility.addAll(chartToUse.columnVisibility!);
              
              // 컬럼 구조가 구식이면 컬럼만 업데이트 (데이터는 유지)
              if (chartToUse.columnVisibility!.length < 30) {
                AppLogger.d('🔄 일반 차트의 컬럼 구조를 업데이트합니다 (데이터 유지)');
                final updatedChart = chartToUse.copyWith(
                  columnVisibility: Map<String, bool>.from(_columnVisibility),
                  columnOrder: _columns,
                );
                _currentChart = updatedChart;
                
                // 업데이트된 차트 저장
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (mounted) {
                    final integratedService = ref.read(integratedChartServiceProvider);
                    await integratedService.saveChart(updatedChart);
                  }
                });
              }
            } else {
              // 컬럼 가시성 정보가 아예 없으면 기본값으로 초기화
              for (String column in _columns) {
                _columnVisibility[column] = _isRequiredColumn(column);
              }
            }
          }
        });

        // 프로바이더 상태 동기화
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _currentChart != null) {
            try {
              ref.read(currentChartProvider.notifier).setChart(_currentChart!);
              AppLogger.d('차트 로딩 및 프로바이더 동기화 완료');
            } catch (e) {
              AppLogger.error('프로바이더 동기화 실패', error: e);
            }
          }
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('_loadChart 중 오류 발생', error: e, stackTrace: stackTrace);
      if (mounted) {
        _createDefaultChart();
      }
    }
  }

  void _createDefaultChart() {
    if (!mounted) return;

    try {
      final chartId = widget.chartId.isNotEmpty
          ? widget.chartId
          : DateTime.now().millisecondsSinceEpoch.toString();
      // 필수 컬럼들('집 이름', '월세', '보증금')을 기본으로 표시하도록 설정
      Map<String, bool> defaultColumnVisibility = {};
      for (String column in _columns) {
        if (column != '순') {
          // '순' 컬럼은 항상 표시되므로 제외
          defaultColumnVisibility[column] = _isRequiredColumn(column);
        }
      }

      final defaultChart = PropertyChartModel(
        id: chartId,
        title: '새 부동산 차트',
        date: DateTime.now(),
        properties: [
          PropertyData(
            id: '1',
            name: '',
            deposit: '',
            rent: '',
            direction: '',
            landlordEnvironment: '',
            rating: 0,
            createdAt: DateTime.now(),
            cellImages: {},
          ),
        ], // 첫 번째 빈 행 추가
        columnOptions: _columnOptions,
        columnVisibility: defaultColumnVisibility,
      );

      setState(() {
        _currentChart = defaultChart;
        // _columnVisibility도 함께 초기화
        _columnVisibility.clear();
        _columnVisibility.addAll(defaultColumnVisibility);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          final integratedService = ref.read(integratedChartServiceProvider);
          await integratedService.saveChart(defaultChart);
          ref.read(currentChartProvider.notifier).setChart(defaultChart);
        }
      });
    } catch (e, stackTrace) {
      AppLogger.error('기본 차트 생성 실패', error: e, stackTrace: stackTrace);
      if (mounted) setState(() => _currentChart = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.d('Build: FilteringChartScreen');

    // 실시간으로 차트 데이터 감시하여 동기화
    final chartList = ref.watch(propertyChartListProvider);
    final latestChart = chartList.firstWhere(
      (chart) => chart.id == widget.chartId,
      orElse: () => PropertyChartModel(
        id: '',
        title: '',
        date: DateTime.now(),
        properties: [],
      ),
    );
    
    // 차트가 업데이트되었으면 현재 차트도 업데이트
    if (latestChart.id.isNotEmpty && _currentChart != null && latestChart != _currentChart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentChart = latestChart;
          });
        }
      });
    }

    if (_currentChart == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('차트 로딩 중...',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFAB91), // 밝은 주황색 (왼쪽 위)
                  Color(0xFFFF8A65), // 메인 주황색 (중간)
                  Color(0xFFFF7043), // 진한 주황색 (오른쪽 아래)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: GestureDetector(
          key: _titleKey,
          onTap: () {
            AppLogger.d('Title tapped - showing edit bottom sheet');
            _showEditTitleBottomSheet();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _currentChart!.title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.edit,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onSelected: (value) {
              if (value == 'interactive') {
                _showInteractiveChartGuide();
              } else if (value == 'demo') {
                _showTutorial();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'interactive',
                child: Row(
                  children: [
                    Icon(Icons.gamepad, size: 20),
                    SizedBox(width: 8),
                    Text('🎮 실제 체험 가이드'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'demo',
                child: Row(
                  children: [
                    Icon(Icons.play_circle, size: 20),
                    SizedBox(width: 8),
                    Text('🎬 자동 데모'),
                  ],
                ),
              ),
            ],
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
      body: Stack(
        children: [
          Column(
            children: [
              _buildSortingControls(),
              Expanded(child: Container(key: _tableKey, child: _buildEnhancedTable())),
            ],
          ),
          _buildFloatingAddRowButton(),
        ],
      ),
    );
  }

  void _saveCurrentChart() {
    if (_currentChart == null || !mounted) return;

    try {
      
      // 다음 프레임에서 Provider 업데이트를 수행하여 setState 중 수정 방지
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentChart != null) {
          try {
            // 현재 차트를 currentChartProvider에 업데이트
            ref.read(currentChartProvider.notifier).updateChart(_currentChart!);
            // Firebase 통합 서비스로 저장
            final integratedService = ref.read(integratedChartServiceProvider);
            integratedService.saveChart(_currentChart!);
          } catch (e) {
            // Provider 업데이트 실패시 사용자에게 알림
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('데이터 저장 중 오류가 발생했습니다: ${e.toString()}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(milliseconds: 800),
                ),
              );
            }
          }
        }
      });
    } catch (e) {
      // 전체 에러 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF8A65),
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  String _getCurrentCellValue(int rowIndex, int columnIndex) {
    if (_currentChart == null ||
        rowIndex < 0 ||
        columnIndex < 0 ||
        columnIndex >= _columns.length) {
      AppLogger.warning(
          '_getCurrentCellValue: Invalid parameters - row: $rowIndex, col: $columnIndex');
      return '';
    }

    // 빈 차트이거나 인덱스가 범위를 벗어나는 경우 빈 값 반환
    if (_currentChart!.properties.isEmpty || rowIndex >= _currentChart!.properties.length) {
      return '';
    }

    final property = _currentChart!.properties[rowIndex];
    final columnName = _columns[columnIndex];
    final columnKey = _getColumnDataKey(columnName);

    String value = '';

    if (columnKey['type'] == 'base') {
      // 기본 컬럼에서 값 가져오기
      switch (columnKey['key']) {
        case 'name':
          value = property.name;
          break;
        case 'deposit':
          value = property.deposit;
          break;
        case 'rent':
          value = property.rent;
          break;
        case 'address':
          value = property.address;
          // Debug: Address retrieval logging
          break;
        case 'direction':
          value = property.direction;
          break;
        case 'landlordEnvironment':
          value = property.landlordEnvironment;
          break;
        case 'rating':
          value = property.rating.toString();
          break;
      }
    } else {
      // 추가 컬럼에서 값 가져오기
      value = property.additionalData[columnKey['key']] ?? '';
    }

    AppLogger.d(
        '_getCurrentCellValue: Property ${property.id}, column: "$columnName" -> key: "${columnKey['key']}" -> value: "$value"');
    return value;
  }

  void _updateCellValue(int rowIndex, int columnIndex, String value) {
    // 기본 검증
    if (_currentChart == null || rowIndex < 0 || columnIndex < 0 || !mounted) {
      AppLogger.warning(
          'Debug: 기본 검증 실패 - chart: ${_currentChart != null}, row: $rowIndex, col: $columnIndex, mounted: $mounted');
      return;
    }
    
    // Debug: Address update logging
    if (columnIndex < _columns.length && _columns[columnIndex] == '주소') {
    }

    // 입력값 안전성 검사
    final safeValue = value;
    AppLogger.d(
        'CELL UPDATE START: row: $rowIndex, col: $columnIndex, value: "$safeValue"');
    AppLogger.d(
        'CELL UPDATE: Total properties: ${_currentChart!.properties.length}');
    AppLogger.d('CELL UPDATE: Total columns: ${_columns.length}');
    AppLogger.d(
        'CELL UPDATE: Column name: ${columnIndex < _columns.length ? _columns[columnIndex] : "UNKNOWN"}');

    try {
      // 상태 업데이트를 별도 메서드로 분리하여 안전성 확보
      final success = _performCellUpdate(rowIndex, columnIndex, safeValue);

      if (success && mounted) {
        // 성공적으로 업데이트된 경우에만 저장
        _saveCurrentChart();
        AppLogger.d('Debug: 셀 업데이트 성공');
      } else {
        AppLogger.warning('Debug: 셀 업데이트 실패');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Debug: 셀 업데이트 중 오류', error: e, stackTrace: stackTrace);

      // 에러 발생시 사용자에게 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('셀 업데이트 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF8A65),
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  bool _performCellUpdate(int rowIndex, int columnIndex, String value) {
    try {
      AppLogger.d(
          'PERFORM UPDATE: Starting for row: $rowIndex, col: $columnIndex, value: "$value"');

      // 기본 유효성 검사
      if (!_isValidUpdateState(rowIndex, columnIndex, value)) {
        AppLogger.warning('PERFORM UPDATE: Validation failed');
        return false;
      }

      // 데이터 준비 (setState 외부에서 수행)
      final updateResult = _prepareDataUpdate(rowIndex, columnIndex, value);
      if (!updateResult.success) {
        AppLogger.error(
            'PERFORM UPDATE: 데이터 준비 실패: ${updateResult.errorMessage}');
        return false;
      }

      AppLogger.d('PERFORM UPDATE: Data preparation successful');

      // 안전한 상태 업데이트 (최소한의 setState 사용)
      if (mounted) {
        setState(() {
          _currentChart = updateResult.updatedChart;
        });
        AppLogger.d(
            'PERFORM UPDATE: 셀 업데이트 성공 - row: $rowIndex, col: $columnIndex');

        // 업데이트 후 상태 확인
        if (_currentChart != null &&
            rowIndex < _currentChart!.properties.length) {
          final updatedProperty = _currentChart!.properties[rowIndex];
          final rowData = updatedProperty.getRowData(_columns.length);
          AppLogger.d(
              'PERFORM UPDATE: Updated row data for property ${updatedProperty.id}: $rowData');
          if (columnIndex < rowData.length) {
            AppLogger.d(
                'PERFORM UPDATE: Value at col_$columnIndex: "${rowData[columnIndex]}"');
          }
        }

        return true;
      }

      return false;
    } catch (e, stackTrace) {
      AppLogger.error('PERFORM UPDATE: 셀 업데이트 실패',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // 유효성 검사를 별도 메서드로 분리
  bool _isValidUpdateState(int rowIndex, int columnIndex, String value) {
    if (_currentChart == null) {
      AppLogger.warning('차트가 null 상태');
      return false;
    }

    if (!mounted) {
      AppLogger.warning('위젯이 마운트되지 않음');
      return false;
    }

    if (rowIndex < 0 || columnIndex < 0) {
      AppLogger.warning('잘못된 인덱스: row=$rowIndex, col=$columnIndex');
      return false;
    }

    return true;
  }

  // 데이터 업데이트 준비를 별도 메서드로 분리
  _UpdateResult _prepareDataUpdate(
      int rowIndex, int columnIndex, String value) {
    try {
      AppLogger.d(
          'PREPARE UPDATE: Starting for row: $rowIndex, col: $columnIndex, value: "$value"');

      final currentProperties =
          List<PropertyData>.from(_currentChart!.properties);

      AppLogger.d(
          'PREPARE UPDATE: Current properties count: ${currentProperties.length}');

      // 필요한 경우 새 행 생성
      _ensureRowExists(currentProperties, rowIndex);

      // 셀 값 업데이트
      if (rowIndex < currentProperties.length) {
        final originalProperty = currentProperties[rowIndex];
        AppLogger.d('PREPARE UPDATE: Original property ${originalProperty.id}');
        AppLogger.d(
            'PREPARE UPDATE: Original additionalData: ${originalProperty.additionalData}');

        final columnName = _columns[columnIndex];
        final updatedProperty = originalProperty.updateCellByName(
            columnName, value, _getColumnDataKey(columnName));
        AppLogger.d('PREPARE UPDATE: Updated property ${updatedProperty.id}');
        AppLogger.d(
            'PREPARE UPDATE: Updated additionalData: ${updatedProperty.additionalData}');

        currentProperties[rowIndex] = updatedProperty;

        final updatedChart =
            _currentChart!.copyWith(properties: currentProperties);
        AppLogger.d('PREPARE UPDATE: Chart update successful');
        return _UpdateResult.success(updatedChart);
      } else {
        AppLogger.warning(
            'PREPARE UPDATE: 행 인덱스 범위 초과 - rowIndex: $rowIndex, length: ${currentProperties.length}');
        return _UpdateResult.failure('행 인덱스 범위 초과');
      }
    } catch (e) {
      AppLogger.error('PREPARE UPDATE: 데이터 업데이트 준비 실패: $e');
      return _UpdateResult.failure('데이터 업데이트 준비 실패: $e');
    }
  }

  // 행 존재 확인 및 생성을 별도 메서드로 분리
  void _ensureRowExists(List<PropertyData> properties, int requiredRowIndex) {
    while (requiredRowIndex >= properties.length) {
      // 추가 컬럼들에 대한 빈 데이터 준비
      final additionalData = <String, String>{};
      for (int i = 8; i < _columns.length; i++) {
        additionalData['col_$i'] = ''; // 모든 추가 컬럼에 빈 문자열 설정
      }

      final newProperty = PropertyData(
        id: '${DateTime.now().millisecondsSinceEpoch}_${properties.length}',
        additionalData: additionalData, // 추가 데이터 포함
      );
      properties.add(newProperty);
      AppLogger.d('새 행 생성 - index: ${properties.length - 1}');
    }
  }

  double _getColumnWidth(int index) {
    // 차트의 컬럼 너비 설정 사용
    if (_currentChart?.columnWidths.containsKey(index) ?? false) {
      return _currentChart!.columnWidths[index]!;
    }

    // 기본 너비 (제목 컬럼과 스크롤 컬럼 구분)
    switch (index) {
      case 0:
        return 160; // 집 이름
      case 1:
        return 80; // 보증금 (좁게)
      case 2:
        return 80; // 월세
      case 3:
        return 160; // 주소 (넓게)
      case 4:
        return 120; // 주거 형태
      case 5:
        return 140; // 집주인 환경
      case 6:
        return 120; // 별점
      default:
        return 98;
    }
  }

  void _editCell(int rowIndex, int columnIndex) {
    // 튜토리얼 상태 추적
    if (!_hasClickedCell) {
      setState(() {
        _hasClickedCell = true;
      });
    }
    if (columnIndex < 0 || columnIndex >= _columns.length) {
      AppLogger.warning(
          'Invalid column index: $columnIndex, columns length: ${_columns.length}');
      return;
    }

    final columnName = _columns[columnIndex];
    final columnType = _columnTypes[columnName] ?? 'text';
    final currentValue = _getCurrentCellValue(rowIndex, columnIndex);

    AppLogger.d(
        'Editing cell - row: $rowIndex, col: $columnIndex, name: $columnName, type: $columnType, value: "$currentValue"');

    // 행이 존재하지 않는 경우 새로 생성
    if (_currentChart != null && rowIndex >= _currentChart!.properties.length) {
      final properties = List<PropertyData>.from(_currentChart!.properties);
      _ensureRowExists(properties, rowIndex);
      setState(() {
        _currentChart = _currentChart!.copyWith(properties: properties);
      });
    }

    // 새 컬럼인 경우 기본 옵션 설정 확인
    if (!_columnOptions.containsKey(columnName)) {
      _columnOptions[columnName] = [];
      AppLogger.d('Created empty options for column: $columnName');
    }

    // 주소 컬럼 특별 처리
    if (columnName == '주소') {
      _showAddressBottomSheet(rowIndex, columnIndex, columnName);
      return;
    }

    switch (columnType) {
      case 'rating':
        _showRatingBottomSheet(rowIndex);
        break;
      case 'direction':
        _showDirectionBottomSheet(rowIndex, columnIndex, columnName);
        break;
      case 'environment':
        _showEnvironmentBottomSheet(rowIndex, columnIndex, columnName);
        break;
      case 'price':
        _showPriceBottomSheet(rowIndex, columnIndex, columnName);
        break;
      case 'number':
        _showNumberBottomSheet(rowIndex, columnIndex, columnName);
        break;
      default:
        AppLogger.d('Showing edit bottom sheet for: $columnName');
        _showEditBottomSheet(rowIndex, columnIndex, columnName);
        break;
    }
  }

  void _showEditBottomSheet(int rowIndex, int columnIndex, String columnName) {
    final currentValue = _getCurrentCellValue(rowIndex, columnIndex);
    final options = _columnOptions[columnName] ?? [];

    // 기본 옵션과 사용자 옵션 합치기
    final defaultOptions = _columnDefaultOptions[columnName] ?? [];
    final allOptions = <String>[];

    // 기본 옵션을 먼저 추가
    allOptions.addAll(defaultOptions);

    // 중복되지 않는 사용자 옵션 추가
    for (final option in options) {
      if (!allOptions.contains(option)) {
        allOptions.add(option);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditBottomSheet(
        columnName: columnName,
        currentValue: currentValue,
        options: allOptions,
        defaultOptionsCount: defaultOptions.length,
        onSave: (value) {
          _updateCellValue(rowIndex, columnIndex, value);
        },
        onAddOption: (newOption) {
          if (!_columnOptions.containsKey(columnName)) {
            _columnOptions[columnName] = [];
          }
          _columnOptions[columnName]!.add(newOption);
          _saveCurrentChart();
          // 메인 화면 갱신
          if (mounted) {
            setState(() {});
          }
        },
        onDeleteOption: (option) {
          // 기본 옵션은 삭제할 수 없도록 함
          if (!defaultOptions.contains(option)) {
            _columnOptions[columnName]?.remove(option);
            _saveCurrentChart(); // 삭제 후 차트 저장
            if (mounted) {
              setState(() {});
            }
          }
        },
      ),
    );
  }

  void _showRatingBottomSheet(int rowIndex) {
    final columnIndex = _columns.indexOf('별점');
    final currentValue = _getCurrentCellValue(rowIndex, columnIndex);
    int rating = int.tryParse(currentValue) ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('별점 선택',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      rating = index + 1;
                      _updateCellValue(
                          rowIndex, columnIndex, rating.toString());
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.star,
                        size: 40,
                        color: index < rating ? Colors.amber : Colors.grey[300],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddressBottomSheet(int rowIndex, int columnIndex, String columnName) {
    final currentValue = _getCurrentCellValue(rowIndex, columnIndex);
    final controller = TextEditingController(text: currentValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, 
                      color: Color(0xFFFF8A65), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    '주소',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (currentValue.isNotEmpty) ...[
                const Text(
                  '현재 주소:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFCCBC)),
                  ),
                  child: Text(
                    currentValue,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: currentValue.isEmpty ? '주소 등록' : '주소 수정',
                  labelStyle: const TextStyle(color: Color(0xFFFF8A65)),
                  hintText: '상세 주소를 입력하세요',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFFF8A65)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFFF8A65), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFFF8A65), width: 2.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onSubmitted: (value) {
                  _updateCellValue(rowIndex, columnIndex, value.trim());
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final newAddress = controller.text.trim();
                        _updateCellValue(rowIndex, columnIndex, newAddress);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A65),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        currentValue.isEmpty ? '등록' : '수정',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDirectionBottomSheet(
      int rowIndex, int columnIndex, String columnName) {
    final currentValue = _getCurrentCellValue(rowIndex, columnIndex);
    final defaultOptions = _columnDefaultOptions[columnName] ?? [];
    final customOptions = _columnOptions[columnName] ?? [];
    final allOptions = [...defaultOptions, ...customOptions];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditBottomSheet(
        columnName: columnName,
        currentValue: currentValue,
        options: allOptions,
        defaultOptionsCount: defaultOptions.length,
        onSave: (value) {
          _updateCellValue(rowIndex, columnIndex, value);
        },
        onAddOption: (newOption) {
          if (!_columnOptions.containsKey(columnName)) {
            _columnOptions[columnName] = [];
          }
          _columnOptions[columnName]!.add(newOption);
          _saveCurrentChart();
          // 바텀시트 갱신을 위해 setState 호출하되, 화면도 갱신되도록 함
          if (mounted) {
            setState(() {});
          }
        },
        onDeleteOption: (option) {
          _columnOptions[columnName]?.remove(option);
          _saveCurrentChart(); // 삭제 후 차트 저장
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  void _showEnvironmentBottomSheet(
      int rowIndex, int columnIndex, String columnName) {
    final currentValue = _getCurrentCellValue(rowIndex, columnIndex);
    final defaultOptions = _columnDefaultOptions[columnName] ?? [];
    final customOptions = _columnOptions[columnName] ?? [];
    final allOptions = [...defaultOptions, ...customOptions];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditBottomSheet(
        columnName: columnName,
        currentValue: currentValue,
        options: allOptions,
        defaultOptionsCount: defaultOptions.length,
        onSave: (value) {
          _updateCellValue(rowIndex, columnIndex, value);
        },
        onAddOption: (newOption) {
          if (!_columnOptions.containsKey(columnName)) {
            _columnOptions[columnName] = [];
          }
          _columnOptions[columnName]!.add(newOption);
          _saveCurrentChart();
          // 바텀시트 갱신을 위해 setState 호출하되, 화면도 갱신되도록 함
          if (mounted) {
            setState(() {});
          }
        },
        onDeleteOption: (option) {
          _columnOptions[columnName]?.remove(option);
          _saveCurrentChart(); // 삭제 후 차트 저장
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  void _showPriceBottomSheet(int rowIndex, int columnIndex, String columnName) {
    final currentValue = _getCurrentCellValue(rowIndex, columnIndex);
    final options = _columnOptions[columnName] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditBottomSheet(
        columnName: columnName,
        currentValue: currentValue,
        options: options,
        defaultOptionsCount: 0,
        onSave: (value) {
          _updateCellValue(rowIndex, columnIndex, value);
        },
        onAddOption: (newOption) {
          if (!_columnOptions.containsKey(columnName)) {
            _columnOptions[columnName] = [];
          }
          _columnOptions[columnName]!.add(newOption);
          _saveCurrentChart();
          // 바텀시트 갱신을 위해 setState 호출하되, 화면도 갱신되도록 함
          if (mounted) {
            setState(() {});
          }
        },
        onDeleteOption: (option) {
          _columnOptions[columnName]?.remove(option);
          _saveCurrentChart(); // 삭제 후 차트 저장
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  void _showNumberBottomSheet(
      int rowIndex, int columnIndex, String columnName) {
    final currentValue = _getCurrentCellValue(rowIndex, columnIndex);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditBottomSheet(
        columnName: columnName,
        currentValue: currentValue,
        options: const [],
        defaultOptionsCount: 0,
        onSave: (value) {
          _updateCellValue(rowIndex, columnIndex, value);
        },
        onAddOption: (newOption) {},
      ),
    );
  }

  Widget _buildEnhancedTable() {
    AppLogger.d('테이블 렌더링 시작');

    // null 체크와 에러 상태 처리
    if (_currentChart == null) {
      return _buildLoadingState();
    }

    if (_currentChart!.properties.isEmpty) {
      return _buildEmptyState();
    }

    // 통합된 가로 스크롤 테이블 렌더링
    try {
      AppLogger.d(
          '테이블 데이터 렌더링 - properties: ${_currentChart!.properties.length}');

      return _buildUnifiedScrollableTable();
    } catch (e, stackTrace) {
      AppLogger.error('테이블 렌더링 오류', error: e, stackTrace: stackTrace);
      return _buildErrorState(e);
    }
  }

  // 새 컬럼 추가 버튼 (더 작게 수정)
  Widget _buildAddColumnButton() {
    return GestureDetector(
      key: _addColumnKey,
      onTap: _showAddColumnBottomSheet,
      child: Container(
        width: 35,
        height: 35,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF8A65),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // 새 행 추가 버튼
  Widget _buildAddRowButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Container(
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
          key: _addRowKey,
          onPressed: _addNewRow,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  // 새 행 추가 메서드
  void _addNewRow() {
    // 튜토리얼 상태 추적
    if (!_hasAddedRow) {
      setState(() {
        _hasAddedRow = true;
      });
    }
    if (!mounted || _currentChart == null) return;

    // 추가 컬럼들에 대한 빈 데이터 준비
    final additionalData = <String, String>{};
    for (int i = 7; i < _columns.length; i++) {
      additionalData['col_$i'] = ''; // 모든 추가 컬럼에 빈 문자열 설정
    }

    final now = DateTime.now();
    final newProperty = PropertyData(
      id: now.millisecondsSinceEpoch.toString(),
      createdAt: now, // 생성 시간 명시적 설정
      additionalData: additionalData, // 추가 데이터 포함
    );

    setState(() {
      final properties = List<PropertyData>.from(_currentChart!.properties);
      properties.add(newProperty);
      _currentChart = _currentChart!.copyWith(properties: properties);
    });

    _saveCurrentChart();
  }

  // 별점 표시 위젯
  Widget _buildRatingStars(String value, {int? rowIndex, int? columnIndex}) {
    final rating = int.tryParse(value) ?? 0;

    // 행 인덱스와 컬럼 인덱스가 제공된 경우 클릭 가능한 별점
    if (rowIndex != null && columnIndex != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 클릭 가능한 별점들
          ...List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                final newRating = index + 1;
                _updateCellValue(rowIndex, columnIndex, newRating.toString());
              },
              child: Icon(
                Icons.star,
                size: 16,
                color: index < rating ? Colors.amber : Colors.grey[300],
              ),
            );
          }),
        ],
      );
    }

    // 기본 읽기 전용 별점 (행/컬럼 정보가 없는 경우)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Icon(
          Icons.star,
          size: 16,
          color: index < rating ? Colors.amber : Colors.grey[300],
        );
      }),
    );
  }

  // 전체 항목 우선순위 관리 컨트롤
  Widget _buildSortingControls() {
    return Container(
      key: _filterKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 전체 항목 우선순위 설정
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showGlobalPrioritySettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A65),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.reorder, size: 20),
              label: const Text('표제목 순서'),
            ),
          ),
          const SizedBox(width: 12),
          // 항목 가중치 설정
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showItemWeightSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.balance, size: 20),
              label: const Text('중요도 설정'),
            ),
          ),
          const SizedBox(width: 12),
          // 전체 맞춤 정렬
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showCustomRankingSort,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text('맞춤 정렬'),
            ),
          ),
        ],
      ),
    );
  }

  // 새 컬럼 추가 바텀시트
  void _showAddColumnBottomSheet() {
    // 튜토리얼 상태 추적
    if (!_hasAddedColumn) {
      setState(() {
        _hasAddedColumn = true;
      });
    }
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더 부분
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9575), Color(0xFFFF8A65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      '새 컬럼 추가',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 내용 부분
            Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFCC80),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFFFF8A65),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '새로운 비교 항목을 추가하여 매물을 더 세세하게 평가해보세요.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6D4C41),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: '컬럼 이름',
                      labelStyle: const TextStyle(
                        color: Color(0xFFFF8A65),
                        fontWeight: FontWeight.w600,
                      ),
                      hintText: '예: 특이사항, 연락처, 교통편',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFFCCBC)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFFCCBC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF8A65),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFFFAF8),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFFFCCBC),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(
                              color: Color(0xFF757575),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9575), Color(0xFFFF8A65)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (controller.text.trim().isNotEmpty) {
                                final newColumnName = controller.text.trim();
                                _addNewColumn(newColumnName);
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              '추가',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 새 컬럼 추가 메서드 (별점을 마지막에 유지)
  void _addNewColumn(String columnName) {
    if (!mounted || _currentChart == null) return;

    AppLogger.d('=== NEW COLUMN ADDITION START ===');
    AppLogger.d('Adding column: "$columnName"');
    AppLogger.d('Current columns: $_columns');
    AppLogger.d(
        'Current properties count: ${_currentChart!.properties.length}');

    // 새 컬럼을 추가하기 전에 기존 추가 컬럼들의 정보를 저장
    final existingAdditionalColumns = <String>[];
    for (int i = 7; i < _columns.length; i++) {
      if (_columns[i] != '별점') {
        existingAdditionalColumns.add(_columns[i]);
      }
    }
    AppLogger.d('Existing additional columns: $existingAdditionalColumns');

    // 새 컬럼 키 생성
    final newColumnKey = _getColumnDataKey(columnName);
    final newDataKey = newColumnKey['key']!;
    AppLogger.d('New column "$columnName" will use key: "$newDataKey"');

    // 모든 행을 업데이트하여 기존 데이터는 유지하고 새 컬럼만 추가
    final updatedProperties = <PropertyData>[];

    for (int propertyIndex = 0;
        propertyIndex < _currentChart!.properties.length;
        propertyIndex++) {
      final property = _currentChart!.properties[propertyIndex];

      AppLogger.d('--- Processing Property ${property.id} ---');
      AppLogger.d('Original additionalData: ${property.additionalData}');

      // 기존 additionalData를 완전히 복사
      final newAdditionalData =
          Map<String, String>.from(property.additionalData);

      // 새 컬럼에 대해서만 빈 값 추가
      newAdditionalData[newDataKey] = '';
      AppLogger.d('Added new column key "$newDataKey" with empty value');

      AppLogger.d(
          'Final additionalData for property ${property.id}: $newAdditionalData');

      // PropertyData 복사 (기존 데이터 모두 유지)
      final updatedProperty = PropertyData(
        id: property.id, // 기존 ID 유지
        name: property.name,
        deposit: property.deposit,
        rent: property.rent,
        direction: property.direction,
        landlordEnvironment: property.landlordEnvironment,
        rating: property.rating,
        cellImages: Map<String, List<String>>.from(property.cellImages),
        additionalData: newAdditionalData, // 새 컬럼이 추가된 맵
      );

      updatedProperties.add(updatedProperty);
      AppLogger.d('Updated property ${property.id} successfully');
    }

    // 컬럼 목록 업데이트 (별점을 마지막에 유지)
    if (_columns.contains('별점')) {
      _columns.remove('별점');
    }
    _columns.add(columnName);
    if (!_columns.contains('별점')) {
      _columns.add('별점');
    }

    // 새 컬럼 타입을 text로 설정하고 빈 옵션으로 초기화
    _columnTypes[columnName] = 'text';
    _columnOptions[columnName] = [];

    AppLogger.d('Updated columns: $_columns');
    AppLogger.d('=== NEW COLUMN ADDITION END ===');

    setState(() {
      _currentChart = _currentChart!.copyWith(properties: updatedProperties);
    });

    _saveCurrentChart();

    // 검증
    AppLogger.d('=== VERIFICATION ===');
    for (final property in updatedProperties) {
      AppLogger.d(
          'Property ${property.id} final additionalData: ${property.additionalData}');
    }
  }

  // 행 삭제 옵션 표시
  void _showRowDeleteOption(int rowIndex) {
    if (_currentChart == null ||
        rowIndex < 0 ||
        rowIndex >= _currentChart!.properties.length) {
      return;
    }

    final property = _currentChart!.properties[rowIndex];
    final rowName =
        property.name.isNotEmpty ? property.name : '${rowIndex + 1}번 행';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘과 제목
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A65).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 32,
                  color: Color(0xFFFF8A65),
                ),
              ),
              const SizedBox(height: 16),

              // 제목
              const Text(
                '행 삭제',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // 설명
              Text(
                '"$rowName"을(를) 삭제하시겠습니까?\n\n삭제된 행의 모든 데이터는 복구할 수 없습니다.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF718096),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 버튼들
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF718096),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteRow(rowIndex);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A65),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '삭제',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 실제 행 삭제 수행
  void _deleteRow(int rowIndex) {
    if (_currentChart == null ||
        rowIndex < 0 ||
        rowIndex >= _currentChart!.properties.length) {
      AppLogger.warning('Invalid row index for deletion: $rowIndex');
      return;
    }

    final property = _currentChart!.properties[rowIndex];
    final rowName =
        property.name.isNotEmpty ? property.name : '${rowIndex + 1}번 행';

    AppLogger.d('=== ROW DELETE START ===');
    AppLogger.d(
        'Deleting row $rowIndex: "$rowName" (Property ID: ${property.id})');

    // 새로운 프로퍼티 리스트 생성 (해당 행 제외)
    final updatedProperties = <PropertyData>[];

    for (int i = 0; i < _currentChart!.properties.length; i++) {
      if (i != rowIndex) {
        updatedProperties.add(_currentChart!.properties[i]);
      }
    }

    AppLogger.d(
        'Properties before deletion: ${_currentChart!.properties.length}');
    AppLogger.d('Properties after deletion: ${updatedProperties.length}');

    // 순번은 리스트의 인덱스로 자동 관리됨 (order 필드 제거됨)

    setState(() {
      _currentChart = _currentChart!.copyWith(properties: updatedProperties);
    });

    _saveCurrentChart();

    AppLogger.d('=== ROW DELETE END ===');

    // 성공 메시지
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('"$rowName"이(가) 삭제되었습니다.'),
          ],
        ),
        backgroundColor: const Color(0xFFFF8A65),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  // 제목 편집 바텀시트
  void _showEditTitleBottomSheet() {
    // 튜토리얼 상태 추적
    if (!_hasEditedTitle) {
      setState(() {
        _hasEditedTitle = true;
        _isBottomSheetVisible = true; // 바텀시트 표시 상태 추적
      });
    } else {
      setState(() {
        _isBottomSheetVisible = true; // 바텀시트 표시 상태 추적
      });
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditBottomSheet(
        columnName: '제목',
        currentValue: _currentChart?.title ?? '',
        options: const [],
        defaultOptionsCount: 0,
        onSave: (newTitle) {
          _updateTitle(newTitle);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('제목이 수정되었습니다.'),
              backgroundColor: Color(0xFFFF8A65),
              duration: Duration(milliseconds: 800),
            ),
          );
        },
        onAddOption: (newOption) {},
      ),
    ).whenComplete(() {
      // 바텀시트가 닫힐 때 상태 초기화
      if (mounted) {
        setState(() {
          _isBottomSheetVisible = false;
        });
      }
    });
  }

  // 빠른 정렬 옵션 표시
  void _showQuickSortOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.sort, color: Color(0xFFFF8A65)),
                  SizedBox(width: 8),
                  Text(
                    '빠른 정렬',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 기본 정렬 옵션들
              _buildQuickSortButton('보증금 낮은순', () => _sortBy('보증금', true)),
              _buildQuickSortButton('보증금 높은순', () => _sortBy('보증금', false)),
              _buildQuickSortButton('월세 낮은순', () => _sortBy('월세', true)),
              _buildQuickSortButton('월세 높은순', () => _sortBy('월세', false)),
              _buildQuickSortButton('별점 높은순', () => _sortBy('별점', false)),
              _buildQuickSortButton('별점 낮은순', () => _sortBy('별점', true)),
              _buildQuickSortButton('이름순', () => _sortBy('집 이름', true)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSortButton(String title, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () {
          onTap();
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
        ),
        child: Text(title),
      ),
    );
  }

  void _sortBy(String columnName, bool ascending) {
    // 튜토리얼 상태 추적
    if (!_hasUsedSort) {
      setState(() {
        _hasUsedSort = true;
      });
    }
    if (_currentChart == null) return;

    final properties = List<PropertyData>.from(_currentChart!.properties);

    properties.sort((a, b) {
      String aValue = '';
      String bValue = '';

      switch (columnName) {
        case '보증금':
          aValue = a.deposit;
          bValue = b.deposit;
          break;
        case '월세':
          aValue = a.rent;
          bValue = b.rent;
          break;
        case '별점':
          return ascending
              ? a.rating.compareTo(b.rating)
              : b.rating.compareTo(a.rating);
        case '집 이름':
          aValue = a.name;
          bValue = b.name;
          break;
        default:
          return 0;
      }

      // 숫자 필드인 경우
      if (columnName == '보증금' || columnName == '월세') {
        final aNum = int.tryParse(aValue) ?? 0;
        final bNum = int.tryParse(bValue) ?? 0;
        return ascending ? aNum.compareTo(bNum) : bNum.compareTo(aNum);
      }

      // 문자열 필드인 경우
      return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
    });

    setState(() {
      _currentChart = _currentChart!.copyWith(properties: properties);
    });

    _saveCurrentChart();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$columnName ${ascending ? "오름차순" : "내림차순"}으로 정렬되었습니다.'),
        backgroundColor: const Color(0xFFFF8A65),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  // 컬럼 관리 시트
  void _showColumnManagementSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  const Text(
                    '항목 관리',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddColumnBottomSheet();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A65),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('항목 추가'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteColumnSheet();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBDBDBD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.remove),
                      label: const Text('항목 삭제'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 컬럼 삭제 시트
  void _showDeleteColumnSheet() {
    final deletableColumns =
        _columns.where((col) => !_baseColumns.contains(col)).toList();

    if (deletableColumns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('삭제할 수 있는 컬럼이 없습니다.'),
          backgroundColor: Colors.orange,
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.remove_circle, color: Color(0xFFBDBDBD)),
                  SizedBox(width: 8),
                  Text(
                    '컬럼 삭제',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                '삭제할 컬럼을 선택하세요:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ...deletableColumns.map((col) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteColumnByName(col);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A65),
                        foregroundColor: const Color(0xFFFF8A65),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(col),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteColumnByName(String columnName) {
    if (!mounted ||
        _currentChart == null ||
        _baseColumns.contains(columnName)) {
      return;
    }

    final columnIndex = _columns.indexOf(columnName);
    if (columnIndex == -1) return;

    final columnKey = _getColumnDataKey(columnName);
    final dataKey = columnKey['key']!;

    // 컬럼 제거
    setState(() {
      _columns.removeAt(columnIndex);

      // 모든 속성에서 해당 데이터 제거
      final updatedProperties = _currentChart!.properties.map((property) {
        final newAdditionalData =
            Map<String, String>.from(property.additionalData);
        newAdditionalData.remove(dataKey);
        return property.copyWith(additionalData: newAdditionalData);
      }).toList();

      _currentChart = _currentChart!.copyWith(properties: updatedProperties);
    });

    _saveCurrentChart();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$columnName" 컬럼이 삭제되었습니다.'),
        backgroundColor: const Color(0xFFFF8A65),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  // 직접 정렬 선택
  void _showDirectSortSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.list_alt, color: Colors.teal[600]),
                  const SizedBox(width: 8),
                  const Text(
                    '정렬 순서 직접 설정',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                '컬럼을 선택하여 맞춤 정렬을 설정하세요:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ..._columns.map((col) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCustomSortOrderDialog(col);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[50],
                        foregroundColor: Colors.teal[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.tune),
                      label: Text(col),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomSortOrderDialog(String columnName) {
    showDialog(
      context: context,
      builder: (context) => CustomSortOrderDialog(
        columnName: columnName,
        onOrderSet: (customOrder) {
          _applySortOrder(columnName, customOrder);
        },
      ),
    );
  }

  void _applySortOrder(String columnName, List<String> customOrder) {
    if (_currentChart == null || customOrder.isEmpty) return;

    final properties = List<PropertyData>.from(_currentChart!.properties);

    properties.sort((a, b) {
      String aValue = '';
      String bValue = '';

      // 컬럼에 따른 값 추출
      switch (columnName) {
        case '재계/방향':
          aValue = a.direction;
          bValue = b.direction;
          break;
        case '집주인 환경':
          aValue = a.landlordEnvironment;
          bValue = b.landlordEnvironment;
          break;
        case '집 이름':
          aValue = a.name;
          bValue = b.name;
          break;
        default:
          // 추가 컬럼인 경우
          final columnKey = _getColumnDataKey(columnName);
          final dataKey = columnKey['key']!;
          aValue = a.additionalData[dataKey] ?? '';
          bValue = b.additionalData[dataKey] ?? '';
      }

      // 커스텀 순서에 따른 정렬
      final aIndex = customOrder.indexOf(aValue);
      final bIndex = customOrder.indexOf(bValue);

      // 리스트에 없는 값들은 마지막으로
      if (aIndex == -1 && bIndex == -1) return 0;
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;

      return aIndex.compareTo(bIndex);
    });

    setState(() {
      _currentChart = _currentChart!.copyWith(properties: properties);
    });

    _saveCurrentChart();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$columnName 맞춤 순서로 정렬되었습니다.'),
        backgroundColor: const Color(0xFFFF8A65),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  // 원래 순서로 되돌리기
  void _resetToOriginalOrder() {
    if (_currentChart == null) return;

    try {
      final properties = List<PropertyData>.from(_currentChart!.properties);

      // createdAt 기준으로 원래 생성 순서대로 정렬
      properties.sort((a, b) {
        // 둘 다 createdAt이 있으면 시간 비교
        if (a.createdAt != null && b.createdAt != null) {
          return a.createdAt!.compareTo(b.createdAt!);
        }
        // a만 createdAt이 없으면 a를 뒤로
        if (a.createdAt == null && b.createdAt != null) {
          return 1;
        }
        // b만 createdAt이 없으면 b를 뒤로  
        if (a.createdAt != null && b.createdAt == null) {
          return -1;
        }
        // 둘 다 createdAt이 없으면 ID 기준 정렬 (숫자 형태 ID이므로 숫자로 변환하여 비교)
        final aIdNum = int.tryParse(a.id) ?? 0;
        final bIdNum = int.tryParse(b.id) ?? 0;
        return aIdNum.compareTo(bIdNum);
      });

      // 순번은 리스트의 인덱스로 자동 관리됨 (order 필드 제거됨)

      setState(() {
        _currentChart = _currentChart!.copyWith(properties: properties);
        // 정렬 상태 초기화
        _sortColumn = null;
        _sortAscending = true;
        _filters.clear();
        _customSortOrders.clear();
      });

      _saveCurrentChart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('원래 순서로 되돌렸습니다.'),
            backgroundColor: Color(0xFFFF8A65),
            duration: Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('순서 초기화 실패', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('순서 초기화 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 1500),
          ),
        );
      }
    }
  }

  // 기본 컬럼 순서 반환 ('순' 제외)
  List<String> _getDefaultColumnOrder() {
    return [
      '집 이름',
      '보증금',
      '월세',
      '주거형태',
      '건축물용도',
      '임차권 등기명령 이력여부',
      '근저당권여부',
      '가압류나 압류이력여부',
      '계약조건',
      '등기부등본',
      '입주가능일',
      '전입신고 가능여부',
      '관리비',
      '주택보증보험가능여부',
      '특약',
      '특이사항',
      '재계/방향',
      '집주인 환경',
      '별점'
    ];
  }

  // 전체 항목 우선순위 설정
  void _showGlobalPrioritySettings() {
    // 임시 컬럼 순서 (팝업 내에서만 사용, 고정 컬럼들 제외)
    List<String> tempColumns =
        _columns.where((column) => column != '순' && column != '제목').toList();

    // 컬럼 표시 여부를 관리하는 Map (저장된 값이 있으면 사용, 없으면 기본값 false)
    // 필수 컬럼들('집 이름', '월세', '보증금')은 항상 true로 설정
    Map<String, bool> tempColumnVisibility = {
      for (String column in tempColumns)
        column: _isRequiredColumn(column)
            ? true
            : (_currentChart?.columnVisibility?[column] ?? false)
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          margin: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.reorder, color: Color(0xFFFF8A65)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '표 제목 순서 정하기',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          tempColumns = _getDefaultColumnOrder();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF8A65),
                        side: const BorderSide(color: Color(0xFFFF8A65)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                      child: const Text('원래대로', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '카드에서 보일 항목 체크하기',
                  style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFFF8A65),
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  '핸들(=)을 드래그하여 컬럼 순서를 변경하세요',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: tempColumns.length,
                    onReorder: (oldIndex, newIndex) {
                      setModalState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final item = tempColumns.removeAt(oldIndex);
                        tempColumns.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final column = tempColumns[index];
                      return Container(
                        key: ValueKey(column),
                        margin: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _isRequiredColumn(column)
                                    ? true
                                    : (tempColumnVisibility[column] ?? false),
                                onChanged: _isRequiredColumn(column)
                                    ? null
                                    : (value) {
                                        setModalState(() {
                                          // 체크하려고 할 때 6개 제한 확인 (필수 컬럼 제외)
                                          if (value == true) {
                                            int checkedCount =
                                                tempColumnVisibility.entries
                                                    .where((entry) =>
                                                        entry.value &&
                                                        !_isRequiredColumn(
                                                            entry.key))
                                                    .length;
                                            if (checkedCount >= 6) {
                                              // 필수 3개 + 선택 6개 = 총 9개
                                              // 6개 제한 알림
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      '필수 컬럼 외 최대 6개까지만 추가 선택할 수 있습니다.'),
                                                  backgroundColor:
                                                      Color(0xFFFF8A65),
                                                  duration: Duration(
                                                      milliseconds: 1500),
                                                ),
                                              );
                                              return;
                                            }
                                          }
                                          tempColumnVisibility[column] =
                                              value ?? false;
                                        });
                                      },
                                activeColor: const Color(0xFFFF8A65),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                backgroundColor: const Color(0xFFFF8A65),
                                radius: 16,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            column,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: (_isRequiredColumn(column) ||
                                      (tempColumnVisibility[column] ?? false))
                                  ? Colors.black87
                                  : Colors.grey[400],
                            ),
                          ),
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.drag_handle,
                                color: Color(0xFFFF8A65),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[400]!),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            // 순과 제목은 고정 컬럼이므로 제외하고 순서 적용
                            _columns = tempColumns.where((column) => column != '순' && column != '제목').toList();
                          });
                          Navigator.pop(context);

                          // 컬럼 순서와 표시 여부를 차트에 저장
                          if (_currentChart != null) {
                            // AppLogger.d('💾 컬럼 순서 저장: $_columns');

                            // 필수 컬럼들을 항상 true로 설정하여 저장
                            Map<String, bool> finalColumnVisibility =
                                Map.from(tempColumnVisibility);
                            for (String column in tempColumns) {
                              if (_isRequiredColumn(column)) {
                                finalColumnVisibility[column] = true;
                              }
                            }

                            // AppLogger.d('💾 컬럼 표시 여부 저장: $finalColumnVisibility');
                            _currentChart = _currentChart!.copyWith(
                              columnOrder: List.from(_columns),
                              columnVisibility: finalColumnVisibility,
                            );
                            // AppLogger.d('💾 차트에 저장된 컬럼 순서: ${_currentChart!.columnOrder}');
                            // AppLogger.d('💾 차트에 저장된 컬럼 표시 여부: ${_currentChart!.columnVisibility}');
                            _saveCurrentChart();
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('컬럼 순서 및 표시 설정이 저장되었습니다.'),
                              backgroundColor: Color(0xFFFF8A65),
                              duration: Duration(milliseconds: 800),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8A65),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('저장'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 항목 가중치 설정
  void _showItemWeightSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          margin: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.balance, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    const Text(
                      '항목 중요도 설정',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  '각 항목의 중요도를 설정하세요 (1-5점)',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _columns.length,
                      itemBuilder: (context, index) {
                        final column = _columns[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  column,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: List.generate(5, (starIndex) {
                                    return GestureDetector(
                                      onTap: () {
                                        // 가중치 설정 로직 (starIndex + 1이 가중치)
                                        setModalState(() {
                                          _itemWeights[column] = starIndex + 1;
                                        });
                                      },
                                      child: Icon(
                                        Icons.star,
                                        size: 24,
                                        color: starIndex <
                                                (_itemWeights[column] ?? 3)
                                            ? Colors.amber
                                            : Colors.grey[300],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('가중치가 설정되었습니다.'),
                          backgroundColor: Colors.orange,
                          duration: Duration(milliseconds: 800),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('저장'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 맞춤 정렬 기능
  void _showCustomRankingSort() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.teal[600]),
                  const SizedBox(width: 8),
                  const Text(
                    '맞춤 정렬',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                '설정된 우선순위와 가중치를 바탕으로 자동 정렬합니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _performSmartSort(ascending: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.trending_up),
                      label: const Text('최고 순'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _performSmartSort(ascending: false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.trending_down),
                      label: const Text('최저 순'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 스마트 정렬 수행
  void _performSmartSort({required bool ascending}) {
    if (_currentChart == null) return;

    final properties = List<PropertyData>.from(_currentChart!.properties);

    // 간단한 스마트 정렬: 별점, 보증금, 월세를 종합적으로 고려
    properties.sort((a, b) {
      double aScore = 0;
      double bScore = 0;

      // 별점 (30% 가중치)
      aScore += a.rating * 0.3;
      bScore += b.rating * 0.3;

      // 보증금 (낮을수록 좋음, 30% 가중치)
      final aDeposit = int.tryParse(a.deposit) ?? 0;
      final bDeposit = int.tryParse(b.deposit) ?? 0;
      const maxDeposit = 10000; // 최대 보증금 기준
      aScore += (maxDeposit - aDeposit) / maxDeposit * 0.3;
      bScore += (maxDeposit - bDeposit) / maxDeposit * 0.3;

      // 월세 (낮을수록 좋음, 40% 가중치)
      final aRent = int.tryParse(a.rent) ?? 0;
      final bRent = int.tryParse(b.rent) ?? 0;
      const maxRent = 100; // 최대 월세 기준
      aScore += (maxRent - aRent) / maxRent * 0.4;
      bScore += (maxRent - bRent) / maxRent * 0.4;

      return ascending ? bScore.compareTo(aScore) : aScore.compareTo(bScore);
    });

    setState(() {
      _currentChart = _currentChart!.copyWith(properties: properties);
    });

    _saveCurrentChart();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('맞춤 정렬이 ${ascending ? "최고 순" : "최저 순"}으로 완료되었습니다.'),
        backgroundColor: Colors.teal[600],
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  // 컬럼의 기존 값들을 가져오는 메서드
  List<String> _getExistingValuesForColumn(String columnName) {
    if (_currentChart == null) return [];

    final values = <String>{};

    for (final property in _currentChart!.properties) {
      final value = _getPropertyValue(property, columnName);
      if (value.trim().isNotEmpty) {
        values.add(value.trim());
      }
    }

    return values.toList()..sort();
  }

  // 헤더 컬럼 편집 바텀시트
  void _showEditColumnBottomSheet(String columnName, int columnIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ColumnSortFilterBottomSheet(
        columnName: columnName,
        columnType: _columnTypes[columnName] ?? 'text',
        currentSortColumn: _sortColumn,
        sortAscending: _sortAscending,
        currentFilter: _filters[columnName],
        existingValues: _getExistingValuesForColumn(columnName),
        onSort: (ascending) {
          setState(() {
            _sortColumn = columnName;
            _sortAscending = ascending;
          });
          _applySortingAndFiltering();
        },
        onFilter: (filterValue) {
          setState(() {
            if (filterValue == null) {
              _filters.remove(columnName);
            } else {
              _filters[columnName] = filterValue;
            }
          });
          _applySortingAndFiltering();
        },
        onCustomSort: (customOrder) {
          setState(() {
            _customSortOrders[columnName] = customOrder;
            _sortColumn = columnName;
            _sortAscending = true; // 커스텀 정렬은 항상 설정한 순서대로
          });
          _applySortingAndFiltering();
        },
        onRename: (newName) {
          _renameColumn(columnIndex, newName);
        },
        onDelete: () {
          _deleteColumnByName(columnName);
        },
        onQuickSort: _showQuickSortOptions,
        onColumnManagement: _showColumnManagementSheet,
        onDirectSort: _showDirectSortSelection,
        onResetOrder: _resetToOriginalOrder,
      ),
    );
  }

  // 정렬 및 필터링 적용
  void _applySortingAndFiltering() {
    if (_currentChart == null) return;

    setState(() {
      List<PropertyData> properties = List.from(_currentChart!.properties);

      // 필터링 적용
      for (final entry in _filters.entries) {
        final columnName = entry.key;
        final filterValue = entry.value;

        properties = properties.where((property) {
          final value = _getPropertyValue(property, columnName);
          return _matchesFilter(
              value, filterValue, _columnTypes[columnName] ?? 'text');
        }).toList();
      }

      // 정렬 적용 (순번 컬럼 제외)
      if (_sortColumn != null && _sortColumn != '순') {
        properties.sort((a, b) {
          final aValue = _getPropertyValue(a, _sortColumn!);
          final bValue = _getPropertyValue(b, _sortColumn!);

          int comparison = _compareValues(
              aValue, bValue, _columnTypes[_sortColumn!] ?? 'text');
          return _sortAscending ? comparison : -comparison;
        });

        // 순번은 리스트의 인덱스로 자동 관리됨 (order 필드 제거됨)
      }

      // 차트 업데이트
      _currentChart = PropertyChartModel(
        id: _currentChart!.id,
        title: _currentChart!.title,
        date: _currentChart!.date,
        properties: properties,
        columnWidths: _currentChart!.columnWidths,
        columnOptions: _currentChart!.columnOptions,
      );
    });

    // 변경사항 저장
    _saveCurrentChart();
  }

  // PropertyData에서 값 추출하는 헬퍼 메서드
  String _getPropertyValue(PropertyData property, String columnName) {
    final columnKey = _getColumnDataKey(columnName);

    if (columnKey['type'] == 'base') {
      switch (columnKey['key']) {
        case 'order':
          // order 필드가 제거되었으므로, 리스트에서의 위치를 반환
          final index = _currentChart!.properties.indexOf(property);
          return (index + 1).toString();
        case 'name':
          return property.name;
        case 'deposit':
          return property.deposit;
        case 'rent':
          return property.rent;
        case 'direction':
          return property.direction;
        case 'landlordEnvironment':
          return property.landlordEnvironment;
        case 'rating':
          return property.rating.toString();
        default:
          return '';
      }
    } else {
      // 추가 컬럼
      return property.additionalData[columnKey['key']] ?? '';
    }
  }

  // 필터 매칭 확인
  bool _matchesFilter(dynamic value, dynamic filter, String columnType) {
    switch (columnType) {
      case 'price':
        final numValue = double.tryParse(value.toString()) ?? 0;
        final filterNum = double.tryParse(filter.toString()) ?? 0;
        return numValue <= filterNum;
      case 'select':
        return value
            .toString()
            .toLowerCase()
            .contains(filter.toString().toLowerCase());
      case 'rating':
        final numValue = double.tryParse(value.toString()) ?? 0;
        final filterNum = double.tryParse(filter.toString()) ?? 0;
        return numValue >= filterNum;
      default:
        return value
            .toString()
            .toLowerCase()
            .contains(filter.toString().toLowerCase());
    }
  }

  // 값 비교 (정렬용)
  int _compareValues(dynamic a, dynamic b, String columnType) {
    // 커스텀 정렬 순서가 있는 경우 우선 적용
    if (_sortColumn != null && _customSortOrders.containsKey(_sortColumn!)) {
      return _compareWithCustomOrder(a.toString(), b.toString(), _sortColumn!);
    }

    switch (columnType) {
      case 'price':
      case 'rating':
        final numA = double.tryParse(a.toString()) ?? 0;
        final numB = double.tryParse(b.toString()) ?? 0;
        return numA.compareTo(numB);
      case 'date':
        final dateA = DateTime.tryParse(a.toString()) ?? DateTime.now();
        final dateB = DateTime.tryParse(b.toString()) ?? DateTime.now();
        return dateA.compareTo(dateB);
      case 'select':
        return a.toString().compareTo(b.toString());
      default:
        return a.toString().compareTo(b.toString());
    }
  }

  // 커스텀 정렬 순서 비교
  int _compareWithCustomOrder(String a, String b, String columnName) {
    final customOrder = _customSortOrders[columnName];
    if (customOrder == null || customOrder.isEmpty) {
      return a.compareTo(b); // 커스텀 순서가 없으면 기본 정렬
    }

    // 커스텀 순서에서 각 값의 정확한 인덱스 찾기
    int indexA = customOrder.indexOf(a);
    int indexB = customOrder.indexOf(b);

    // 정확히 일치하지 않는 경우 contains로 부분 일치 확인
    if (indexA == -1) {
      for (int i = 0; i < customOrder.length; i++) {
        if (a.contains(customOrder[i]) || customOrder[i].contains(a)) {
          indexA = i;
          break;
        }
      }
    }

    if (indexB == -1) {
      for (int i = 0; i < customOrder.length; i++) {
        if (b.contains(customOrder[i]) || customOrder[i].contains(b)) {
          indexB = i;
          break;
        }
      }
    }

    // 둘 다 커스텀 순서에 있는 경우
    if (indexA != -1 && indexB != -1) {
      return indexA.compareTo(indexB);
    }

    // 하나만 커스텀 순서에 있는 경우, 커스텀 순서에 있는 것을 우선
    if (indexA != -1 && indexB == -1) return -1;
    if (indexA == -1 && indexB != -1) return 1;

    // 둘 다 커스텀 순서에 없으면 일반 문자열 비교
    return a.compareTo(b);
  }

  // 컬럼명 변경
  void _renameColumn(int columnIndex, String newName) {
    if (!mounted || _currentChart == null) return;

    if (columnIndex < 0 || columnIndex >= _columns.length) return;

    final oldName = _columns[columnIndex];
    _columns[columnIndex] = newName;

    // 컬럼 타입과 옵션도 함께 이동
    if (_columnTypes.containsKey(oldName)) {
      _columnTypes[newName] = _columnTypes[oldName]!;
      _columnTypes.remove(oldName);
    }

    if (_columnOptions.containsKey(oldName)) {
      _columnOptions[newName] = _columnOptions[oldName]!;
      _columnOptions.remove(oldName);
    }

    setState(() {});
    _saveCurrentChart();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('컬럼명이 "$newName"으로 변경되었습니다.'),
        backgroundColor: const Color(0xFFFF8A65),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }


  // 차트 제목 업데이트
  void _updateTitle(String newTitle) {
    if (_currentChart == null || !mounted) return;

    setState(() {
      _currentChart = _currentChart!.copyWith(title: newTitle);
    });

    _saveCurrentChart();
  }


  // 카테고리별 컬럼 추가 다이얼로그
  void _showAddColumnDialog(String categoryName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        elevation: 8,
        title: Container(
          padding: const EdgeInsets.only(bottom: 16),
          decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: Color(0xFFFFECE0), width: 2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9C8A), Color(0xFFFF8064)],
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
                child: const Icon(Icons.add_circle_outline,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text('$categoryName에 컬럼 추가',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242))),
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
              child: Text(
                '$categoryName 카테고리에 새로운 컬럼을 추가합니다.',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6D4C41)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '컬럼 이름',
                labelStyle: const TextStyle(color: Color(0xFFFF8A65)),
                hintText: '예: 새로운 항목',
                hintStyle: const TextStyle(color: Color(0xFFBCAAA4)),
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
                prefixIcon: const Icon(Icons.add, color: Color(0xFFFF8A65)),
                filled: true,
                fillColor: const Color(0xFFFFF8F5),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                colors: [Color(0xFFFF9C8A), Color(0xFFFF8064)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4DFF8A65),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  _addColumnToCategory(categoryName, controller.text.trim());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '$categoryName에 "${controller.text.trim()}" 컬럼이 추가되었습니다.',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
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
      ),
    );
  }

  // 카테고리에 컬럼 추가
  void _addColumnToCategory(String categoryName, String columnName) {
    try {
      setState(() {
        // 전체 컬럼 리스트에 추가
        _columns.add(columnName);

        // 카테고리 그룹에 추가
        if (_categoryGroups.containsKey(categoryName)) {
          _categoryGroups[categoryName]!.add(columnName);
        }

        // 새 컬럼 가시성 기본값 설정
        _columnVisibility[columnName] = true;
      });

      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$categoryName에 "$columnName" 컬럼이 추가되었습니다'),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      AppLogger.error('컬럼 추가 실패', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('컬럼 추가 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: const Color(0xFFFF8A65),
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  // 카테고리별 배경색 반환
  Color _getCategoryBackgroundColor(String categoryName) {
    // 카드 상세페이지와 동일한 색상 체계 적용
    switch (categoryName) {
      case '💰 필수정보':
        return const Color(0xFFFFE4E6); // 따뜻한 핑크 (카드: 필수 정보)
      case '🏠 부동산 상세 정보':
        return const Color(0xFFFFF8E1); // 밝은 엠버 (카드: 부동산 상세 정보)
      case '🚇 교통 및 편의시설':
        return const Color(0xFFF3E5F5); // 연한 퍼플 (카드: 교통 및 편의시설)
      case '🔒 치안 관련':
        return const Color(0xFFE8F5E8); // 부드러운 그린 (카드: 치안 관련)
      case '🧽 환경 및 청결':
        return const Color(0xFFE0F2F1); // 민트 그린 (카드: 환경 및 청결)
      case '🎨 미관 및 기타':
        return const Color(0xFFFFF3E0); // 따뜻한 오렌지 (카드: 미관 및 기타)
      case '소음•외풍•미세먼지':
        return const Color(0xFFE0F2F1); // 민트 그린 (환경 및 청결과 동일)
      default:
        return const Color(0xFFF8F9FA); // 중성 그레이 (카드와 동일)
    }
  }

  List<Widget> _buildCategoryHeaders(List<String> visibleColumns) {
    final headers = <Widget>[];

    for (final entry in _categoryGroups.entries) {
      final categoryName = entry.key;
      final categoryColumns = entry.value;
      final isExpanded = _categoryExpanded[categoryName] ?? true;

      // 이 카테고리에 표시될 컬럼들 찾기 (순번 제외)
      final visibleCategoryColumns = <String>[];
      if (isExpanded) {
        visibleCategoryColumns.addAll(categoryColumns
            .where((col) => visibleColumns.contains(col) && col != '제목'));
      }

      // 카테고리가 속한 컬럼이 하나라도 있으면 헤더 표시
      final allCategoryColumns =
          categoryColumns.where((col) => col != '제목').toList();
      if (allCategoryColumns.isNotEmpty) {
        // 카테고리의 총 너비 계산
        double totalWidth = 0;
        if (isExpanded) {
          // 펼쳐진 경우: 표시되는 컬럼들의 너비 합계
          for (final column in visibleCategoryColumns) {
            final originalIndex = _columns.indexOf(column);
            if (originalIndex != -1) {
              totalWidth += _getColumnWidth(originalIndex);
            }
          }
        } else {
          // 접힌 경우: 첫 번째 컬럼의 너비만 계산
          final firstColumnInCategory =
              allCategoryColumns.isNotEmpty ? allCategoryColumns.first : '';
          if (firstColumnInCategory.isNotEmpty) {
            final originalIndex = _columns.indexOf(firstColumnInCategory);
            if (originalIndex != -1) {
              totalWidth = _getColumnWidth(originalIndex);
            }
          }
          if (totalWidth == 0) totalWidth = 120; // 최소 너비 보장
        }

        headers.add(
          GestureDetector(
            onTap: () => _toggleCategory(categoryName),
            child: Container(
              width: totalWidth,
              height: 35,
              decoration: BoxDecoration(
                color: _getCategoryBackgroundColor(categoryName),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showAddColumnDialog(categoryName),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 146, 159),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color.fromARGB(255, 255, 157, 157),
                            width: 1),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 12,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        );
      }
    }

    return headers;
  }

  // 순번 고정 테이블 (통합 스크롤)
  Widget _buildUnifiedScrollableTable() {
    try {
      return Column(
        children: [
          // 메인 테이블
          Expanded(
            child: Row(
              children: [
                // 고정된 제목 컬럼 (헤더 + 데이터)
                SizedBox(
                  width: 40, // 제목 컬럼 최소 너비
                  child: Column(
                    children: [
                      // 카테고리 헤더 높이만큼 빈 공간
                      Container(
                        height: 35,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border(
                            right: BorderSide(
                                color: Colors.grey.shade400, width: 1),
                            bottom: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                        ),
                      ),
                      // 제목 헤더
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border(
                            bottom:
                                const BorderSide(color: Colors.grey, width: 1),
                            right: BorderSide(
                                color: Colors.grey.shade400, width: 1),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '제목',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color.fromARGB(255, 84, 84, 84),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      // 제목 데이터들 (1, 2, 3... 숫자 표시)
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            // 제목 컬럼 스크롤시 데이터 영역도 동기화
                            if (notification is ScrollUpdateNotification) {
                              _synchronizeScrollOffset();
                            }
                            return false;
                          },
                          child: ListView.builder(
                            controller: _verticalController,
                            physics: const ClampingScrollPhysics(),
                            itemCount: _currentChart!.properties.isEmpty ? 1 : _currentChart!.properties.length,
                            itemBuilder: (context, index) {
                              return Container(
                                height: 60,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 8),
                                decoration: BoxDecoration(
                                  color: index % 2 == 0
                                      ? Colors.white
                                      : Colors.grey[50],
                                  border: Border(
                                    top: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 0.5),
                                    bottom: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 0.5),
                                    right: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 0.5),
                                    left: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 0.5),
                                  ),
                                ),
                                child: GestureDetector(
                                  onTap: () => _editCell(index, 0),
                                  onLongPress: () {
                                    AppLogger.d(
                                        'Long press on row $index - showing delete option');
                                    _showRowDeleteOption(index);
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              Color.fromARGB(255, 84, 84, 84)),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 스크롤 가능한 나머지 부분 (헤더 + 데이터 통합)
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      // 메인 테이블 가로 스크롤시 카테고리 헤더도 동기화
                      if (notification is ScrollUpdateNotification) {
                        _synchronizeHorizontalScroll();
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        width: _getTotalScrollableWidth(),
                        child: Column(
                          children: [
                            // 카테고리 헤더 (스크롤됨)
                            SizedBox(
                              height: 35,
                              child: Row(
                                children: _buildCategoryHeaders(
                                    _getVisibleColumns()),
                              ),
                            ),
                            // 스크롤되는 헤더
                            Container(
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                    bottom: BorderSide(
                                        color: Colors.grey, width: 1)),
                              ),
                              child: Row(
                                children: [
                                  // 제목 제외한 나머지 컬럼들 (가시성 적용)
                                  ..._getVisibleColumns()
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final columnName = entry.value;
                                    final columnIndex =
                                        _columns.indexOf(columnName);
                                    final width = _getColumnWidth(columnIndex);

                                    return Container(
                                      width: width,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border(
                                            right: BorderSide(
                                                color: Colors.grey.shade300,
                                                width: 0.5)),
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          AppLogger.d(
                                              'Header column tapped: $columnName');
                                          _showEditColumnBottomSheet(
                                              columnName, columnIndex);
                                        },
                                        child: Center(
                                          child: Text(
                                            columnName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Color.fromARGB(
                                                    255, 84, 84, 84)),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  // 새 컬럼 추가 버튼
                                  _buildAddColumnButton(),
                                ],
                              ),
                            ),
                            // 스크롤되는 데이터들
                            Expanded(
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  // 데이터 영역 스크롤시 순번 컬럼도 동기화
                                  if (notification
                                      is ScrollUpdateNotification) {
                                    _synchronizeDataScrollOffset();
                                  }
                                  return false;
                                },
                                child: ListView.builder(
                                  controller: _dataVerticalController,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: _currentChart!.properties.isEmpty ? 1 : _currentChart!.properties.length,
                                  itemBuilder: (context, index) {
                                    return _buildScrollableDataRow(index);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } catch (e) {
      AppLogger.error('테이블 빌드 오류', error: e);
      return const Center(
        child: Text('테이블 로딩 중 오류가 발생했습니다.'),
      );
    }
  }

  Widget _buildFloatingAddRowButton() {
    return _buildAddRowButton();
  }

  // 스크롤 가능한 전체 너비 계산
  double _getTotalScrollableWidth() {
    double totalWidth = 0;
    final visibleColumns = _getVisibleColumns();
    for (int i = 0; i < visibleColumns.length; i++) {
      final columnName = visibleColumns[i];
      final originalIndex = _columns.indexOf(columnName);
      if (originalIndex != -1) {
        totalWidth += _getColumnWidth(originalIndex);
      }
    }
    return totalWidth + 51; // + 버튼 너비 포함
  }

  // 스크롤되는 데이터 행 빌더 (순번 제외)
  Widget _buildScrollableDataRow(int index) {
    // 빈 차트인 경우나 인덱스가 범위를 벗어나는 경우 기본 빈 행 표시

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 0.5),
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 제목 제외한 나머지 셀들 (가시성 적용)
          ...List.generate(_getVisibleColumns().length, (i) {
            final visibleColumns = _getVisibleColumns();
            final columnName = visibleColumns[i]; // 제목은 고정 컬럼이므로 visibleColumns에 포함안됨
            final columnIndex = _columns.indexOf(columnName);
            final width = _getColumnWidth(columnIndex);
            final value = _getCurrentCellValue(index, columnIndex);

            return Container(
              width: width,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  top: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                ),
              ),
              child: GestureDetector(
                onTap: () {
                  AppLogger.d(
                      'Cell tapped - row: $index, col: $columnIndex, value: "$value"');
                  _editCell(index, columnIndex);
                },
                onDoubleTap: () {
                  AppLogger.d(
                      'Cell double tapped - row: $index, col: $columnIndex');
                  _showImageManager(index, columnIndex);
                },
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.center,
                  color: Colors.transparent, // 터치 영역을 명확하게 정의
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 메인 콘텐츠 (별점 또는 텍스트)
                      Expanded(
                        child: columnIndex == _columns.indexOf('별점') &&
                                _columns.contains('별점')
                            ? _buildRatingStars(value,
                                rowIndex: index, columnIndex: columnIndex)
                            : Text(
                                value,
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 42, 42, 42)),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      // 이미지 인디케이터
                      if (_getCellImages(index, columnIndex).isNotEmpty)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF8A65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          // + 버튼 아래 빈 공간
          const SizedBox(width: 51),
        ],
      ),
    );
  }

  // 필수 컬럼인지 확인하는 헬퍼 메소드
  bool _isRequiredColumn(String columnName) {
    // 기본적으로 표시할 필수 컬럼들만 (최소한의 기본 정보)
    const defaultVisibleColumns = {
      '집 이름', '보증금', '월세'
    };
    return defaultVisibleColumns.contains(columnName);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('차트를 로딩중입니다...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('데이터가 없습니다'),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 48, color: Color(0xFFFF8A65)),
          const SizedBox(height: 16),
          const Text('테이블 렌더링 오류'),
          const SizedBox(height: 8),
          Text('오류: $error', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // 이미지 관리 바텀시트 표시
  void _showImageManager(int rowIndex, int columnIndex) {
    AppLogger.d('Showing image manager for row: $rowIndex, col: $columnIndex');

    final columnName = _columns[columnIndex];
    final cellKey = '${rowIndex}_${columnName}_images';
    final currentImages = _getCellImages(rowIndex, columnIndex);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ImageManagerBottomSheet(
        rowIndex: rowIndex,
        columnIndex: columnIndex,
        columnName: columnName,
        cellKey: cellKey,
        initialImages: currentImages,
        onImageAdded: (imagePath) {
          // 이미지가 추가되면 셀에 이미지 정보 저장
          _updateCellImageData(rowIndex, columnIndex, imagePath);
        },
        onImageDeleted: (imagePath) {
          // 이미지가 삭제되면 셀에서 이미지 정보 제거
          _removeCellImageData(rowIndex, columnIndex, imagePath);
        },
      ),
    );
  }

  // 셀에 이미지 데이터 업데이트
  void _updateCellImageData(int rowIndex, int columnIndex, String imagePath) {
    if (_currentChart == null || rowIndex >= _currentChart!.properties.length) {
      return;
    }

    final columnName = _columns[columnIndex];
    final imageKey = '${columnName}_images';

    final property = _currentChart!.properties[rowIndex];
    final currentImages = _getCellImages(rowIndex, columnIndex);

    if (!currentImages.contains(imagePath)) {
      currentImages.add(imagePath);

      final updatedProperty = property.copyWith(
        additionalData: {
          ...property.additionalData,
          imageKey: jsonEncode(currentImages),
        },
      );

      final updatedProperties =
          List<PropertyData>.from(_currentChart!.properties);
      updatedProperties[rowIndex] = updatedProperty;

      setState(() {
        _currentChart = _currentChart!.copyWith(properties: updatedProperties);
      });

      _saveCurrentChart();
      AppLogger.d('Image added to cell - row: $rowIndex, col: $columnIndex');
    }
  }

  // 셀에서 이미지 데이터 제거
  void _removeCellImageData(int rowIndex, int columnIndex, String imagePath) {
    if (_currentChart == null || rowIndex >= _currentChart!.properties.length) {
      return;
    }

    final columnName = _columns[columnIndex];
    final imageKey = '${columnName}_images';

    final property = _currentChart!.properties[rowIndex];
    final currentImages = _getCellImages(rowIndex, columnIndex);

    if (currentImages.contains(imagePath)) {
      currentImages.remove(imagePath);

      final updatedProperty = property.copyWith(
        additionalData: {
          ...property.additionalData,
          imageKey: jsonEncode(currentImages),
        },
      );

      final updatedProperties =
          List<PropertyData>.from(_currentChart!.properties);
      updatedProperties[rowIndex] = updatedProperty;

      setState(() {
        _currentChart = _currentChart!.copyWith(properties: updatedProperties);
      });

      _saveCurrentChart();
      AppLogger.d(
          'Image removed from cell - row: $rowIndex, col: $columnIndex');
    }
  }

  // 셀의 이미지 목록 가져오기
  List<String> _getCellImages(int rowIndex, int columnIndex) {
    if (_currentChart == null || rowIndex >= _currentChart!.properties.length) {
      return [];
    }

    final columnName = _columns[columnIndex];
    final imageKey = '${columnName}_images';
    final property = _currentChart!.properties[rowIndex];

    final imageData = property.additionalData[imageKey];
    if (imageData == null || imageData.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> imageList = jsonDecode(imageData);
      return imageList.cast<String>();
    } catch (e) {
      AppLogger.warning('Failed to decode image data for cell: $e');
      return [];
    }
  }

  // 중복된 메서드들 제거됨 - 기존 메서드 사용

  void _showTutorial() {
    final steps = [
      GuideStep(
        title: '차트 제목 변경하기 📝',
        description: '상단 제목을 터치하여 차트 제목을 변경할 수 있습니다. 매물 비교 목적에 맞는 이름으로 설정해보세요.',
        targetKey: _titleKey,
        icon: Icons.title,
        tooltipPosition: GuideTooltipPosition.bottom,
        autoNext: true,
        autoNextDelay: const Duration(seconds: 3),
        onStepEnter: () {
          // 차트 제목 변경
          final chart = ref.read(currentChartProvider);
          if (chart != null) {
            final updatedChart = chart.copyWith(title: '예시 차트');
            ref.read(currentChartProvider.notifier).updateChart(updatedChart);
            final integratedService = ref.read(integratedChartServiceProvider);
            integratedService.saveChart(updatedChart);
          }
        },
        onStepExit: () {
          // 원래 제목으로 복원
          final chartList = ref.read(propertyChartListProvider);
          final originalChart = chartList.firstWhere(
            (chart) => chart.id == widget.chartId,
            orElse: () => PropertyChartModel(
          id: '',
          title: '',
          date: DateTime.now(),
          properties: [],
        ),
          );
          if (originalChart.id.isNotEmpty) {
            ref.read(currentChartProvider.notifier).updateChart(originalChart);
            // Firebase에도 원래 제목으로 저장
            final integratedService = ref.read(integratedChartServiceProvider);
            integratedService.saveChart(originalChart);
          }
        },
      ),
      GuideStep(
        title: '정렬 기능 사용하기 🔄',
        description: '정렬 기능을 사용하여 매물들을 별점순, 가격순 등으로 정렬할 수 있습니다. 우선순위에 따라 매물을 비교해보세요.',
        targetKey: _filterKey,
        icon: Icons.sort,
        tooltipPosition: GuideTooltipPosition.bottom,
        autoNext: true,
        autoNextDelay: const Duration(seconds: 3),
        onStepEnter: () {
          // 별점순 정렬 실행
          setState(() {
            _sortColumn = '별점';
            _sortAscending = false;
          });
          _applySortingAndFiltering();
        },
        onStepExit: () {
          // 원래 순서로 복원
          setState(() {
            _sortColumn = null;
            _sortAscending = true;
          });
          _applySortingAndFiltering();
        },
      ),
      GuideStep(
        title: '스마트 정렬 기능 ✨',
        description: '스마트 정렬 기능으로 여러 조건을 종합하여 최적의 매물 순서로 정렬할 수 있습니다. 복잡한 비교도 쉽게!',
        targetKey: _filterKey,
        icon: Icons.auto_awesome,
        tooltipPosition: GuideTooltipPosition.bottom,
        autoNext: true,
        autoNextDelay: const Duration(seconds: 3),
        onStepEnter: () {
          // 스마트 정렬 실행
          _performSmartSort(ascending: false);
        },
        onStepExit: () {
          // 원래 순서로 복원
          setState(() {
            _sortColumn = null;
            _sortAscending = true;
          });
          _applySortingAndFiltering();
        },
      ),
      GuideStep(
        title: '컬럼 표시 설정하기 👁️',
        description: '컬럼 가시성 설정으로 필요한 항목만 보이게 할 수 있습니다. 화면을 깔끔하게 정리해보세요.',
        targetKey: _addColumnKey,
        icon: Icons.view_column,
        tooltipPosition: GuideTooltipPosition.bottom,
        autoNext: true,
        autoNextDelay: const Duration(seconds: 3),
        onStepEnter: () {
          // 일부 컬럼 숨기기
          final chart = ref.read(currentChartProvider);
          if (chart != null) {
            final newVisibility = Map<String, bool>.from(chart.columnVisibility ?? {});
            newVisibility['주거 형태'] = false;
            newVisibility['건축물용도'] = false;
            final updatedChart = chart.copyWith(columnVisibility: newVisibility);
            ref.read(currentChartProvider.notifier).updateChart(updatedChart);
          }
        },
        onStepExit: () {
          // 컬럼 가시성 복원
          final chart = ref.read(currentChartProvider);
          if (chart != null) {
            final newVisibility = Map<String, bool>.from(chart.columnVisibility ?? {});
            newVisibility['주거 형태'] = true;
            newVisibility['건축물용도'] = true;
            final updatedChart = chart.copyWith(columnVisibility: newVisibility);
            ref.read(currentChartProvider.notifier).updateChart(updatedChart);
          }
        },
      ),
      GuideStep(
        title: '셀 편집하기 📝',
        description: '표의 각 셀을 터치하여 매물 정보를 직접 편집할 수 있습니다. 실시간으로 정보를 업데이트해보세요.',
        targetKey: _tableKey,
        icon: Icons.edit,
        tooltipPosition: GuideTooltipPosition.bottom,
      ),
      GuideStep(
        title: '비교 항목 추가하기 ➕',
        description: '+ 버튼을 사용하여 나만의 비교 항목을 추가할 수 있습니다. 원하는 조건으로 매물을 평가해보세요.',
        targetKey: _addColumnKey,
        icon: Icons.add_circle,
        tooltipPosition: GuideTooltipPosition.bottom,
      ),
      GuideStep(
        title: '새 매물 추가하기 🏠',
        description: '우하단 + 버튼으로 새로운 매물을 차트에 추가할 수 있습니다. 비교할 매물이 많을수록 좋은 선택을!',
        targetKey: _addRowKey,
        icon: Icons.add,
        tooltipPosition: GuideTooltipPosition.top,
      ),
      GuideStep(
        title: '가이드 완료! 🎉',
        description: '차트 비교 기능을 모두 살펴보았습니다. 이제 실제로 매물을 추가하고 비교해보세요! 🎉',
        targetKey: _titleKey,
        icon: Icons.check,
        tooltipPosition: GuideTooltipPosition.bottom,
        onStepEnter: () {
          // 모든 변경사항 복원
          final chartList = ref.read(propertyChartListProvider);
          final originalChart = chartList.firstWhere(
            (chart) => chart.id == widget.chartId,
            orElse: () => PropertyChartModel(
          id: '',
          title: '',
          date: DateTime.now(),
          properties: [],
        ),
          );
          if (originalChart.id.isNotEmpty) {
            ref.read(currentChartProvider.notifier).updateChart(originalChart);
            setState(() {
              _sortColumn = null;
              _sortAscending = true;
            });
            _applySortingAndFiltering();
          }
        },
      ),
    ];

    InteractiveGuideManager.showGuide(
      context,
      steps: steps,
      onCompleted: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('차트 화면 가이드가 완료되었습니다!'),
            backgroundColor: Color(0xFFFF8A65),
          ),
        );
      },
      onSkipped: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('가이드를 건너뛰었습니다.')),
        );
      },
    );
  }

  // 실제 체험형 인터렉티브 가이드
  void _showInteractiveChartGuide() {
    // 상태 초기화
    setState(() {
      _hasClickedCell = false;
      _hasAddedColumn = false;
      _hasAddedRow = false;
      _hasUsedSort = false;
      _hasEditedTitle = false;
    });

    final steps = [
      // 1단계: 환영 및 소개
      GuideStep(
        title: '차트 관리 체험 가이드 📊',
        description: '실제 차트 기능을 직접 사용해보면서 배워보겠습니다. 각 단계마다 실제로 클릭하고 입력해보세요!',
        autoNext: true,
        autoNextDelay: const Duration(seconds: 3),
      ),

      // 2단계: 제목 기능 체험
      GuideStep(
        title: '차트 제목 기능 체험하기 ✏️',
        description: '상단의 차트 제목을 눌러서 편집할 수 있습니다. 다음 버튼을 눌러 계속하세요.',
        targetKey: _titleKey,
        tooltipPosition: GuideTooltipPosition.bottom,
        waitForUserAction: false,
        autoNext: true,
        getDynamicArea: () {
          if (_isBottomSheetVisible) {
            final screenSize = MediaQuery.of(context).size;
            return Rect.fromLTWH(0, screenSize.height * 0.3, screenSize.width, screenSize.height * 0.7);
          }
          return Rect.zero;
        },
      ),

      // 3단계: 테이블 셀 기능 체험
      GuideStep(
        title: '테이블 셀 기능 체험하기 📝',
        description: '테이블의 셀을 눌러서 매물 정보를 편집할 수 있습니다. 다음 버튼을 눌러 계속하세요.',
        targetKey: _tableKey,
        tooltipPosition: GuideTooltipPosition.top,
        waitForUserAction: false,
        autoNext: true,
        getDynamicArea: () {
          if (_isBottomSheetVisible) {
            final screenSize = MediaQuery.of(context).size;
            return Rect.fromLTWH(0, screenSize.height * 0.3, screenSize.width, screenSize.height * 0.7);
          }
          return Rect.zero;
        },
      ),

      // 4단계: 정렬 기능 체험
      GuideStep(
        title: '정렬 기능 체험하기 🔄',
        description: '상단의 정렬 버튼을 눌러서 다양한 정렬 옵션을 확인할 수 있습니다. 다음 버튼을 눌러 계속하세요.',
        targetKey: _filterKey,
        tooltipPosition: GuideTooltipPosition.bottom,
        waitForUserAction: false,
        autoNext: true,
      ),

      // 5단계: 새 컬럼 추가 체험
      GuideStep(
        title: '비교 항목 추가 체험하기 ➕',
        description: '새로운 비교 항목(컬럼) 추가 버튼을 눌러서 나만의 비교 기준을 생성할 수 있습니다. 다음 버튼을 눌러 계속하세요.',
        targetKey: _addColumnKey,
        tooltipPosition: GuideTooltipPosition.bottom,
        waitForUserAction: false,
        autoNext: true,
      ),

      // 6단계: 새 매물 추가 체험
      GuideStep(
        title: '새 매물 추가 체험하기 🏠',
        description: '우하단의 + 버튼을 눌러서 새로운 매물을 추가할 수 있습니다. 다음 버튼을 눌러 계속하세요.',
        targetKey: _addRowKey,
        tooltipPosition: GuideTooltipPosition.top,
        waitForUserAction: false,
        autoNext: true,
      ),

      // 7단계: 완료
      GuideStep(
        title: '체험 완료! 🎉',
        description: '훌륭합니다! 차트의 모든 주요 기능을 직접 체험해보셨습니다. 이제 자유롭게 매물들을 비교 분석해보세요.',
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
            content: Text('🎉 인터렉티브 차트 가이드가 완료되었습니다!'),
            backgroundColor: Colors.green,
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

  // 예시 집 3개 데이터 생성
  List<PropertyData> _createSampleProperties() {
    return [
      PropertyData(
        id: '1',
        name: '강남구 역삼동 빌라',
        deposit: '1000',
        rent: '60',
        address: '서울특별시 강남구 역삼동 123-45',
        direction: '남동향',
        landlordEnvironment: '친절함',
        rating: 4,
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        cellImages: {},
        additionalData: {
          'housing_type': '빌라',
          'building_use': '주거용',
          'lease_registration': '없음',
          'mortgage': '없음',
          'seizure_history': '없음',
          'contract_conditions': '월세',
          'property_register': '확인완료',
          'move_in_date': '즉시',
          'resident_registration': '가능',
          'maintenance_fee': '5만원',
          'housing_insurance': '가능',
          'special_terms': '없음',
          'special_notes': '없음',
          'area': '20평대',
          'room_count': '2개',
          'room_structure': '복도형',
          'window_view': '뻥뷰',
          'direction_compass': '남동',
          'lighting': '좋음',
          'floor': '3층',
          'elevator': '없음',
          'ac_type': '벽걸이',
          'heating': '보일러',
          'veranda': '있음',
          'balcony': '있음',
          'parking': '지상주차장',
          'bathroom': '독립',
          'gas': '도시가스',
          'subway_distance': '10분거리',
          'bus_stop': '5분거리',
          'convenience_store': '5분거리',
          'location': '골목길',
          'cctv': '각층',
          'window_condition': '나무창',
          'door_condition': '잘닫침',
          'landlord_personality': '좋은것같음',
          'landlord_residence': '없음',
          'nearby_bar': '없음',
          'security_window': '있음',
          'day_atmosphere': '평범함',
          'night_atmosphere': '평범함',
          'double_lock': '있음',
          'noise_source': '없음',
          'indoor_noise': '없음',
          'double_window': '있음',
          'window_seal': '있음',
          'water_pressure': '강함',
          'leak': '없음',
          'ac_mold': '없음',
          'ac_smell': '없음',
          'ventilation': '됨',
          'mold': '없음',
          'smell': '없음',
          'bugs': '없음',
          'molding': '화이트몰딩',
          'window_sheet': '없음',
          'related_link': '없음',
          'property_info': '확인완료',
          'landlord_info': '확인완료',
          'guide_person': '중개사',
          'memo': '교통 편리, 조용한 동네'
        },
      ),
      PropertyData(
        id: '2',
        name: '홍대입구 오피스텔',
        deposit: '500',
        rent: '80',
        address: '서울특별시 마포구 홍익동 987-12',
        direction: '정남향',
        landlordEnvironment: '보통',
        rating: 3,
        createdAt: DateTime.now().subtract(Duration(days: 2)),
        cellImages: {},
        additionalData: {
          'housing_type': '오피스텔',
          'building_use': '주거용',
          'lease_registration': '없음',
          'mortgage': '있음',
          'seizure_history': '없음',
          'contract_conditions': '월세',
          'property_register': '확인완료',
          'move_in_date': '1주일후',
          'resident_registration': '가능',
          'maintenance_fee': '10만원',
          'housing_insurance': '가능',
          'special_terms': '없음',
          'special_notes': '소음 있음',
          'area': '15평대',
          'room_count': '원룸',
          'room_structure': '원룸',
          'window_view': '마주보는 건물',
          'direction_compass': '정남',
          'lighting': '매우좋음',
          'floor': '7층',
          'elevator': '있음',
          'ac_type': '중앙냉방',
          'heating': '중앙난방',
          'veranda': '없음',
          'balcony': '있음',
          'parking': '지하주차장',
          'bathroom': '독립',
          'gas': '도시가스',
          'subway_distance': '5분거리',
          'bus_stop': '5분거리',
          'convenience_store': '5분거리',
          'location': '대로변',
          'cctv': '각층',
          'window_condition': '철제창',
          'door_condition': '잘닫침',
          'landlord_personality': '별로',
          'landlord_residence': '없음',
          'nearby_bar': '있음',
          'security_window': '없음',
          'day_atmosphere': '사람들 많이다님',
          'night_atmosphere': '사람들 많이다님',
          'double_lock': '있음',
          'noise_source': '큰 도로',
          'indoor_noise': '있음',
          'double_window': '있음',
          'window_seal': '있음',
          'water_pressure': '보통',
          'leak': '없음',
          'ac_mold': '없음',
          'ac_smell': '없음',
          'ventilation': '됨',
          'mold': '없음',
          'smell': '없음',
          'bugs': '없음',
          'molding': '체리몰딩',
          'window_sheet': '격자무늬 시트지',
          'related_link': '있음',
          'property_info': '확인완료',
          'landlord_info': '확인완료',
          'guide_person': '중개사',
          'memo': '번화가 근처, 소음 주의'
        },
      ),
      PropertyData(
        id: '3',
        name: '신촌 아파트',
        deposit: '2000',
        rent: '40',
        address: '서울특별시 서대문구 신촌동 456-78',
        direction: '서향',
        landlordEnvironment: '매우 친절',
        rating: 5,
        createdAt: DateTime.now().subtract(Duration(days: 3)),
        cellImages: {},
        additionalData: {
          'housing_type': '아파트',
          'building_use': '주거용',
          'lease_registration': '없음',
          'mortgage': '없음',
          'seizure_history': '없음',
          'contract_conditions': '전세',
          'property_register': '확인완료',
          'move_in_date': '협의',
          'resident_registration': '가능',
          'maintenance_fee': '7만원',
          'housing_insurance': '가능',
          'special_terms': '없음',
          'special_notes': '없음',
          'area': '25평대',
          'room_count': '3개',
          'room_structure': '복도형',
          'window_view': '뻥뷰',
          'direction_compass': '정서',
          'lighting': '보통',
          'floor': '5층이상',
          'elevator': '있음',
          'ac_type': '천장형',
          'heating': '중앙난방',
          'veranda': '있음',
          'balcony': '있음',
          'parking': '지하주차장',
          'bathroom': '독립',
          'gas': '도시가스',
          'subway_distance': '15분거리',
          'bus_stop': '10분거리',
          'convenience_store': '10분거리',
          'location': '차도',
          'cctv': '각층',
          'window_condition': '나무창',
          'door_condition': '잘닫침',
          'landlord_personality': '좋은것같음',
          'landlord_residence': '있음',
          'nearby_bar': '없음',
          'security_window': '있음',
          'day_atmosphere': '분위기 좋음',
          'night_atmosphere': '평범함',
          'double_lock': '있음',
          'noise_source': '없음',
          'indoor_noise': '없음',
          'double_window': '있음',
          'window_seal': '있음',
          'water_pressure': '강함',
          'leak': '없음',
          'ac_mold': '없음',
          'ac_smell': '없음',
          'ventilation': '됨',
          'mold': '없음',
          'smell': '없음',
          'bugs': '없음',
          'molding': '화이트몰딩',
          'window_sheet': '없음',
          'related_link': '없음',
          'property_info': '확인완료',
          'landlord_info': '확인완료',
          'guide_person': '중개사',
          'memo': '조용하고 안전한 아파트 단지'
        },
      ),
    ];
  }
}

// 편집 바텀시트 위젯들
class _EditBottomSheet extends StatefulWidget {
  final String columnName;
  final String currentValue;
  final List<String> options;
  final int defaultOptionsCount;
  final Function(String) onSave;
  final Function(String) onAddOption;
  final Function(String)? onDeleteOption;

  const _EditBottomSheet({
    required this.columnName,
    required this.currentValue,
    required this.options,
    this.defaultOptionsCount = 0,
    required this.onSave,
    required this.onAddOption,
    this.onDeleteOption,
  });

  @override
  State<_EditBottomSheet> createState() => _EditBottomSheetState();
}

class _EditBottomSheetState extends State<_EditBottomSheet> {
  late TextEditingController _controller;
  String _selectedValue = '';
  late List<String> _currentOptions;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
    _selectedValue = widget.currentValue;
    _currentOptions = List<String>.from(widget.options);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 새 항목 추가 다이얼로그
  void _showAddOptionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '새 항목 추가',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '새 항목',
                labelStyle: const TextStyle(color: Color(0xFFFF8A65)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF8A65), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _currentOptions.add(controller.text.trim());
                });
                widget.onAddOption(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A65),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  // 간단한 삭제 다이얼로그
  void _showDeleteOptionDialog(String option) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('항목 삭제'),
        content: Text('$option을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentOptions.remove(option);
              });
              if (widget.onDeleteOption != null) {
                widget.onDeleteOption!(option);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.columnName} 편집',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 직접 입력
            TextField(
              controller: _controller,
              cursorColor: Colors.grey[600],
              maxLines: null, // 자동으로 줄 늘어남
              minLines: 1,    // 최소 1줄
              decoration: InputDecoration(
                labelText: '직접 입력',
                labelStyle: TextStyle(color: Colors.grey[600]),
                floatingLabelStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide:
                      const BorderSide(color: Color(0xFFFF8A65), width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide:
                      const BorderSide(color: Color(0xFFFF8A65), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide:
                      const BorderSide(color: Color(0xFFFF8A65), width: 2),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _controller.clear(),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedValue = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // 빠른 선택 옵션들
            if (_currentOptions.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '빠른 선택',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8A65).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: const Color(0xFFFF8A65),
                        width: 1,
                      ),
                    ),
                    child: TextButton.icon(
                      onPressed: _showAddOptionDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('항목 추가'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFF8A65),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _currentOptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = _selectedValue == option;
                  final isDefaultOption = index < widget.defaultOptionsCount;

                  return GestureDetector(
                    onTap: () {
                      try {
                        // 선택된 값으로 즉시 저장하고 바텀시트 닫기
                        widget.onSave(option);
                        Navigator.pop(context);
                      } catch (e) {
                        // 오류 발생 시 기존 방식으로 폴백
                        setState(() {
                          _selectedValue = option;
                          _controller.text = option;
                        });
                      }
                    },
                    onLongPress: isDefaultOption
                        ? null
                        : () => _showDeleteOptionDialog(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF8A65)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF8A65)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              // 옵션이 없을 때 새 항목 추가 버튼
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A65).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: const Color(0xFFFF8A65),
                      width: 1,
                    ),
                  ),
                  child: TextButton.icon(
                    onPressed: _showAddOptionDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('새 항목 추가'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF8A65),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 저장/취소 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      try {
                        widget.onSave(_controller.text);
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('저장 중 오류가 발생했습니다: ${e.toString()}'),
                            backgroundColor: const Color(0xFFFF8A65),
                            duration: const Duration(milliseconds: 800),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A65),
                    ),
                    child: const Text(
                      '저장',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

}
