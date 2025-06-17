import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/data/models/user_model.dart';
import 'package:house_note/data/repositories/user_repository.dart';
import 'package:house_note/providers/auth_providers.dart';
import 'package:house_note/services/firestore_service.dart';

// UserRepository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(firestoreServiceProvider));
});

// 현재 로그인된 사용자의 UserModel 스트림 Provider
// 이 Provider는 사용자 프로필이 Firestore에 생성/업데이트될 때마다 최신 UserModel을 제공합니다.
final userModelProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userRepository = ref.watch(userRepositoryProvider);

  if (authState.asData?.value?.uid != null) {
    final uid = authState.asData!.value!.uid;
    // Firestore에서 UserModel 스트림을 반환하도록 UserRepository에 메서드 추가 필요
    // 예: return userRepository.userProfileStream(uid);
    // 지금은 get으로 한번 가져오는 예시 (스트림으로 바꾸는 것이 좋음)
    // Firestore에 해당 유저 데이터가 없을 수도 있으니 주의
    return userRepository
        .getUserProfileStream(uid); // getUserProfileStream 메서드 구현 필요
  }
  return Stream.value(null);
});

// 사용자의 우선순위 리스트를 가져오는 Provider
final userPrioritiesProvider = Provider<List<String>>((ref) {
  final userModel = ref.watch(userModelProvider).asData?.value;
  if (userModel != null && userModel.priorities.isNotEmpty) {
    return userModel.priorities;
  }
  return [];
});
