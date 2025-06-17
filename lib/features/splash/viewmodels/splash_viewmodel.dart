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

  static final _logger = Logger('SplashViewModel');

  Future<void> initialize() async {
    try {
      _logger.info('q 0T Ü‘');
      
      // D”\ 0T ‘Å ‰
      await Future.delayed(const Duration(seconds: 2));
      
      state = state.copyWith(isLoading: false);
      _logger.info('q 0T DÌ');
    } catch (e) {
      _logger.error('q 0T $X: $e');
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