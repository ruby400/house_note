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
  final userId = ref.watch(authStateChangesProvider).asData?.value?.uid;
  return CardListViewModel(cardRepository, userId);
});

// CardDetailViewModel Provider Family (cardId를 인자로 받기 위해)
final cardDetailViewModelProvider = StateNotifierProvider.family<
    CardDetailViewModel, AsyncValue<CardModel?>, String>((ref, cardId) {
  final cardRepository = ref.watch(cardRepositoryProvider);
  final userId = ref.watch(authStateChangesProvider).asData?.value?.uid;
  return CardDetailViewModel(cardRepository, userId, cardId);
});
