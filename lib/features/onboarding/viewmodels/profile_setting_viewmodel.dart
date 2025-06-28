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

  Future<String?> saveProfile({
    required String nickname,
    String? realName,
    String? ageGroup,
    String? gender,
  }) async {
    if (_userId == null) return "사용자 정보가 없습니다.";
    if (nickname.trim().isEmpty) return "닉네임을 입력해주세요.";

    state = state.copyWith(isLoading: true, error: null);
    try {
      // Firebase Auth 프로필 업데이트 (displayName은 닉네임으로 설정)
      await _authRepository.updateProfile(displayName: nickname);
      
      // Firestore 사용자 문서 업데이트
      final updateData = <String, dynamic>{
        'displayName': nickname,
        'nickname': nickname,
        'updatedAt': DateTime.now(),
      };
      
      // 선택적 필드들 추가
      if (realName != null && realName.trim().isNotEmpty) {
        updateData['realName'] = realName.trim();
      }
      if (ageGroup != null && ageGroup.isNotEmpty) {
        updateData['ageGroup'] = ageGroup;
      }
      if (gender != null && gender.isNotEmpty) {
        updateData['gender'] = gender;
      }
      
      await _userRepository.updateUser(_userId!, updateData);
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
