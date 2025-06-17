// lib/features/my_page/viewmodels/my_page_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/data/models/user_model.dart';
import 'package:house_note/data/repositories/user_repository.dart';
import 'package:house_note/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:house_note/providers/auth_providers.dart';
import 'package:house_note/providers/user_providers.dart';

// 상태 정의
class MyPageState {
  final AsyncValue<UserModel?> userModel;
  final bool isLoggingOut;
  final String? error;

  MyPageState({
    this.userModel = const AsyncValue.loading(),
    this.isLoggingOut = false,
    this.error,
  });

  MyPageState copyWith({
    AsyncValue<UserModel?>? userModel,
    bool? isLoggingOut,
    String? error,
  }) {
    return MyPageState(
      userModel: userModel ?? this.userModel,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
      error: error ?? this.error,
    );
  }
}

// ViewModel
class MyPageViewModel extends StateNotifier<MyPageState> {
  final AuthViewModel _authViewModel;
  final UserRepository _userRepository;
  final Ref _ref; // Reader 대신 Ref를 직접 받도록 수정

  MyPageViewModel(this._authViewModel, this._userRepository, this._ref)
      : super(MyPageState()) {
    // ViewModel에서는 UI 관련 로직이 아닌 데이터 처리/액션만 담당
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoggingOut: true, error: null);
    await _authViewModel.signOut();
    state = state.copyWith(isLoggingOut: false);
  }

  Future<bool> resetOnboarding() async {
    state = state.copyWith(error: null);
    final userId = _ref
        .read(authStateChangesProvider)
        .asData
        ?.value
        ?.uid; // _read 대신 _ref.read 사용
    if (userId == null) {
      state = state.copyWith(error: "사용자 ID를 찾을 수 없습니다.");
      return false;
    }
    try {
      await _userRepository.updateOnboardingStatus(userId, false);
      return true;
    } catch (e) {
      state = state.copyWith(error: "온보딩 초기화 중 오류 발생: $e");
      return false;
    }
  }
}

// Provider
final myPageViewModelProvider =
    StateNotifierProvider<MyPageViewModel, MyPageState>((ref) {
  final authViewModel = ref.watch(authViewModelProvider.notifier);
  final userRepository = ref.watch(userRepositoryProvider);
  return MyPageViewModel(authViewModel, userRepository, ref); // ref를 생성자에 전달
});
