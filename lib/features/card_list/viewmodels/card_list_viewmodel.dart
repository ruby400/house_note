import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/data/models/card_model.dart';
import 'package:house_note/data/repositories/card_repository.dart';
import 'package:house_note/core/utils/logger.dart'; // AppLogger가 정의된 파일

class CardListViewModel extends StateNotifier<AsyncValue<List<CardModel>>> {
  final CardRepository _cardRepository;
  final String? _userId;
  StreamSubscription<List<CardModel>>? _cardsSubscription;

  CardListViewModel(this._cardRepository, this._userId)
      : super(const AsyncValue.loading()) {
    _fetchCards();
  }

  void _fetchCards() {
    if (_userId == null) {
      state = AsyncValue.error("사용자 정보를 찾을 수 없습니다.", StackTrace.current);
      return;
    }
    _cardsSubscription?.cancel(); // 이전 구독 취소
    _cardsSubscription = _cardRepository.getUserCardsStream(_userId!).listen(
      (cards) {
        state = AsyncValue.data(cards);
      },
      onError: (error, stackTrace) {
        // ❗️수정: 스트림에서 에러 발생 시 상태를 업데이트하고 로그를 남깁니다.
        state = AsyncValue.error(error, stackTrace);
        AppLogger.error("카드 목록을 가져오는 중 에러 발생",
            error: error, stackTrace: stackTrace);
      },
    );
  }

  Future<void> addCard(CardModel card) async {
    if (_userId == null) return;
    try {
      await _cardRepository.addCard(_userId!, card);
      // 스트림이 자동으로 업데이트하므로 별도 state 변경 불필요
    } catch (e, st) {
      // ❗️수정: Logger.error -> AppLogger.error
      AppLogger.error("카드 추가 실패: $e", error: e, stackTrace: st);
      state = AsyncValue.error("카드 추가에 실패했습니다: $e", st);
    }
  }

  Future<void> deleteCard(String cardId) async {
    if (_userId == null) return;
    try {
      await _cardRepository.deleteCard(_userId!, cardId);
    } catch (e, st) {
      // ❗️수정: Logger.error -> AppLogger.error
      AppLogger.error("카드 삭제 실패: $e", error: e, stackTrace: st);
      state = AsyncValue.error("카드 삭제에 실패했습니다: $e", st);
    }
  }

  @override
  void dispose() {
    _cardsSubscription?.cancel();
    super.dispose();
  }
}
