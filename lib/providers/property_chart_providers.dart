import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/core/utils/logger.dart';
import 'package:house_note/data/models/property_chart_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

// 전체 차트 목록 상태
class PropertyChartListNotifier extends StateNotifier<List<PropertyChartModel>> {
  PropertyChartListNotifier() : super([]) {
    _loadChartsFromStorage();
  }

  // 현재 사용자의 저장소 키 생성
  String _getUserStorageKey() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return 'local_charts_${user.uid}';
    }
    return 'local_charts_guest';
  }

  // 로컬 저장소에서 차트 불러오기
  Future<void> _loadChartsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = _getUserStorageKey();
      final chartsJson = prefs.getString(storageKey);
      
      AppLogger.info('차트 로드 - 사용자: ${FirebaseAuth.instance.currentUser?.uid ?? "guest"}, 키: $storageKey');
      
      if (chartsJson != null) {
        final chartsList = jsonDecode(chartsJson) as List;
        final charts = chartsList
            .map((json) => PropertyChartModel.fromJson(json))
            .toList();
        
        AppLogger.info('로컬 저장소에서 ${charts.length}개 차트 불러옴');
        state = charts;
      } else {
        // 저장된 차트가 없으면 기본 예시 차트 생성
        _createDefaultChart();
      }
    } catch (e) {
      AppLogger.error('로컬 차트 로드 실패', error: e);
      _createDefaultChart();
    }
  }

  // 기본 예시 차트 생성
  void _createDefaultChart() {
    final defaultChart = PropertyChartModel(
      id: '1',
      title: '예시 차트',
      date: DateTime.now(),
      properties: [
        PropertyData(
          id: '1',
          // order field removed
          name: '서라벌 오피스텔',
          deposit: '1000',
          rent: '55',
          direction: '남향',
          landlordEnvironment: '친절함',
          rating: 4,
          address: '서울시 강남구 역삼로 234',
          createdAt: DateTime.now(),
          cellImages: {},
          additionalData: {
            'housing_type': '오피스텔',
            'room_structure': '원룸',
            'window_view': '뻥뷰',
            'elevator': '있음',
            'parking': '지하주차장',
            'heating': '중앙난방',
            'landlord_residence': '없음',
            'double_lock': '있음',
          },
        ),
        PropertyData(
          id: '2',
          // order field removed
          name: '라인빌',
          deposit: '2000',
          rent: '75',
          direction: '동향',
          landlordEnvironment: '보통',
          rating: 3,
          address: '서울시 마포구 동교로 15길',
          createdAt: DateTime.now(),
          cellImages: {},
          additionalData: {
            'housing_type': '빌라',
            'room_structure': '1.5룸',
            'window_view': '옆건물 가까움',
            'elevator': '없음',
            'parking': '지상주차장',
            'heating': '보일러',
            'landlord_residence': '있음',
            'double_lock': '설치해준다함',
          },
        ),
        PropertyData(
          id: '3',
          // order field removed
          name: '신촌센트럴빌',
          deposit: '1500',
          rent: '65',
          direction: '서향',
          landlordEnvironment: '편리함',
          rating: 5,
          address: '서울시 서대문구 신촌로 89',
          createdAt: DateTime.now(),
          cellImages: {},
          additionalData: {
            'housing_type': '빌라',
            'room_structure': '원룸',
            'window_view': '마주보는 건물',
            'elevator': '있음',
            'parking': '기계식',
            'heating': '심야전기',
            'landlord_residence': '없음',
            'double_lock': '있음',
          },
        ),
      ], 
      columnOptions: {
        '재계/방향': ['동향', '서향', '남향', '북향', '동남향', '서남향', '동북향', '서북향'],
        '집주인 환경': ['편리함', '보통', '불편함', '매우 좋음', '나쁨', '친절함', '무관심', '까다로움'],
        '집 이름': ['서라벌 오피스텔', '라인빌', '신촌센트럴빌'],
        '보증금': ['1000', '1500', '2000', '3000', '5000'],
        '월세': ['50', '60', '70', '80', '90', '100'],
        '주거 형태': ['빌라', '오피스텔', '아파트', '근린생활시설'],
        '방구조': ['원룸', '1.5룸', '다각형방', '복도형'],
        '창문 뷰': ['뻥뷰', '막힘', '옆건물 가까움', '마주보는 건물', '벽뷰'],
        '엘리베이터': ['있음', '없음'],
        '주차장': ['기계식', '지하주차장', '지상주차장'],
        '난방방식': ['보일러', '심야전기', '중앙난방'],
        '집주인 거주': ['있음', '없음'],
        '2중 잠금장치': ['있음', '없음', '설치해준다함'],
      },
      columnVisibility: {
        // 예시 차트는 더 많은 컬럼을 보여주지만 여전히 기본만 체크
        '집 이름': true,
        '보증금': true,
        '월세': true,
        // 나머지는 false로 설정하여 사용자가 필요에 따라 체크할 수 있도록 함
        '재계/방향': false,
        '집주인 환경': false,
        '주소': false,
        '주거 형태': false,
        '방구조': false,
        '창문 뷰': false,
        '엘리베이터': false,
        '주차장': false,
        '난방방식': false,
        '집주인 거주': false,
        '2중 잠금장치': false,
      },
    );
    state = [defaultChart];
    _saveChartsToStorage();
  }

  // 로컬 저장소에 차트 저장
  Future<void> _saveChartsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = _getUserStorageKey();
      final chartsJson = jsonEncode(state.map((chart) => chart.toJson()).toList());
      await prefs.setString(storageKey, chartsJson);
      AppLogger.info('로컬 저장소에 ${state.length}개 차트 저장 - 키: $storageKey');
    } catch (e) {
      AppLogger.error('로컬 차트 저장 실패', error: e);
    }
  }

  // 외부에서 로컬 저장소 저장을 트리거하는 공개 메서드
  Future<void> saveToStorage() async {
    await _saveChartsToStorage();
  }

  // 로컬 저장소 완전 초기화 (개발/테스트용)
  Future<void> clearStorageAndReset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = _getUserStorageKey();
      await prefs.remove(storageKey);
      AppLogger.info('로컬 저장소 완전 초기화 완료 - 키: $storageKey');
      
      // 기본 예시 차트 다시 생성
      _createDefaultChart();
    } catch (e) {
      AppLogger.error('로컬 저장소 초기화 실패', error: e);
    }
  }

  // 임시: 새로운 예시 데이터로 강제 업데이트
  void forceUpdateToNewExampleData() {
    AppLogger.info('새로운 예시 데이터로 강제 업데이트');
    _createDefaultChart();
  }

  void addChart(PropertyChartModel chart) {
    // 새 차트에 기본 컬럼 옵션과 첫 번째 빈 행 추가
    final uniquePropertyId = '${chart.id}_1'; // 차트 ID와 결합하여 고유 ID 생성
    
    // 새 차트의 컬럼 가시성 설정 (기본적으로 필수 컬럼만 표시)
    final columnVisibility = <String, bool>{
      // 필수 컬럼들만 true로 설정
      '집 이름': true,
      '보증금': true,
      '월세': true,
      // 나머지 모든 컬럼은 false로 설정
      '재계/방향': false,
      '집주인 환경': false,
      '주소': false,
      '주거 형태': false,
      '건축물용도': false,
      '임차권등기명령 이력': false,
      '근저당권': false,
      '가압류, 압류, 경매 이력': false,
      '계약 조건': false,
      '등기부등본(말소사항 포함으로)': false,
      '입주 가능일': false,
      '전입신고': false,
      '관리비': false,
      '주택보증보험': false,
      '특약': false,
      '특이사항': false,
      '평수': false,
      '방개수': false,
      '방구조': false,
      '창문 뷰': false,
      '방향(나침반)': false,
      '채광': false,
      '층수': false,
      '엘리베이터': false,
      '에어컨 방식': false,
      '난방방식': false,
      '베란다': false,
      '발코니': false,
      '주차장': false,
      '화장실': false,
      '가스': false,
      '지하철 거리': false,
      '버스 정류장': false,
      '편의점 거리': false,
      '위치': false,
      'cctv 여부': false,
      '창문 상태': false,
      '문 상태': false,
      '집주인 성격': false,
      '집주인 거주': false,
      '집근처 술집': false,
      '저층 방범창': false,
      '집주변 낮분위기': false,
      '집주변 밤분위기': false,
      '수압': false,
      '냄새': false,
      '곰팡이': false,
      '벌레': false,
      '소음': false,
      '2중 잠금장치': false,
      '외관': false,
      '인테리어': false,
      '별점': false,
    };
    
    final chartWithDefaults = PropertyChartModel(
      id: chart.id,
      title: chart.title,
      date: chart.date,
      properties: [
        PropertyData(
          id: uniquePropertyId,
          // order field removed
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
      columnOptions: {
        '재계/방향': ['동향', '서향', '남향', '북향', '동남향', '서남향', '동북향', '서북향'],
        '집주인 환경': ['편리함', '보통', '불편함', '매우 좋음', '나쁨', '친절함', '무관심', '까다로움'],
        '집 이름': [],
        '보증금': ['1000', '2000', '3000', '5000', '10000'],
        '월세': ['30', '40', '50', '60', '70', '80', '90', '100'],
      },
      columnWidths: chart.columnWidths,
      columnVisibility: columnVisibility,
    );
    state = [...state, chartWithDefaults];
    _saveChartsToStorage(); // 로컬 저장소에 저장
  }

  void updateChart(PropertyChartModel updatedChart) {
    try {
      if (updatedChart.id.isEmpty) return; // 빈 ID는 무시
      
      
      state = state.map((chart) {
        if (chart.id == updatedChart.id) {
          return updatedChart;
        }
        return chart;
      }).toList();
      _saveChartsToStorage(); // 로컬 저장소에 저장
    } catch (e) {
      // 업데이트 실패시 원본 상태 유지
      AppLogger.error('Error updating chart: $e');
    }
  }

  void deleteChart(String chartId) {
    state = state.where((chart) => chart.id != chartId).toList();
    _saveChartsToStorage(); // 로컬 저장소에 저장
  }

  // Firebase에서 받은 차트를 그대로 추가 (기본 데이터 변경 없이)
  void addChartAsIs(PropertyChartModel chart) {
    // 이미 존재하는 차트인지 확인
    final existingIndex = state.indexWhere((c) => c.id == chart.id);
    if (existingIndex == -1) {
      // 새 차트인 경우 추가
      state = [...state, chart];
      _saveChartsToStorage();
    }
  }

  void clearAllCharts() {
    AppLogger.info('모든 로컬 차트 데이터 초기화');
    state = [];
    _saveChartsToStorage(); // 빈 상태도 저장하여 사용자별 데이터 격리 유지
  }

  void resetToDefaultChart() {
    AppLogger.info('기본 차트로 초기화');
    state = [
      PropertyChartModel(
        id: '1',
        title: '예시 차트',
        date: DateTime.now(),
        properties: [
          PropertyData(
            id: '1',
            // order field removed
            name: '서라벌 오피스텔',
            deposit: '1000',
            rent: '55',
            direction: '남향',
            landlordEnvironment: '친절함',
            rating: 4,
            address: '서울시 강남구 역삼로 234',
            createdAt: DateTime.now(),
            cellImages: {},
            additionalData: {
              'housing_type': '오피스텔',
              'room_structure': '원룸',
              'window_view': '뻥뷰',
              'elevator': '있음',
              'parking': '지하주차장',
              'heating': '중앙난방',
              'landlord_residence': '없음',
              'double_lock': '있음',
            },
          ),
          PropertyData(
            id: '2',
            // order field removed
            name: '라인빌',
            deposit: '2000',
            rent: '75',
            direction: '동향',
            landlordEnvironment: '보통',
            rating: 3,
            address: '서울시 마포구 동교로 15길',
            createdAt: DateTime.now(),
            cellImages: {},
            additionalData: {
              'housing_type': '빌라',
              'room_structure': '1.5룸',
              'window_view': '옆건물 가까움',
              'elevator': '없음',
              'parking': '지상주차장',
              'heating': '보일러',
              'landlord_residence': '있음',
              'double_lock': '설치해준다함',
            },
          ),
          PropertyData(
            id: '3',
            // order field removed
            name: '신촌센트럴빌',
            deposit: '1500',
            rent: '65',
            direction: '서향',
            landlordEnvironment: '편리함',
            rating: 5,
            address: '서울시 서대문구 신촌로 89',
            createdAt: DateTime.now(),
            cellImages: {},
            additionalData: {
              'housing_type': '빌라',
              'room_structure': '원룸',
              'window_view': '마주보는 건물',
              'elevator': '있음',
              'parking': '기계식',
              'heating': '심야전기',
              'landlord_residence': '없음',
              'double_lock': '있음',
            },
          ),
        ],
        columnOptions: {
          '재계/방향': ['동향', '서향', '남향', '북향', '동남향', '서남향', '동북향', '서북향'],
          '집주인 환경': ['편리함', '보통', '불편함', '매우 좋음', '나쁨', '친절함', '무관심', '까다로움'],
          '집 이름': ['서라벌 오피스텔', '라인빌', '신촌센트럴빌'],
          '보증금': ['1000', '1500', '2000', '3000', '5000'],
          '월세': ['50', '60', '70', '80', '90', '100'],
          '주거 형태': ['빌라', '오피스텔', '아파트', '근린생활시설'],
          '방구조': ['원룸', '1.5룸', '다각형방', '복도형'],
          '창문 뷰': ['뻥뷰', '막힘', '옆건물 가까움', '마주보는 건물', '벽뷰'],
          '엘리베이터': ['있음', '없음'],
          '주차장': ['기계식', '지하주차장', '지상주차장'],
          '난방방식': ['보일러', '심야전기', '중앙난방'],
          '집주인 거주': ['있음', '없음'],
          '2중 잠금장치': ['있음', '없음', '설치해준다함'],
        },
        columnVisibility: {
          // 예시 차트는 더 많은 컬럼을 보여주지만 여전히 기본만 체크
          '집 이름': true,
          '보증금': true,
          '월세': true,
          // 나머지는 false로 설정하여 사용자가 필요에 따라 체크할 수 있도록 함
          '재계/방향': false,
          '집주인 환경': false,
          '주소': false,
          '주거 형태': false,
          '방구조': false,
          '창문 뷰': false,
          '엘리베이터': false,
          '주차장': false,
          '난방방식': false,
          '집주인 거주': false,
          '2중 잠금장치': false,
        },
      ),
    ];
    _saveChartsToStorage(); // 로컬 저장소에도 저장
  }

  PropertyChartModel? getChart(String chartId) {
    try {
      // 입력값 검증
      if (chartId.isEmpty || chartId.trim().isEmpty) {
        AppLogger.warning('getChart: 비어있는 chartId');
        return null;
      }

      final trimmedId = chartId.trim();
      
      // 안전한 검색
      for (final chart in state) {
        if (chart.id == trimmedId) {
          AppLogger.d('getChart: 차트 찾음 - ID: $trimmedId, Title: ${chart.title}');
          return chart;
        }
      }
      
      AppLogger.warning('getChart: 차트를 찾을 수 없음 - ID: $trimmedId');
      AppLogger.d('getChart: 사용 가능한 차트 ID들: ${state.map((c) => c.id).toList()}');
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('getChart 오류', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // 사용자 변경 시 데이터 다시 로드 (로그인/로그아웃 시 호출)
  Future<void> reloadChartsForCurrentUser() async {
    AppLogger.info('사용자 변경 감지 - 차트 데이터 다시 로드');
    state = []; // 이전 사용자 데이터 초기화
    await _loadChartsFromStorage();
  }

  // 특정 사용자의 로컬 데이터 완전 삭제 (계정 삭제 시)
  Future<void> clearUserData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStorageKey = 'local_charts_$userId';
      await prefs.remove(userStorageKey);
      AppLogger.info('사용자 데이터 삭제 완료 - 사용자: $userId, 키: $userStorageKey');
      
      // 현재 사용자가 삭제된 사용자와 같다면 상태도 초기화
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.uid == userId) {
        state = [];
      }
    } catch (e) {
      AppLogger.error('사용자 데이터 삭제 실패', error: e);
    }
  }
}

// 현재 선택된 차트 상태
class CurrentChartNotifier extends StateNotifier<PropertyChartModel?> {
  CurrentChartNotifier() : super(null);

  void setChart(PropertyChartModel chart) {
    state = chart;
  }

  void updateChart(PropertyChartModel updatedChart) {
    try {
      if (updatedChart.id.isEmpty) return; // 빈 ID는 무시
      state = updatedChart;
    } catch (e) {
      // 업데이트 실패시 원본 상태 유지
    }
  }

  void updateProperty(int propertyIndex, PropertyData updatedProperty) {
    if (state == null) return;
    
    final properties = List<PropertyData>.from(state!.properties);
    if (propertyIndex < properties.length) {
      properties[propertyIndex] = updatedProperty;
      state = state!.copyWith(properties: properties);
    }
  }

  void addProperty(PropertyData property) {
    if (state == null) return;
    
    final properties = List<PropertyData>.from(state!.properties);
    properties.add(property);
    state = state!.copyWith(properties: properties);
  }

  void updateColumnWidth(int columnIndex, double width) {
    if (state == null) return;
    
    final columnWidths = Map<int, double>.from(state!.columnWidths);
    columnWidths[columnIndex] = width;
    state = state!.copyWith(columnWidths: columnWidths);
  }

  void addColumnOption(String columnName, String option) {
    if (state == null) return;
    
    final columnOptions = Map<String, List<String>>.from(state!.columnOptions);
    if (!columnOptions.containsKey(columnName)) {
      columnOptions[columnName] = [];
    }
    columnOptions[columnName] = [...columnOptions[columnName]!, option];
    state = state!.copyWith(columnOptions: columnOptions);
  }

  void updateTitle(String title) {
    if (state == null) return;
    state = state!.copyWith(title: title);
  }

  void updateDate(DateTime date) {
    if (state == null) return;
    state = state!.copyWith(date: date);
  }

  void clearCurrentChart() {
    AppLogger.info('현재 차트 초기화');
    state = null;
  }

  void clearCurrentChartData() {
    if (state == null) return;
    AppLogger.info('현재 차트의 데이터만 초기화');
    state = state!.copyWith(properties: []);
  }
}

// Provider 정의
final propertyChartListProvider = StateNotifierProvider<PropertyChartListNotifier, List<PropertyChartModel>>((ref) {
  return PropertyChartListNotifier();
});

final currentChartProvider = StateNotifierProvider<CurrentChartNotifier, PropertyChartModel?>((ref) {
  return CurrentChartNotifier();
});

// 특정 chartId로 차트를 가져오는 Provider
final propertyChartProvider = Provider.family<AsyncValue<PropertyChartModel?>, String>((ref, chartId) {
  try {
    final chart = ref.read(propertyChartListProvider.notifier).getChart(chartId);
    return AsyncValue.data(chart);
  } catch (error, stackTrace) {
    return AsyncValue.error(error, stackTrace);
  }
});

