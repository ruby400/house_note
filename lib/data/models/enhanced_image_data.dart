/// 강화된 이미지 데이터 모델 - Firebase Storage 지원
/// 
/// 로컬 경로와 Firebase URL을 함께 관리하여
/// 이중 백업 시스템을 지원합니다.
class EnhancedImageData {
  /// 로컬 이미지 파일 경로
  final String localPath;
  
  /// Firebase Storage 다운로드 URL
  final String? firebaseUrl;
  
  /// 동기화 상태
  /// - 'synced': 로컬과 Firebase 모두 동기화됨
  /// - 'pending': Firebase 업로드 대기 중
  /// - 'failed': Firebase 업로드 실패
  /// - 'local_only': 로컬 파일만 존재
  final String syncStatus;
  
  /// 이미지 업로드 시각
  final DateTime uploadedAt;
  
  /// 마지막 동기화 시각
  final DateTime? lastSyncAt;
  
  /// 이미지 메타데이터
  final Map<String, dynamic>? metadata;

  const EnhancedImageData({
    required this.localPath,
    this.firebaseUrl,
    this.syncStatus = 'local_only',
    required this.uploadedAt,
    this.lastSyncAt,
    this.metadata,
  });

  /// 동기화된 이미지 생성
  factory EnhancedImageData.synced({
    required String localPath,
    required String firebaseUrl,
    DateTime? uploadedAt,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return EnhancedImageData(
      localPath: localPath,
      firebaseUrl: firebaseUrl,
      syncStatus: 'synced',
      uploadedAt: uploadedAt ?? now,
      lastSyncAt: now,
      metadata: metadata,
    );
  }

  /// 로컬 전용 이미지 생성
  factory EnhancedImageData.localOnly({
    required String localPath,
    DateTime? uploadedAt,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedImageData(
      localPath: localPath,
      firebaseUrl: null,
      syncStatus: 'local_only',
      uploadedAt: uploadedAt ?? DateTime.now(),
      lastSyncAt: null,
      metadata: metadata,
    );
  }

  /// 업로드 대기 중인 이미지 생성
  factory EnhancedImageData.pending({
    required String localPath,
    DateTime? uploadedAt,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedImageData(
      localPath: localPath,
      firebaseUrl: null,
      syncStatus: 'pending',
      uploadedAt: uploadedAt ?? DateTime.now(),
      lastSyncAt: null,
      metadata: metadata,
    );
  }

  /// 복사본 생성
  EnhancedImageData copyWith({
    String? localPath,
    String? firebaseUrl,
    String? syncStatus,
    DateTime? uploadedAt,
    DateTime? lastSyncAt,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedImageData(
      localPath: localPath ?? this.localPath,
      firebaseUrl: firebaseUrl ?? this.firebaseUrl,
      syncStatus: syncStatus ?? this.syncStatus,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Firebase URL이 설정된 복사본 생성 (동기화 완료)
  EnhancedImageData withFirebaseUrl(String firebaseUrl) {
    return copyWith(
      firebaseUrl: firebaseUrl,
      syncStatus: 'synced',
      lastSyncAt: DateTime.now(),
    );
  }

  /// 동기화 상태 업데이트
  EnhancedImageData withSyncStatus(String status) {
    return copyWith(
      syncStatus: status,
      lastSyncAt: status == 'synced' ? DateTime.now() : lastSyncAt,
    );
  }

  /// 접근 가능한 이미지 경로 반환
  /// 로컬 파일이 없으면 Firebase URL 반환
  String get accessiblePath {
    // 우선순위: 로컬 경로 > Firebase URL
    return localPath.isNotEmpty ? localPath : (firebaseUrl ?? '');
  }

  /// 동기화 여부 확인
  bool get isSynced => syncStatus == 'synced' && firebaseUrl != null;

  /// 업로드 대기 중인지 확인
  bool get isPending => syncStatus == 'pending';

  /// 업로드 실패했는지 확인
  bool get isFailed => syncStatus == 'failed';

  /// 로컬 전용인지 확인
  bool get isLocalOnly => syncStatus == 'local_only';

  /// 백업이 있는지 확인 (Firebase URL 존재)
  bool get hasBackup => firebaseUrl != null && firebaseUrl!.isNotEmpty;

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'localPath': localPath,
      'firebaseUrl': firebaseUrl,
      'syncStatus': syncStatus,
      'uploadedAt': uploadedAt.toIso8601String(),
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// JSON에서 생성
  factory EnhancedImageData.fromJson(Map<String, dynamic> json) {
    return EnhancedImageData(
      localPath: json['localPath'] ?? '',
      firebaseUrl: json['firebaseUrl'],
      syncStatus: json['syncStatus'] ?? 'local_only',
      uploadedAt: DateTime.tryParse(json['uploadedAt'] ?? '') ?? DateTime.now(),
      lastSyncAt: json['lastSyncAt'] != null 
          ? DateTime.tryParse(json['lastSyncAt']) 
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 기존 로컬 경로에서 생성 (호환성)
  factory EnhancedImageData.fromLegacyPath(String localPath) {
    return EnhancedImageData.localOnly(
      localPath: localPath,
      metadata: {'legacy': true},
    );
  }

  /// 기존 로컬 경로 리스트에서 생성 (호환성)
  static List<EnhancedImageData> fromLegacyPaths(List<String> localPaths) {
    return localPaths
        .map((path) => EnhancedImageData.fromLegacyPath(path))
        .toList();
  }

  /// EnhancedImageData 리스트를 기존 경로 리스트로 변환 (호환성)
  static List<String> toLegacyPaths(List<EnhancedImageData> images) {
    return images.map((img) => img.accessiblePath).toList();
  }

  @override
  String toString() {
    return 'EnhancedImageData('
        'localPath: $localPath, '
        'firebaseUrl: $firebaseUrl, '
        'syncStatus: $syncStatus, '
        'isSynced: $isSynced'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is EnhancedImageData &&
        other.localPath == localPath &&
        other.firebaseUrl == firebaseUrl &&
        other.syncStatus == syncStatus;
  }

  @override
  int get hashCode {
    return localPath.hashCode ^
        firebaseUrl.hashCode ^
        syncStatus.hashCode;
  }
}

/// 셀별 이미지 데이터 관리 클래스
class CellImageData {
  /// 셀 식별자 (예: 'address', 'memo', 'custom_field_1')
  final String cellId;
  
  /// 해당 셀의 이미지들
  final List<EnhancedImageData> images;

  const CellImageData({
    required this.cellId,
    required this.images,
  });

  /// 복사본 생성
  CellImageData copyWith({
    String? cellId,
    List<EnhancedImageData>? images,
  }) {
    return CellImageData(
      cellId: cellId ?? this.cellId,
      images: images ?? this.images,
    );
  }

  /// 이미지 추가
  CellImageData addImage(EnhancedImageData image) {
    return copyWith(images: [...images, image]);
  }

  /// 이미지 제거
  CellImageData removeImage(String localPath) {
    return copyWith(
      images: images.where((img) => img.localPath != localPath).toList(),
    );
  }

  /// 이미지 업데이트
  CellImageData updateImage(String localPath, EnhancedImageData newImage) {
    final updatedImages = images.map((img) {
      return img.localPath == localPath ? newImage : img;
    }).toList();
    
    return copyWith(images: updatedImages);
  }

  /// 동기화되지 않은 이미지들 반환
  List<EnhancedImageData> get unsyncedImages {
    return images.where((img) => !img.isSynced).toList();
  }

  /// 동기화된 이미지들 반환
  List<EnhancedImageData> get syncedImages {
    return images.where((img) => img.isSynced).toList();
  }

  /// 업로드 대기 중인 이미지들 반환
  List<EnhancedImageData> get pendingImages {
    return images.where((img) => img.isPending).toList();
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'cellId': cellId,
      'images': images.map((img) => img.toJson()).toList(),
    };
  }

  /// JSON에서 생성
  factory CellImageData.fromJson(Map<String, dynamic> json) {
    final imagesList = json['images'] as List<dynamic>? ?? [];
    final images = imagesList
        .map((imgJson) => EnhancedImageData.fromJson(imgJson as Map<String, dynamic>))
        .toList();

    return CellImageData(
      cellId: json['cellId'] ?? '',
      images: images,
    );
  }

  /// 기존 cellImages 형식에서 변환 (호환성)
  factory CellImageData.fromLegacy(String cellId, List<String> imagePaths) {
    final images = EnhancedImageData.fromLegacyPaths(imagePaths);
    return CellImageData(cellId: cellId, images: images);
  }

  /// 기존 cellImages 형식으로 변환 (호환성)
  List<String> toLegacy() {
    return EnhancedImageData.toLegacyPaths(images);
  }

  @override
  String toString() {
    return 'CellImageData(cellId: $cellId, images: ${images.length})';
  }
}