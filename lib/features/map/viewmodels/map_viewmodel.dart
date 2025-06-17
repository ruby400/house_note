import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// 상태 정의
class MapState {
  final bool isLoading;
  final String? error;
  // TODO: 실제 지도 마커, 폴리라인 등을 담을 필드
  // final Set<Marker> markers;
  // final LatLng initialPosition;

  MapState({
    this.isLoading = false,
    this.error,
    /* this.markers = const {}, this.initialPosition = const LatLng(37.5665, 126.9780)*/
  });

  MapState copyWith({
    bool? isLoading,
    String? error,
    /* Set<Marker>? markers, LatLng? initialPosition */
  }) {
    return MapState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      /* markers: markers ?? this.markers, initialPosition: initialPosition ?? this.initialPosition,*/
    );
  }
}

// ViewModel
class MapViewModel extends StateNotifier<MapState> {
  // TODO: MapRepository 또는 위치 서비스, 장소 서비스 주입
  MapViewModel() : super(MapState()) {
    loadMapData();
  }

  Future<void> loadMapData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: 현재 위치 가져오기, 주변 장소 검색 등
      await Future.delayed(const Duration(seconds: 1)); // 임시 지연
      // state = state.copyWith(isLoading: false, markers: ..., initialPosition: ...);
      state = state.copyWith(isLoading: false); // 임시
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Provider
final mapViewModelProvider =
    StateNotifierProvider<MapViewModel, MapState>((ref) {
  return MapViewModel();
});
