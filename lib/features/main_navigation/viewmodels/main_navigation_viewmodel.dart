import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/core/utils/logger.dart';

class MainNavigationState {
  final int currentIndex;
  final bool isLoading;

  const MainNavigationState({
    this.currentIndex = 0,
    this.isLoading = false,
  });

  MainNavigationState copyWith({
    int? currentIndex,
    bool? isLoading,
  }) {
    return MainNavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MainNavigationViewModel extends StateNotifier<MainNavigationState> {
  MainNavigationViewModel() : super(const MainNavigationState());

  static final _logger = Logger('MainNavigationViewModel');

  void setCurrentIndex(int index) {
    if (index >= 0 && index <= 3) {
      _logger.info('í À½: $index');
      state = state.copyWith(currentIndex: index);
    }
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

final mainNavigationViewModelProvider =
    StateNotifierProvider<MainNavigationViewModel, MainNavigationState>((ref) {
  return MainNavigationViewModel();
});