class PriorityItem {
  final String name;
  final String level; // '낮음', '보통', '높음'
  final bool isVisible; // 카드에서 보이기 여부

  PriorityItem({
    required this.name,
    required this.level,
    this.isVisible = true,
  });

  factory PriorityItem.fromMap(Map<String, dynamic> data) {
    return PriorityItem(
      name: data['name'] as String,
      level: data['level'] as String,
      isVisible: data['isVisible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'level': level,
      'isVisible': isVisible,
    };
  }
}

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool onboardingCompleted; // 온보딩 완료 여부
  final List<String> priorities; // 사용자가 선택한 우선순위 항목들 (호환성용 유지)
  final List<PriorityItem> priorityItems; // 새로운 구조화된 우선순위 항목들
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // 개인정보 필드 추가
  final String? realName; // 실명
  final String? nickname; // 닉네임
  final String? ageGroup; // 나이대 ('20대', '30대', '40대', '50대', '60대 이상')
  final String? gender; // 성별 ('남성', '여성', '선택안함')

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.onboardingCompleted = false,
    this.priorities = const [],
    this.priorityItems = const [],
    this.createdAt,
    this.updatedAt,
    this.realName,
    this.nickname,
    this.ageGroup,
    this.gender,
  });

  // Firestore 데이터 변환을 위한 factory constructor 및 toJson 메서드 추가
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'],
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      onboardingCompleted: data['onboardingCompleted'] ?? false,
      priorities: data['priorities'] != null 
          ? List<String>.from(data['priorities']) 
          : [],
      priorityItems: data['priorityItems'] != null
          ? (data['priorityItems'] as List<dynamic>)
              .map((item) => PriorityItem.fromMap(item as Map<String, dynamic>))
              .toList()
          : [],
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
      realName: data['realName'],
      nickname: data['nickname'],
      ageGroup: data['ageGroup'],
      gender: data['gender'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'onboardingCompleted': onboardingCompleted,
      'priorities': priorities,
      'priorityItems': priorityItems.map((item) => item.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'realName': realName,
      'nickname': nickname,
      'ageGroup': ageGroup,
      'gender': gender,
      // uid는 문서 ID로 사용되므로 map에 포함하지 않을 수 있음
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? onboardingCompleted,
    List<String>? priorities,
    List<PriorityItem>? priorityItems,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? realName,
    String? nickname,
    String? ageGroup,
    String? gender,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      priorities: priorities ?? this.priorities,
      priorityItems: priorityItems ?? this.priorityItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      realName: realName ?? this.realName,
      nickname: nickname ?? this.nickname,
      ageGroup: ageGroup ?? this.ageGroup,
      gender: gender ?? this.gender,
    );
  }
}
