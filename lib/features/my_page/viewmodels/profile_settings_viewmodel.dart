import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/data/repositories/auth_repository.dart';
import 'package:house_note/data/repositories/user_repository.dart';
import 'package:house_note/providers/user_providers.dart';
import 'package:house_note/providers/property_chart_providers.dart';
import 'package:house_note/services/firestore_service.dart';

class ProfileSettingsState {
  final bool isLoading;
  final String? error;

  ProfileSettingsState({
    this.isLoading = false,
    this.error,
  });

  ProfileSettingsState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return ProfileSettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfileSettingsViewModel extends StateNotifier<ProfileSettingsState> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final FirestoreService _firestoreService;
  final Ref _ref;

  ProfileSettingsViewModel(this._authRepository, this._userRepository, this._firestoreService, this._ref)
      : super(ProfileSettingsState());

  Future<bool> updateProfile({
    required String displayName,
    required String nickname,
    required String email,
    String? password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 현재 사용자 가져오기
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        state = state.copyWith(isLoading: false, error: '로그인이 필요합니다');
        return false;
      }

      // 이메일 업데이트 (필요한 경우)
      if (email != currentUser.email) {
        await _authRepository.updateEmail(email);
      }

      // 비밀번호 업데이트 (필요한 경우)
      if (password != null && password.isNotEmpty) {
        await _authRepository.updatePassword(password);
      }

      // 프로필 정보 업데이트
      await _authRepository.updateProfile(displayName: displayName);

      // Firestore 사용자 정보 업데이트
      await _userRepository.updateUser(currentUser.uid, {
        'displayName': displayName,
        'nickname': nickname,
        'email': email,
        'updatedAt': DateTime.now(),
      });

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteAccount({String? password}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        state = state.copyWith(isLoading: false, error: '로그인이 필요합니다');
        return false;
      }

      // 구글 계정인지 확인
      final isGoogleAccount = currentUser.providerData
          .any((info) => info.providerId == 'google.com');

      // 재인증 수행
      if (isGoogleAccount) {
        await _authRepository.reauthenticateWithGoogle();
      } else {
        if (password == null || password.isEmpty) {
          state = state.copyWith(isLoading: false, error: '비밀번호가 필요합니다');
          return false;
        }
        await _authRepository.reauthenticateWithPassword(password);
      }

      // 사용자 ID 저장 (삭제 전에)
      final userId = currentUser.uid;

      // 모든 사용자 데이터 삭제 (차트, 프로필 등 포함)
      await _firestoreService.deleteAllUserData(userId);

      // 로컬 차트 데이터도 삭제
      await _ref.read(propertyChartListProvider.notifier).clearUserData(userId);

      // Firebase Auth에서 계정 삭제
      await _authRepository.deleteAccount();

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final profileSettingsViewModelProvider = StateNotifierProvider<ProfileSettingsViewModel, ProfileSettingsState>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  final userRepository = ref.read(userRepositoryProvider);
  final firestoreService = ref.read(firestoreServiceProvider);
  return ProfileSettingsViewModel(authRepository, userRepository, firestoreService, ref);
});