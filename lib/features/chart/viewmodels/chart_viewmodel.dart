import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:fl_chart/fl_chart.dart'; // 예시: fl_chart 사용시

// 상태 정의
class ChartState {
  final bool isLoading;
  final String? error;
  // TODO: 실제 차트 데이터를 담을 필드 (예: List<BarChartGroupData> chartData)

  ChartState({this.isLoading = false, this.error /*, this.chartData */});

  ChartState copyWith({
    bool? isLoading,
    String? error,
    /* List<BarChartGroupData>? chartData, */
  }) {
    return ChartState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      /* chartData: chartData ?? this.chartData, */
    );
  }
}

// ViewModel
class ChartViewModel extends StateNotifier<ChartState> {
  // TODO: ChartRepository 또는 관련 서비스 주입
  ChartViewModel() : super(ChartState()) {
    loadChartData();
  }

  Future<void> loadChartData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: 실제 데이터 로딩 로직 (예: API 호출, 로컬 DB 조회)
      await Future.delayed(const Duration(seconds: 1)); // 임시 지연
      // state = state.copyWith(isLoading: false, chartData: ... );
      state = state.copyWith(isLoading: false); // 임시
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Provider
final chartViewModelProvider =
    StateNotifierProvider<ChartViewModel, ChartState>((ref) {
  return ChartViewModel();
});
