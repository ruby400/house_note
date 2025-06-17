import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/core/utils/logger.dart';
import 'package:house_note/data/repositories/user_repository.dart';
import 'package:house_note/providers/auth_providers.dart';
import 'package:house_note/providers/user_providers.dart';

class PrioritySettingState {
  final bool isLoading;
  final String? error;
  const PrioritySettingState({this.isLoading = false, this.error});

  PrioritySettingState copyWith({bool? isLoading, String? error}) {
    return PrioritySettingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PrioritySettingViewModel extends StateNotifier<PrioritySettingState> {
  final UserRepository _userRepository;
  final String? _userId;

  PrioritySettingViewModel(this._userRepository, this._userId)
      : super(const PrioritySettingState());

  Future<String?> savePriorities(List<String> priorities) async {
    if (_userId == null) return "사용자 정보가 없습니다.";

    state = state.copyWith(isLoading: true, error: null);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _userRepository
            .createUserProfile(currentUser)
            .catchError((e) => AppLogger.info("사용자 문서가 이미 존재함: $e"));
      }

      await _userRepository.updateUser(_userId!, {
        'priorities': priorities,
        'updatedAt': DateTime.now(),
      });
      await _userRepository.updateOnboardingStatus(_userId!, true);

      AppLogger.info("중요도 저장 완료: $priorities");
      state = state.copyWith(isLoading: false);
      return null;
    } catch (e, st) {
      final errorMsg = e.toString();
      AppLogger.error("중요도 저장 실패", error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: errorMsg);
      return errorMsg;
    }
  }

  Future<String?> savePrioritiesWithVisibility(List<String> priorities, List<Map<String, dynamic>> priorityItems) async {
    if (_userId == null) return "사용자 정보가 없습니다.";

    state = state.copyWith(isLoading: true, error: null);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _userRepository
            .createUserProfile(currentUser)
            .catchError((e) => AppLogger.info("사용자 문서가 이미 존재함: $e"));
      }

      await _userRepository.updateUser(_userId!, {
        'priorities': priorities,
        'priorityItems': priorityItems,
        'updatedAt': DateTime.now(),
      });
      await _userRepository.updateOnboardingStatus(_userId!, true);

      AppLogger.info("중요도 및 표시 설정 저장 완료: $priorities, $priorityItems");
      state = state.copyWith(isLoading: false);
      return null;
    } catch (e, st) {
      final errorMsg = e.toString();
      AppLogger.error("중요도 및 표시 설정 저장 실패", error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: errorMsg);
      return errorMsg;
    }
  }
}

final prioritySettingViewModelProvider =
    StateNotifierProvider<PrioritySettingViewModel, PrioritySettingState>(
        (ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  final userId = ref.watch(authStateChangesProvider).value?.uid;
  return PrioritySettingViewModel(userRepository, userId);
});
