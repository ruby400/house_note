import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/core/utils/logger.dart';
import 'package:house_note/data/models/property_chart_model.dart';

// 전체 차트 목록 상태
class PropertyChartListNotifier extends StateNotifier<List<PropertyChartModel>> {
  PropertyChartListNotifier() : super([
    PropertyChartModel(
      id: '1',
      title: '마포구 부동산 차트',
      date: DateTime.now(),
      properties: [
        PropertyData(
          id: '1',
          order: '1',
          name: '강남 해피빌',
          deposit: '5000',
          rent: '50',
          direction: '동향',
          landlordEnvironment: '편리함',
          rating: 5,
          memo: '교통이 편리하고 시설이 좋음',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        PropertyData(
          id: '2',
          order: '2',
          name: '정우 오피스텔',
          deposit: '3000',
          rent: '40',
          direction: '남향',
          landlordEnvironment: '보통',
          rating: 3,
          memo: '가격 대비 적당함',
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
        PropertyData(
          id: '3',
          order: '3',
          name: '파인라인빌',
          deposit: '10000',
          rent: '0',
          direction: '서남향',
          landlordEnvironment: '양호',
          rating: 4,
          memo: '전세로 좋은 조건',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        PropertyData(
          id: '4',
          order: '4',
          name: '서라벌 오피스텔',
          deposit: '2000',
          rent: '60',
          direction: '북향',
          landlordEnvironment: '친절함',
          rating: 3,
          memo: '집주인이 친절하나 북향이 아쉬움',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ],
      columnOptions: {
        '재계/방향': ['동향', '서향', '남향', '북향', '동남향', '서남향', '동북향', '서북향'],
        '집주인 환경': ['편리함', '보통', '불편함', '매우 좋음', '나쁨', '친절함', '무관심', '까다로움'],
        '집 이름': ['강남 해피빌', '정우 오피스텔', '파인라인빌', '서라벌 오피스텔'],
        '보증금': ['1000', '2000', '3000', '5000', '10000'],
        '월세': ['30', '40', '50', '60', '70', '80', '90', '100'],
      },
    ),
  ]);

  void addChart(PropertyChartModel chart) {
    // 새 차트에 기본 샘플 데이터와 컬럼 옵션 추가
    final chartWithDefaults = PropertyChartModel(
      id: chart.id,
      title: chart.title,
      date: chart.date,
      properties: [
        PropertyData(
          id: '1',
          order: '1',
          name: '샘플 부동산',
          deposit: '1000',
          rent: '30',
          direction: '남향',
          landlordEnvironment: '보통',
          rating: 3,
          memo: '새로 추가된 샘플 데이터',
          createdAt: DateTime.now(),
        ),
      ],
      columnOptions: {
        '재계/방향': ['동향', '서향', '남향', '북향', '동남향', '서남향', '동북향', '서북향'],
        '집주인 환경': ['편리함', '보통', '불편함', '매우 좋음', '나쁨', '친절함', '무관심', '까다로움'],
        '집 이름': ['샘플 부동산'],
        '보증금': ['1000', '2000', '3000', '5000', '10000'],
        '월세': ['30', '40', '50', '60', '70', '80', '90', '100'],
      },
      columnWidths: chart.columnWidths,
    );
    state = [...state, chartWithDefaults];
  }

  void updateChart(PropertyChartModel updatedChart) {
    try {
      if (updatedChart.id.isEmpty) return; // 빈 ID는 무시
      
      // 디버깅을 위한 로그
      print('Updating chart ${updatedChart.id} with ${updatedChart.properties.length} properties');
      for (var property in updatedChart.properties) {
        print('Property ${property.id} cellImages: ${property.cellImages}');
      }
      
      state = state.map((chart) {
        if (chart.id == updatedChart.id) {
          return updatedChart;
        }
        return chart;
      }).toList();
    } catch (e) {
      // 업데이트 실패시 원본 상태 유지
      print('Error updating chart: $e');
    }
  }

  void deleteChart(String chartId) {
    state = state.where((chart) => chart.id != chartId).toList();
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
    final chartList = ref.watch(propertyChartListProvider);
    final chart = ref.read(propertyChartListProvider.notifier).getChart(chartId);
    return AsyncValue.data(chart);
  } catch (error, stackTrace) {
    return AsyncValue.error(error, stackTrace);
  }
});

