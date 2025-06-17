import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/data/models/card_model.dart';
import 'package:house_note/data/repositories/card_repository.dart';
import 'package:house_note/features/card_list/viewmodels/card_detail_viewmodel.dart';
import 'package:house_note/features/card_list/viewmodels/card_list_viewmodel.dart';
import 'package:house_note/providers/auth_providers.dart';

// CardListViewModel Provider
final cardListViewModelProvider =
    StateNotifierProvider<CardListViewModel, AsyncValue<List<CardModel>>>(
        (ref) {
  final cardRepository = ref.watch(cardRepositoryProvider);
  final authState = ref.watch(authStateChangesProvider);
  
  final userId = authState.when(
    data: (user) => user?.uid,
    loading: () => null,
    error: (_, __) => null,
  );
  
  return CardListViewModel(cardRepository, userId);
});

// CardDetailViewModel Provider Family (cardId를 인자로 받기 위해)
final cardDetailViewModelProvider = StateNotifierProvider.family<
    CardDetailViewModel, AsyncValue<CardModel?>, String>((ref, cardId) {
  final cardRepository = ref.watch(cardRepositoryProvider);
  final authState = ref.watch(authStateChangesProvider);
  
  // 인증 상태가 로딩 중이거나 에러인 경우 적절히 처리
  final userId = authState.when(
    data: (user) => user?.uid,
    loading: () => null,
    error: (_, __) => null,
  );
  
  final viewModel = CardDetailViewModel(cardRepository, userId, cardId);
  
  // userId 변경 감지를 위한 listener 추가
  ref.listen(authStateChangesProvider, (previous, next) {
    final newUserId = next.when(
      data: (user) => user?.uid,
      loading: () => null,
      error: (_, __) => null,
    );
    viewModel.updateUserId(newUserId);
  });
  
  return viewModel;
});
