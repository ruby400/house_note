// lib/data/repositories/card_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/data/models/card_model.dart'; // import 추가
import 'package:house_note/services/firestore_service.dart';

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository(ref.watch(firestoreProvider));
});

class CardRepository {
  final FirebaseFirestore _firestore;

  CardRepository(this._firestore);

  // 사용자별 하위 컬렉션으로 카드 관리
  CollectionReference<CardModel> _cardsCollection(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('cards')
      .withConverter<CardModel>(
        fromFirestore: (snapshots, _) => CardModel.fromFirestore(snapshots),
        toFirestore: (card, _) => card.toFirestore(),
      );

  // 사용자의 모든 카드 가져오기 (Stream)
  Stream<List<CardModel>> getUserCardsStream(String userId) {
    return _cardsCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // 특정 카드 가져오기 (Stream)
  Stream<CardModel?> getCardStream(String userId, String cardId) {
    return _cardsCollection(userId)
        .doc(cardId)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  // 카드 추가
  Future<DocumentReference<CardModel>> addCard(String userId, CardModel card) {
    return _cardsCollection(userId).add(card);
  }

  // 카드 업데이트
  Future<void> updateCard(String userId, CardModel card) {
    return _cardsCollection(userId).doc(card.id).update(card.toFirestore());
  }

  // 카드 삭제
  Future<void> deleteCard(String userId, String cardId) {
    return _cardsCollection(userId).doc(cardId).delete();
  }
}
