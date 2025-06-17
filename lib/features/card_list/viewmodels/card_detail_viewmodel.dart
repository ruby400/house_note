import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/data/models/card_model.dart';
import 'package:house_note/data/repositories/card_repository.dart';

class CardDetailViewModel extends StateNotifier<AsyncValue<CardModel?>> {
  final CardRepository _cardRepository;
  String? _userId;
  final String _cardId;
  StreamSubscription<CardModel?>? _cardSubscription;

  CardDetailViewModel(this._cardRepository, this._userId, this._cardId)
      : super(const AsyncValue.loading()) {
    _fetchCardDetail();
  }

  // userId 업데이트 메서드 추가
  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      _fetchCardDetail();
    }
  }

  void _fetchCardDetail() {
    if (_userId == null) {
      state = AsyncValue.error("로그인이 필요합니다.", StackTrace.current);
      return;
    }
    
    _cardSubscription?.cancel();
    _cardSubscription = _cardRepository.getCardStream(_userId!, _cardId).listen(
      (card) {
        if (card != null) {
          state = AsyncValue.data(card);
        } else {
          state = AsyncValue.error("카드를 찾을 수 없습니다. (ID: $_cardId)", StackTrace.current);
        }
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error("카드 정보를 불러오는 중 오류가 발생했습니다: $error", stackTrace);
      },
    );
  }

  Future<void> updateCard(CardModel updatedCard) async {
    if (_userId == null) return;
    state = const AsyncValue.loading(); // 로딩 상태 표시
    try {
      await _cardRepository.updateCard(_userId!, updatedCard);
      // 스트림이 업데이트하므로 state는 자동으로 변경됨
    } catch (e, st) {
      state = AsyncValue.error("카드 업데이트 실패: $e", st);
    }
  }

  @override
  void dispose() {
    _cardSubscription?.cancel();
    super.dispose();
  }
}
