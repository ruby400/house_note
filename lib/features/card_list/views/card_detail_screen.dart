import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/data/models/property_chart_model.dart';
import 'package:house_note/features/chart/views/image_manager_widgets.dart';
import 'package:house_note/providers/property_chart_providers.dart';
import 'dart:io';

class CardDetailScreen extends ConsumerStatefulWidget {
  static const routeName = 'card-detail';
  static const routePath = ':cardId';

  final String cardId;
  final PropertyData? propertyData;
  final String? chartId;
  final bool isNewProperty;

  const CardDetailScreen({
    super.key,
    required this.cardId,
    this.propertyData,
    this.chartId,
    this.isNewProperty = false,
  });

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  // 실제 PropertyData (나중에 Provider로 가져올 예정)
  PropertyData? propertyData;
  bool isEditMode = false;
  Map<String, String> editedValues = {};
  Map<String, List<String>> dropdownOptions = {};
  Map<String, bool> showPlaceholder = {};
  String? activeDropdownKey; // 현재 활성된 드롭다운의 키
  final ScrollController _scrollController = ScrollController();

  // 각 컬럼별 기본 옵션 정의
  static const Map<String, List<String>> defaultOptions = {
    '주거 형태': ['빌라', '오피스텔', '아파트', '근린생활시설'],
    '건축물용도': ['주거용', '상업용', '혼용'],
    '임차권등기명령 이력': ['유', '무'],
    '근저당권': ['유', '무'],
    '가압류, 압류, 경매 이력': ['유', '무'],
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
    '엘리베이터': ['유', '무'],
    '에어컨 방식': ['천장형', '벽걸이', '중앙냉방'],
    '난방방식': ['보일러', '심야전기', '중앙난방'],
    '베란다': ['유', '무'],
    '발코니': ['유', '무'],
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
    '집주인 거주': ['유', '무'],
    '집근처 술집': ['유', '무'],
    '저층 방범창': ['유', '무'],
    '집주변 낮분위기': ['을씨년스러움', '사람들 많이다님', '사람들 안다님', '평범함', '분위기 좋음', '따뜻함'],
    '집주변 밤분위기': ['을씨년스러움', '무서움', '스산함', '평범함', '사람들 많이다님', '사람들 안다님'],
    '2종 잠금장치': ['유', '무', '설치해준다함'],
    '집 근처 소음원': ['공장', '공사장', '폐기장', '고물상', '큰 도로', '없음'],
    '실내소음': ['있음', '없음', '가벽'],
    '이중창(소음, 외풍)': ['유', '무'],
    '창문 밀폐(미세먼지)': ['유', '무'],
    '수압': ['약함', '보통', '강함'],
    '누수': ['없음', '있음'],
    '에어컨 내부 곰팡이': ['유', '무'],
    '에어컨 냄새': ['유', '무'],
    '환기(공기순환)': ['됨', '안됨'],
    '곰팡이(벽,화장실,베란다)': ['유', '무'],
    '냄새': ['이상함', '퀘퀘함', '담배냄새', '없음'],
    '벌레(바퀴똥)': ['서랍', '씽크대 하부장 모서리', '씽크대 상부장', '없음'],
    '몰딩': ['체리몰딩', '화이트몰딩', '없음', '나무'],
    '창문': ['난초그림시트', '격자무늬 시트지', '네모패턴시트지', '없음'],
    '관련 링크': ['있음', '없음'],
    '부동산 정보': ['확인완료', '미확인'],
    '집주인 정보': ['확인완료', '미확인'],
    '계약시 중개보조인인지 중개사인지 체크': ['중개사', '중개보조인', '미확인'],
    '메모': ['없음', '있음'],
  };

