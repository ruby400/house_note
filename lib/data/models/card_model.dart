// lib/data/models/card_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CardModel {
  final String id; // Firestore document ID
  final String userId; // 이 카드를 소유한 사용자 ID
  final String name; // 카드 이름
  final String company; // 카드사
  final String numberLastFour; // 카드 번호 마지막 4자리 (보안상 전체 저장 X)
  final String type; // 예: 'credit', 'check', 'hybrid'
  final List<String> benefits; // 주요 혜택 (문자열 리스트)
  final Timestamp? expiryDate; // 만료일 (선택적)
  final String? imageUrl; // 카드 이미지 URL (선택적)

  CardModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.company,
    required this.numberLastFour,
    required this.type,
    this.benefits = const [],
    this.expiryDate,
    this.imageUrl,
  });

  factory CardModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) throw Exception("Card data is null!");

    return CardModel(
      id: snapshot.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      company: data['company'] as String,
      numberLastFour: data['numberLastFour'] as String,
      type: data['type'] as String,
      benefits: List<String>.from(data['benefits'] ?? []),
      expiryDate: data['expiryDate'] as Timestamp?,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'company': company,
      'numberLastFour': numberLastFour,
      'type': type,
      'benefits': benefits,
      if (expiryDate != null) 'expiryDate': expiryDate,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
