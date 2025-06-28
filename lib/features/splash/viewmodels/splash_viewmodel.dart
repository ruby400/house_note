import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/core/utils/logger.dart';

class SplashState {
  final bool isLoading;
  final String? error;

  const SplashState({
    this.isLoading = true,
    this.error,
  });

  SplashState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return SplashState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SplashViewModel extends StateNotifier<SplashState> {
  SplashViewModel() : super(const SplashState());

  Future<void> initialize() async {
    try {
      AppLogger.info('스플래시 초기화 시작');
      
      // 스플래시 화면 표시 시간
      await Future.delayed(const Duration(seconds: 2));
      
      state = state.copyWith(isLoading: false);
      AppLogger.info('스플래시 초기화 완료');
    } catch (e) {
      AppLogger.error('스플래시 초기화 오류: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final splashViewModelProvider =
    StateNotifierProvider<SplashViewModel, SplashState>((ref) {
  return SplashViewModel();
});