  @override
  void initState() {
    super.initState();
    _initializePropertyData();

    // 새 부동산인 경우 자동으로 편집 모드 활성화
    if (widget.isNewProperty) {
      isEditMode = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 드롭다운 너비 계산 (내용에 따라 동적으로 조정)
  double _calculateDropdownWidth(BuildContext context,
      List<String> defaultOptions, List<String> customOptions) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 모든 옵션의 텍스트 길이를 기반으로 너비 계산
    double maxTextWidth = 0;

    // 기본 옵션들 검사
    for (String option in defaultOptions) {
      double textWidth = option.length * 12.0; // 대략적인 글자당 너비
      if (textWidth > maxTextWidth) {
        maxTextWidth = textWidth;
      }
    }

    // 사용자 정의 옵션들 검사
    for (String option in customOptions) {
      double textWidth = option.length * 12.0;
      if (textWidth > maxTextWidth) {
        maxTextWidth = textWidth;
      }
    }

    // "직접 입력", "새 옵션 추가" 등 고정 버튼들도 고려
    maxTextWidth = maxTextWidth.clamp(180.0, double.infinity);

    // 패딩과 여백을 고려한 최종 너비 계산
    double dropdownWidth = maxTextWidth + 100; // 패딩과 여백 고려

    // 최소 280, 최대 화면 너비의 90%로 제한
    dropdownWidth = dropdownWidth.clamp(280.0, screenWidth * 0.9);

    return dropdownWidth;
  }


  void _initializePropertyData() {
    if (widget.propertyData != null) {
      propertyData = widget.propertyData;
    } else if (widget.chartId != null) {
      // 차트 ID가 있는 경우 해당 차트에서 카드 데이터 찾기
      final chartList = ref.read(propertyChartListProvider);
      final chart = chartList.firstWhere(
        (chart) => chart.id == widget.chartId,
        orElse: () => PropertyChartModel(
          id: widget.chartId!,
          title: '새 차트',
          date: DateTime.now(),
          properties: [],
        ),
      );

      final property = chart.properties.firstWhere(
        (prop) => prop.id == widget.cardId,
        orElse: () => PropertyData(
          id: widget.cardId,
          order: '',
          name: '',
          deposit: '',
          rent: '',
          direction: '',
          landlordEnvironment: '',
          rating: 0,
        ),
      );

      propertyData = property;

      // 차트의 컬럼 옵션을 dropdownOptions에 로드
      _loadChartOptions(chart);
    } else {
      // 기본값 생성
      propertyData = PropertyData(
        id: widget.cardId,
        order: '',
        name: '',
        deposit: '',
        rent: '',
        direction: '',
        landlordEnvironment: '',
        rating: 0,
      );
    }
  }

  void _loadChartOptions(PropertyChartModel chart) {
    // 차트의 columnOptions를 dropdownOptions에 복사
    chart.columnOptions.forEach((columnName, options) {
      // 차트의 컬럼명을 카드의 키로 변환하는 매핑
      String? mappedKey = _getCardKeyFromChartColumnName(columnName);

      if (mappedKey != null) {
        dropdownOptions[mappedKey] = List<String>.from(options);
      }
    });
  }

  // 차트 컬럼명을 카드 키로 변환하는 메서드
  String? _getCardKeyFromChartColumnName(String columnName) {
    const chartToCardKeyMap = {
      // 기본 컬럼
      '재계/방향': 'direction',
      '집주인 환경': 'landlord_environment',
      '집 이름': 'name',
      '보증금': 'deposit',
      '월세': 'rent',
      // 표준 항목들 - 차트와 카드가 동일한 키 사용
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
      '계약시 중개보조인인지 중개사인지 체크': 'agent_check',
      '메모': 'memo',
    };

    return chartToCardKeyMap[columnName];
  }

  // 카드 키를 차트 컬럼명으로 변환하는 메서드
  String? _getChartColumnNameFromCardKey(String key) {
    const cardToChartColumnMap = {
      // 기본 컬럼
      'direction': '재계/방향',
      'landlord_environment': '집주인 환경',
      'name': '집 이름',
      'deposit': '보증금',
      'rent': '월세',
      // 표준 항목들
      'housing_type': '주거 형태',
      'building_use': '건축물용도',
      'lease_registration': '임차권등기명령 이력',
      'mortgage': '근저당권',
      'seizure_history': '가압류, 압류, 경매 이력',
      'contract_conditions': '계약 조건',
      'property_register': '등기부등본(말소사항 포함으로)',
      'move_in_date': '입주 가능일',
      'resident_registration': '전입신고',
      'maintenance_fee': '관리비',
      'housing_insurance': '주택보증보험',
      'special_terms': '특약',
      'special_notes': '특이사항',
      'area': '평수',
      'room_count': '방개수',
      'room_structure': '방구조',
      'window_view': '창문 뷰',
      'compass_direction': '방향(나침반)',
      'lighting': '채광',
      'floor': '층수',
      'elevator': '엘리베이터',
      'air_conditioning': '에어컨 방식',
      'heating': '난방방식',
      'veranda': '베란다',
      'balcony': '발코니',
      'parking': '주차장',
      'bathroom': '화장실',
      'gas_type': '가스',
      'subway_distance': '지하철 거리',
      'bus_distance': '버스 정류장',
      'convenience_store': '편의점 거리',
      'location_type': '위치',
      'cctv': 'cctv 여부',
      'window_condition': '창문 상태',
      'door_condition': '문 상태',
      'landlord_residence': '집주인 거주',
      'nearby_bars': '집근처 술집',
      'security_bars': '저층 방범창',
      'day_atmosphere': '집주변 낮분위기',
      'night_atmosphere': '집주변 밤분위기',
      'double_lock': '2종 잠금장치',
      'noise_source': '집 근처 소음원',
      'indoor_noise': '실내소음',
      'double_window': '이중창(소음, 외풍)',
      'window_seal': '창문 밀폐(미세먼지)',
      'water_pressure': '수압',
      'water_leak': '누수',
      'ac_mold': '에어컨 내부 곰팡이',
      'ac_smell': '에어컨 냄새',
      'ventilation': '환기(공기순환)',
      'mold': '곰팡이(벽,화장실,베란다)',
      'smell': '냄새',
      'insects': '벌레(바퀴똥)',
      'molding': '몰딩',
      'window_film': '창문',
      'related_links': '관련 링크',
      'real_estate_info': '부동산 정보',
      'landlord_info': '집주인 정보',
      'agent_check': '계약시 중개보조인인지 중개사인지 체크',
      'memo': '메모',
    };

    return cardToChartColumnMap[key];
  }

  // 기본 컬럼인지 확인하는 헬퍼 메서드
  bool _isBaseColumn(String columnName) {
    const baseColumns = {'재계/방향', '집주인 환경', '집 이름', '보증금', '월세', '순', '별점'};
    return baseColumns.contains(columnName);
  }

  // 차트 데이터를 기반으로 동적 카테고리 생성
  Map<String, List<Map<String, dynamic>>> _getCategories() {
    if (widget.chartId == null) {
      // 차트 ID가 없으면 기본 카테고리 반환
      return _getDefaultCategories();
    }

    final chartList = ref.read(propertyChartListProvider);
    final chart = chartList.firstWhere(
      (chart) => chart.id == widget.chartId,
      orElse: () => PropertyChartModel(
        id: widget.chartId!,
        title: '새 차트',
        date: DateTime.now(),
        properties: [],
      ),
    );

    // 기본 카테고리에 차트의 추가 컬럼들을 동적으로 추가
    final categories = _getDefaultCategories();

    // 차트에서 사용되는 추가 컬럼들을 '차트 등록 항목'으로 분류
    final chartColumns = <Map<String, dynamic>>[];

    // 모든 PropertyData의 additionalData에서 사용된 키들을 수집
    final usedKeys = <String>{};
    for (final property in chart.properties) {
      usedKeys.addAll(property.additionalData.keys);
    }

    // 모든 형태의 키들을 실제 컬럼명으로 변환
    for (final key in usedKeys) {
      String? columnName;

      // 표준 항목 키들을 컬럼명으로 역변환
      final reverseMapping = _getChartColumnNameFromCardKey(key);
      if (reverseMapping != null) {
        columnName = reverseMapping;
      } else if (key.startsWith('col_')) {
        final columnIndex = int.tryParse(key.substring(4));
        if (columnIndex != null && columnIndex >= 7) {
          // 차트의 컬럼 옵션에서 실제 컬럼명 찾기
          columnName = '추가 항목 ${columnIndex - 6}';

          // 차트의 columnOptions에서 실제 컬럼명 찾기
          chart.columnOptions.forEach((optionKey, values) {
            if (!_isBaseColumn(optionKey)) {
              columnName = optionKey;
            }
          });
        }
      } else if (key.startsWith('custom_')) {
        // custom_ 키에서 실제 컬럼명 추출
        final extractedName = key.substring(7); // 'custom_' 제거
        columnName = extractedName.replaceAll('_', ' '); // 언더스코어를 공백으로 변환

        // 차트의 columnOptions에서 실제 컬럼명 찾기
        chart.columnOptions.forEach((optionKey, values) {
          if (!_isBaseColumn(optionKey)) {
            if (optionKey.contains(extractedName) ||
                extractedName.contains(optionKey)) {
              columnName = optionKey;
            }
          }
        });
      }

      if (columnName != null) {
        chartColumns.add({
          'key': key,
          'label': columnName,
        });
      }
    }

    if (chartColumns.isNotEmpty) {
      categories['차트 등록 항목'] = chartColumns;
    }

    return categories;
  }

  // 기본 카테고리 정의
  Map<String, List<Map<String, dynamic>>> _getDefaultCategories() {
    return {
      '필수 정보': [
        {'key': 'housing_type', 'label': '주거 형태'},
        {'key': 'building_use', 'label': '건축물용도'},
        {'key': 'lease_registration', 'label': '임차권등기명령 이력'},
        {'key': 'mortgage', 'label': '근저당권'},
        {'key': 'seizure_history', 'label': '가압류, 압류, 경매 이력'},
        {'key': 'contract_conditions', 'label': '계약 조건'},
        {'key': 'property_register', 'label': '등기부등본(말소사항 포함으로)'},
        {'key': 'move_in_date', 'label': '입주 가능일'},
        {'key': 'resident_registration', 'label': '전입신고'},
        {'key': 'maintenance_fee', 'label': '관리비'},
        {'key': 'housing_insurance', 'label': '주택보증보험'},
        {'key': 'special_terms', 'label': '특약'},
        {'key': 'special_notes', 'label': '특이사항'},
      ],
      '부동산 상세 정보': [
        {'key': 'area', 'label': '평수'},
        {'key': 'room_count', 'label': '방개수'},
        {'key': 'room_structure', 'label': '방구조'},
        {'key': 'window_view', 'label': '창문 뷰'},
        {'key': 'compass_direction', 'label': '방향(나침반)'},
        {'key': 'lighting', 'label': '채광'},
        {'key': 'floor', 'label': '층수'},
        {'key': 'elevator', 'label': '엘리베이터'},
        {'key': 'air_conditioning', 'label': '에어컨 방식'},
        {'key': 'heating', 'label': '난방방식'},
        {'key': 'veranda', 'label': '베란다'},
        {'key': 'balcony', 'label': '발코니'},
        {'key': 'parking', 'label': '주차장'},
        {'key': 'bathroom', 'label': '화장실'},
        {'key': 'gas_type', 'label': '가스'},
      ],
      '교통 및 편의시설': [
        {'key': 'subway_distance', 'label': '지하철 거리'},
        {'key': 'bus_distance', 'label': '버스 정류장'},
        {'key': 'convenience_store', 'label': '편의점 거리'},
      ],
      '치안 관련': [
        {'key': 'location_type', 'label': '위치'},
        {'key': 'cctv', 'label': 'cctv 여부'},
        {'key': 'window_condition', 'label': '창문 상태'},
        {'key': 'door_condition', 'label': '문 상태'},
        {'key': 'landlord_environment', 'label': '집주인 성격'},
        {'key': 'landlord_residence', 'label': '집주인 거주'},
        {'key': 'nearby_bars', 'label': '집근처 술집'},
        {'key': 'security_bars', 'label': '저층 방범창'},
        {'key': 'day_atmosphere', 'label': '집주변 낮분위기'},
        {'key': 'night_atmosphere', 'label': '집주변 밤분위기'},
        {'key': 'double_lock', 'label': '2종 잠금장치'},
      ],
      '환경 및 청결': [
        {'key': 'noise_source', 'label': '집 근처 소음원'},
        {'key': 'indoor_noise', 'label': '실내소음'},
        {'key': 'double_window', 'label': '이중창(소음, 외풍)'},
        {'key': 'window_seal', 'label': '창문 밀폐(미세먼지)'},
        {'key': 'water_pressure', 'label': '수압'},
        {'key': 'water_leak', 'label': '누수'},
        {'key': 'ac_mold', 'label': '에어컨 내부 곰팡이'},
        {'key': 'ac_smell', 'label': '에어컨 냄새'},
        {'key': 'ventilation', 'label': '환기(공기순환)'},
        {'key': 'mold', 'label': '곰팡이(벽,화장실,베란다)'},
        {'key': 'smell', 'label': '냄새'},
        {'key': 'insects', 'label': '벌레(바퀴똥)'},
      ],
      '미관 및 기타': [
        {'key': 'molding', 'label': '몰딩'},
        {'key': 'window_film', 'label': '창문'},
        {'key': 'related_links', 'label': '관련 링크'},
        {'key': 'real_estate_info', 'label': '부동산 정보'},
        {'key': 'landlord_info', 'label': '집주인 정보'},
        {'key': 'agent_check', 'label': '계약시 중개보조인인지 중개사인지 체크'},
        {'key': 'memo', 'label': '메모'},
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    if (propertyData == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: const Text(
            '집 상세정보',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
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
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          (editedValues['name']?.isNotEmpty == true
                      ? editedValues['name']!
                      : propertyData!.name)
                  .isNotEmpty
              ? (editedValues['name']?.isNotEmpty == true
                  ? editedValues['name']!
                  : propertyData!.name)
              : '집 이름',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 갤러리
            Container(
              height: 140,
              padding: const EdgeInsets.all(16),
              child: _buildImageGallery(),
            ),

            // 기본 정보 요약
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이름 편집
                  isEditMode
                      ? TextField(
                          controller: TextEditingController(
                            text: editedValues['name'] ?? propertyData!.name,
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            hintText: '집 이름',
                          ),
                          onChanged: (value) {
                            setState(() {
                              editedValues['name'] = value;
                            });
                          },
                        )
                      : Text(
                          propertyData!.name.isNotEmpty
                              ? propertyData!.name
                              : '집 이름',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                  const SizedBox(height: 12),
                  // 별점 편집
                  Row(
                    children: [
                      isEditMode
                          ? Row(
                              children: List.generate(5, (index) {
                                final currentRating = int.tryParse(
                                        editedValues['rating'] ?? '') ??
                                    propertyData!.rating;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      editedValues['rating'] =
                                          (index + 1).toString();
                                    });
                                  },
                                  child: Icon(
                                    index < currentRating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 24,
                                  ),
                                );
                              }),
                            )
                          : Row(
                              children: List.generate(
                                  5,
                                  (index) => Icon(
                                        index < propertyData!.rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 20,
                                      )),
                            ),
                      const SizedBox(width: 8),
                      Text(
                        '${int.tryParse(editedValues['rating'] ?? '') ?? propertyData!.rating}/5',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildSummaryItem(
                          '보증금', propertyData!.deposit, 'deposit'),
                      const SizedBox(width: 16),
                      _buildSummaryItem('월세', propertyData!.rent, 'rent'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 카테고리별 정보 섹션들
            ..._getCategories().entries.map((entry) => _buildInfoSection(
                  entry.key,
                  entry.value,
                  _getCategoryColor(entry.key),
                )),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: widget.isNewProperty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF8A65)),
                        foregroundColor: const Color(0xFFFF8A65),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveNewProperty,
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
            )
          : null,
      floatingActionButton: !widget.isNewProperty
          ? FloatingActionButton(
              onPressed: () {
                if (isEditMode) {
                  _saveChanges();
                }
                if (mounted) {
                  setState(() {
                    isEditMode = !isEditMode;
                  });
                }
              },
              backgroundColor: const Color(0xFFFF8A65),
              child: Icon(
                isEditMode ? Icons.check : Icons.edit,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  Widget _buildImageGallery() {
    final List<String> allImages = propertyData?.cellImages['gallery'] ?? [];

    if (allImages.isEmpty) {
      // 편집 모드 여부에 관계없이 3개의 네모 박스 표시
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 0; i < 3; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: i == 1 ? 8 : 4),
                child: GestureDetector(
                  onTap: isEditMode ? () => _showImageManager('gallery') : null,
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isEditMode
                            ? const Color.fromARGB(255, 243, 242, 242)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isEditMode
                              ? const Color.fromARGB(255, 224, 224, 224)
                              : Colors.grey[300]!,
                          width: isEditMode ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isEditMode
                                ? Icons.add_a_photo
                                : Icons.image_outlined,
                            size: isEditMode ? 32 : 28,
                            color: isEditMode
                                ? Colors.grey[400]
                                : Colors.grey[500],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isEditMode ? '사진 추가' : '사진 없음',
                            style: TextStyle(
                              fontSize: 11,
                              color: isEditMode
                                  ? Colors.grey[500]
                                  : Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // 사진이 있을 때는 모든 사진을 썸네일로 표시 + (편집모드일 때만) 추가 버튼
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: isEditMode
          ? allImages.length + 1
          : allImages.length, // 편집모드일 때만 추가 버튼
      itemBuilder: (context, index) {
        if (index < allImages.length) {
          // 기존 이미지 썸네일
          return Container(
            width: 110,
            height: 110,
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => isEditMode
                  ? _showImageManager('gallery') // 편집모드: 이미지 관리
                  : _showImageViewer(allImages, index), // 보기모드: 이미지 뷰어
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Stack(
                    children: [
                      Image.file(
                        File(allImages[index]),
                        width: 110,
                        height: 110,
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
                      // 첫 번째 이미지에 대표 라벨
                      if (index == 0)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8A65),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Text(
                              '대표',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      // 사진 순서 표시
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          // 맨 마지막에 추가 버튼
          return Container(
            width: 110,
            height: 110,
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _showImageManager('gallery'),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF8A65),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 24,
                      color: Color(0xFFFF8A65),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '추가',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFF8A65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, [String? key]) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            isEditMode && key != null
                ? TextField(
                    controller: TextEditingController(
                      text: editedValues[key] ?? value,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: '입력하세요',
                    ),
                    onChanged: (newValue) {
                      editedValues[key] = newValue;
                    },
                  )
                : Text(
                    value.isNotEmpty ? value : '-',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      String title, List<Map<String, dynamic>> items, Color backgroundColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i += 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              items[i]['label'],
                              _getPropertyValue(items[i]['key']),
                              items[i]['key'],
                            ),
                          ),
                          if (i + 1 < items.length) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoRow(
                                items[i + 1]['label'],
                                _getPropertyValue(items[i + 1]['key']),
                                items[i + 1]['key'],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(width: 12),
                            const Expanded(child: SizedBox()),
                          ],
                        ],
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

  Widget _buildInfoRow(String label, String value, [String? key]) {
    Widget child = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: activeDropdownKey == key
                  ? const Color(0xFFFF8A65)
                  : Colors.grey[200]!,
              width: activeDropdownKey == key ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 레이블 섹션
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isEditMode && key != null)
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: const Color(0xFFBDBDBD),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF757575),
                    size: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // 값 섹션
          SizedBox(
            height: 24,
            child: isEditMode
                ? _buildEditableField(key, editedValues[key] ?? value)
                : (editedValues[key] ?? value).isNotEmpty
                    ? Text(
                        editedValues[key] ?? value,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: null,
                      )
                    : Container(),
          ),
        ]));

    // 편집 모드이고 키가 있을 때만 Builder와 GestureDetector로 감싸기
    if (isEditMode && key != null) {
      return Builder(
        builder: (BuildContext buttonContext) {
          return GestureDetector(
            onTap: () {
              // 활성 상태 설정
              setState(() {
                activeDropdownKey = key;
              });

              _showCustomDropdown(buttonContext, key, label);
            },
            child: child,
          );
        },
      );
    }

    return child;
  }

  // 커스텀 드롭다운 표시 메서드
  void _showCustomDropdown(BuildContext context, String key, String label) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    // 드롭다운 높이를 내용에 맞게 정확히 계산
    final List<String> options = dropdownOptions[key] ?? [];
    final List<String> defaultOptionsForLabel = defaultOptions[label] ?? [];

    // 각 요소의 실제 높이 계산
    double contentHeight = 0;

    // 직접 입력 버튼 (고정)
    contentHeight += 50; // padding + height

    // 기본 옵션 섹션
    if (defaultOptionsForLabel.isNotEmpty) {
      contentHeight += 35; // 헤더 높이
      // Wrap을 사용하므로 대략적인 줄 수 계산 (화면 너비 기준)
      final estimatedRows =
          (defaultOptionsForLabel.length / 3).ceil(); // 한 줄에 약 3개 예상
      contentHeight += estimatedRows * 45; // 각 줄당 45px
    }

    // 사용자 정의 옵션들
    contentHeight += options.length * 40; // 각 옵션당 40px

    // 새 옵션 추가 버튼
    contentHeight += 60; // 버튼 높이 + 여백

    // 여백 추가 (충분한 공간 확보)
    contentHeight += 30;

    // 화면 높이에 따라 최대 높이 제한
    final screenHeight = MediaQuery.of(context).size.height;
    final maxAllowedHeight = screenHeight * 0.7; // 화면의 70%까지 허용
    final estimatedHeight = contentHeight.clamp(200.0, maxAllowedHeight);

    final dropdownWidth =
        _calculateDropdownWidth(context, defaultOptionsForLabel, options);

    // 드롭다운 위치 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    final buttonBottom = position.dy + buttonSize.height;
    final spaceBelow = screenHeight - buttonBottom - safeAreaBottom - 10;

    late RelativeRect relativePosition;

    // 더 간단한 방식으로 RelativeRect 계산
    if (spaceBelow >= estimatedHeight) {
      // 아래에 충분한 공간이 있으면 네모칸 바로 아래에 표시
      relativePosition = RelativeRect.fromRect(
        Rect.fromLTWH(
            position.dx, buttonBottom, dropdownWidth, estimatedHeight),
        Rect.fromLTWH(0, 0, screenWidth, screenHeight),
      );
    } else {
      // 위에 표시
      final topPosition = position.dy - estimatedHeight;
      relativePosition = RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, topPosition, dropdownWidth, estimatedHeight),
        Rect.fromLTWH(0, 0, screenWidth, screenHeight),
      );
    }

    showMenu<String>(
      context: context,
      position: relativePosition,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFFFCC80), width: 2), // 연한 주황색 테두리
      ),
      color: Colors.white,
      elevation: 8,
      constraints: const BoxConstraints(),
      items: _buildDropdownItems(key, label, defaultOptionsForLabel, options,
          dropdownWidth, estimatedHeight),
    ).then((String? value) {
      // 드롭다운 닫힐 때 활성 상태 초기화
      setState(() {
        activeDropdownKey = null;
      });

      if (value != null) {
        _handleDropdownSelection(value, key, label);
      }
    });
  }

  // 드롭다운 아이템들을 생성하는 메서드
  List<PopupMenuEntry<String>> _buildDropdownItems(
      String key,
      String label,
      List<String> defaultOptionsForLabel,
      List<String> options,
      double dropdownWidth,
      double estimatedHeight) {
    return [
      PopupMenuItem<String>(
        value: null,
        enabled: false,
        padding: EdgeInsets.zero,
        child: Container(
          width: dropdownWidth,
          constraints: BoxConstraints(
            maxHeight: estimatedHeight,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 직접 입력 버튼
                GestureDetector(
                  onTap: () => Navigator.pop(context, 'direct_input'),
                  child: Container(
                    width: double.infinity,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 16, color: Color(0xFF718096)),
                        SizedBox(width: 8),
                        Text(
                          '직접 입력',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 기본 옵션 섹션
                if (defaultOptionsForLabel.isNotEmpty) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    child: const Row(
                      children: [
                        Icon(Icons.apps,
                            size: 16, color: Color(0xFFFF8A65)),
                        SizedBox(width: 8),
                        Text(
                          '기본 옵션',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF8A65),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 기본 옵션들을 Wrap으로 배치 (동적 너비 지원)
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Wrap(
                      spacing: 6.0, // 버튼 간 수평 간격
                      runSpacing: 4.0, // 줄 간 간격
                      children: defaultOptionsForLabel
                          .map((option) => GestureDetector(
                                onTap: () => Navigator.pop(context, option),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFFF8A65),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF8A65)
                                            .withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    option,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF8A65),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],

                // 사용자 정의 옵션들
                if (options.isNotEmpty) ...[
                  ...options.map((option) => GestureDetector(
                        onTap: () => Navigator.pop(context, option),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.grey[300]!, width: 1),
                          ),
                          child: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ),
                      )),
                ],

                // 새 옵션 추가 버튼
                GestureDetector(
                  onTap: () => Navigator.pop(context, 'add_new'),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFAB91), Color(0xFFFF8A65)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle,
                            size: 22,
                            color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          '새 옵션 추가',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 추가 여백 (마지막 버튼이 잘리지 않도록)
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  // 드롭다운 선택 처리 메서드
  void _handleDropdownSelection(String value, String key, String label) {
    if (value == 'direct_input') {
      if (mounted) {
        setState(() {
          showPlaceholder[key] = true;
        });
      }
    } else if (value == 'add_new') {
      _showAddOptionDialog(key);
    } else {
      if (mounted) {
        setState(() {
          editedValues[key] = value;
          showPlaceholder[key] = false;

          // dropdownOptions에도 추가 (기본 옵션에서 선택한 경우)
          if (!dropdownOptions.containsKey(key)) {
            dropdownOptions[key] = [];
          }
          if (!dropdownOptions[key]!.contains(value)) {
            dropdownOptions[key]!.add(value);
          }
        });

        // 차트의 컬럼 옵션에도 추가
        _addToChartOptions(key, value);

        // 기본 옵션에서 선택했을 때 스낵바 표시
        final List<String> defaultOptionsForLabel = defaultOptions[label] ?? [];
        if (defaultOptionsForLabel.contains(value)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$value" 옵션이 선택되었습니다.',
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
      }
    }
  }

  String _getPropertyValue(String key) {
    switch (key) {
      case 'order':
        return propertyData!.order;
      case 'name':
        return propertyData!.name;
      case 'deposit':
        return propertyData!.deposit;
      case 'rent':
        return propertyData!.rent;
      case 'direction':
        return propertyData!.direction;
      case 'landlord_environment':
        return propertyData!.landlordEnvironment;
      case 'rating':
        return propertyData!.rating.toString();
      case 'memo':
        return propertyData!.memo ?? '';
      default:
        // Handle all other additional data
        return propertyData!.additionalData[key] ?? '';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '기본 정보':
        return const Color(0xFFE8F4FD); // 부드러운 블루
      case '필수 정보':
        return const Color(0xFFFFE4E6); // 따뜻한 핑크
      case '부동산 상세 정보':
        return const Color(0xFFFFF8E1); // 밝은 엠버
      case '교통 및 편의시설':
        return const Color(0xFFF3E5F5); // 연한 퍼플
      case '치안 관련':
        return const Color(0xFFE8F5E8); // 부드러운 그린
      case '환경 및 청결':
        return const Color(0xFFE0F2F1); // 민트 그린
      case '미관 및 기타':
        return const Color(0xFFFFF3E0); // 따뜻한 오렌지
      case '차트 등록 항목':
        return const Color(0xFFE3F2FD); // 밝은 블루
      default:
        return const Color(0xFFF8F9FA); // 중성 그레이
    }
  }

  Widget _buildEditableField(String? key, String value) {
    final bool shouldShowPlaceholder =
        key != null && (showPlaceholder[key] ?? false);

    // 직접입력 버튼을 눌렀을 때만 TextField 표시
    if (shouldShowPlaceholder) {
      return TextField(
        controller: TextEditingController(text: value),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '입력하세요',
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        maxLines: null,
        minLines: 1,
        autofocus: true,
        onChanged: (newValue) {
          editedValues[key] = newValue;
        },
      );
    } else {
      // 기본 상태에서는 텍스트만 표시
      return Text(
        value.isEmpty ? '' : value,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  void _showAddOptionDialog(String key) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  child: const Icon(Icons.add_circle_outline,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                const Text(
                  '새 옵션 추가',
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
                  '새로운 옵션을 추가하여 선택할 수 있습니다.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6D4C41)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: '옵션 이름',
                  labelStyle: const TextStyle(color: Color(0xFFFF8A65)),
                  hintText: '새 옵션을 입력하세요',
                  hintStyle: const TextStyle(color: Color(0xFFBCAAA4)),
                  prefixIcon: const Icon(Icons.edit, color: Color(0xFFFF8A65)),
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
              onPressed: () => Navigator.pop(context),
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
                  if (controller.text.isNotEmpty) {
                    if (mounted) {
                      setState(() {
                        if (!dropdownOptions.containsKey(key)) {
                          dropdownOptions[key] = [];
                        }
                        dropdownOptions[key]!.add(controller.text);
                        editedValues[key] = controller.text;
                        showPlaceholder[key] = false;
                      });

                      // 차트의 컬럼 옵션에도 추가
                      _addToChartOptions(key, controller.text);
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${controller.text}" 옵션이 추가되었습니다.',
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

  void _addToChartOptions(String key, String option) {
    if (widget.chartId == null) return;

    final chartList = ref.read(propertyChartListProvider);
    final chart = chartList.firstWhere(
      (chart) => chart.id == widget.chartId,
      orElse: () => PropertyChartModel(
        id: widget.chartId!,
        title: '새 차트',
        date: DateTime.now(),
        properties: [],
      ),
    );

    // 키에 맞는 컬럼명 찾기
    String columnName = _getChartColumnNameFromCardKey(key) ?? '새 컬럼';

    // 차트의 컬럼 옵션 업데이트
    final updatedColumnOptions =
        Map<String, List<String>>.from(chart.columnOptions);
    if (!updatedColumnOptions.containsKey(columnName)) {
      updatedColumnOptions[columnName] = [];
    }
    if (!updatedColumnOptions[columnName]!.contains(option)) {
      updatedColumnOptions[columnName]!.add(option);
    }

    final updatedChart = chart.copyWith(columnOptions: updatedColumnOptions);
    ref.read(propertyChartListProvider.notifier).updateChart(updatedChart);
  }

  void _saveChanges() {
    // PropertyData는 immutable이므로 copyWith를 사용해서 업데이트
    Map<String, String> additionalDataUpdate =
        Map.from(propertyData!.additionalData);

    for (String key in editedValues.keys) {
      switch (key) {
        case 'order':
          propertyData = propertyData!.copyWith(order: editedValues[key]!);
          break;
        case 'name':
          propertyData = propertyData!.copyWith(name: editedValues[key]!);
          break;
        case 'deposit':
          propertyData = propertyData!.copyWith(deposit: editedValues[key]!);
          break;
        case 'rent':
          propertyData = propertyData!.copyWith(rent: editedValues[key]!);
          break;
        case 'direction':
          propertyData = propertyData!.copyWith(direction: editedValues[key]!);
          break;
        case 'landlord_environment':
          propertyData =
              propertyData!.copyWith(landlordEnvironment: editedValues[key]!);
          break;
        case 'rating':
          propertyData = propertyData!
              .copyWith(rating: int.tryParse(editedValues[key]!) ?? 0);
          break;
        case 'memo':
          propertyData = propertyData!.copyWith(memo: editedValues[key]!);
          break;
        default:
          additionalDataUpdate[key] = editedValues[key]!;
      }
    }

    // additionalData 업데이트가 있는 경우
    if (additionalDataUpdate != propertyData!.additionalData) {
      propertyData =
          propertyData!.copyWith(additionalData: additionalDataUpdate);
    }

    // 실제 차트 데이터에 변경사항 반영
    final chartList = ref.read(propertyChartListProvider);
    for (var chart in chartList) {
      final propertyIndex =
          chart.properties.indexWhere((p) => p.id == propertyData!.id);
      if (propertyIndex != -1) {
        // 해당 차트에서 부동산 데이터 업데이트
        final updatedProperties = List<PropertyData>.from(chart.properties);
        updatedProperties[propertyIndex] = propertyData!;

        final updatedChart = chart.copyWith(properties: updatedProperties);
        ref.read(propertyChartListProvider.notifier).updateChart(updatedChart);
        break;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('변경사항이 저장되었습니다')),
    );
  }

  void _saveNewProperty() {
    if (propertyData == null || widget.chartId == null) return;

    // Apply edited values to propertyData
    Map<String, String> additionalDataUpdate =
        Map.from(propertyData!.additionalData);

    for (String key in editedValues.keys) {
      switch (key) {
        case 'order':
          propertyData = propertyData!.copyWith(order: editedValues[key]!);
          break;
        case 'name':
          propertyData = propertyData!.copyWith(name: editedValues[key]!);
          break;
        case 'deposit':
          propertyData = propertyData!.copyWith(deposit: editedValues[key]!);
          break;
        case 'rent':
          propertyData = propertyData!.copyWith(rent: editedValues[key]!);
          break;
        case 'direction':
          propertyData = propertyData!.copyWith(direction: editedValues[key]!);
          break;
        case 'landlord_environment':
          propertyData =
              propertyData!.copyWith(landlordEnvironment: editedValues[key]!);
          break;
        case 'rating':
          propertyData = propertyData!
              .copyWith(rating: int.tryParse(editedValues[key]!) ?? 0);
          break;
        case 'memo':
          propertyData = propertyData!.copyWith(memo: editedValues[key]!);
          break;
        default:
          additionalDataUpdate[key] = editedValues[key]!;
      }
    }

    // Update additionalData if needed
    if (additionalDataUpdate != propertyData!.additionalData) {
      propertyData =
          propertyData!.copyWith(additionalData: additionalDataUpdate);
    }

    // Set current chart to the target chart
    final chartList = ref.read(propertyChartListProvider);
    final targetChart = chartList.firstWhere(
      (chart) => chart.id == widget.chartId,
      orElse: () => PropertyChartModel(
        id: widget.chartId!,
        title: '새 차트',
        date: DateTime.now(),
        properties: [],
      ),
    );

    // Add the property to the chart
    ref.read(currentChartProvider.notifier).setChart(targetChart);
    ref.read(currentChartProvider.notifier).addProperty(propertyData!);

    // Update the chart in the main list
    final updatedChart = ref.read(currentChartProvider)!;
    ref.read(propertyChartListProvider.notifier).updateChart(updatedChart);

    // Show success message and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('새 부동산이 저장되었습니다')),
    );

    // Navigate back to card list
    Navigator.of(context).pop();
  }

  void _showImageManager(String cellKey) {
    final List<String> currentImages = propertyData?.cellImages[cellKey] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ImageManagerBottomSheet(
            rowIndex: 0,
            columnIndex: 0,
            columnName: _getCellDisplayName(cellKey),
            cellKey: cellKey,
            initialImages: currentImages,
            onImageAdded: (String imagePath) {
              if (mounted) {
                setState(() {
                  final currentImages = propertyData?.cellImages[cellKey] ?? [];
                  final updatedImages = List<String>.from(currentImages);
                  updatedImages.add(imagePath);

                  final updatedCellImages =
                      Map<String, List<String>>.from(propertyData!.cellImages);
                  updatedCellImages[cellKey] = updatedImages;

                  propertyData =
                      propertyData!.copyWith(cellImages: updatedCellImages);
                });
              }
            },
            onImageDeleted: (String imagePath) {
              if (mounted) {
                setState(() {
                  final currentImages = propertyData?.cellImages[cellKey] ?? [];
                  final updatedImages = List<String>.from(currentImages);
                  updatedImages.remove(imagePath);

                  final updatedCellImages =
                      Map<String, List<String>>.from(propertyData!.cellImages);
                  updatedCellImages[cellKey] = updatedImages;

                  propertyData =
                      propertyData!.copyWith(cellImages: updatedCellImages);
                });
              }
            },
          ),
        ),
      ),
    );
  }

  String _getCellDisplayName(String cellKey) {
    switch (cellKey) {
      case 'gallery':
        return '사진 갤러리';
      default:
        return '사진';
    }
  }

  void _showImageViewer(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          int currentIndex = initialIndex;

          return Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                // 이미지 페이지뷰
                PageView.builder(
                  controller: PageController(initialPage: initialIndex),
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Center(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: Image.file(
                          File(images[index]),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.white,
                                size: 64,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                // 닫기 버튼
                Positioned(
                  top: 50,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                // 이미지 인덱스 표시
                if (images.length > 1)
                  Positioned(
                    bottom: 50,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentIndex + 1} / ${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
