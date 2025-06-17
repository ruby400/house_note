import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/data/repositories/auth_repository.dart';
import 'package:house_note/data/repositories/user_repository.dart';
import 'package:house_note/providers/auth_providers.dart';
import 'package:house_note/providers/user_providers.dart';

class ProfileSettingState {
  final bool isLoading;
  final String? error;
  const ProfileSettingState({this.isLoading = false, this.error});

  ProfileSettingState copyWith({bool? isLoading, String? error}) {
    return ProfileSettingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfileSettingViewModel extends StateNotifier<ProfileSettingState> {
  final UserRepository _userRepository;
  final AuthRepository _authRepository;
  final String? _userId;

  ProfileSettingViewModel(
      this._userRepository, this._authRepository, this._userId)
      : super(const ProfileSettingState());

  Future<String?> saveProfile(String displayName) async {
    if (_userId == null) return "사용자 정보가 없습니다.";
    if (displayName.trim().isEmpty) return "닉네임을 입력해주세요.";

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.updateProfile(displayName: displayName);
      await _userRepository.updateUser(_userId!, {'displayName': displayName});
      await _userRepository.updateOnboardingStatus(_userId!, true);
      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      final errorMsg = e.toString();
      state = state.copyWith(isLoading: false, error: errorMsg);
      return errorMsg;
    }
  }
}

final profileSettingViewModelProvider =
    StateNotifierProvider<ProfileSettingViewModel, ProfileSettingState>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  final userId = ref.watch(authStateChangesProvider).value?.uid;
  return ProfileSettingViewModel(userRepository, authRepository, userId);
});
