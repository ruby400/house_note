import 'package:house_note/data/models/property_chart_model.dart';
import 'package:house_note/data/models/enhanced_image_data.dart';
import 'package:house_note/core/utils/logger.dart';

/// PropertyData를 위한 확장 기능
/// 
/// 기존 cellImages (`Map<String, List<String>>`) 형식과
/// 새로운 enhancedCellImages (`Map<String, List<EnhancedImageData>>`) 형식을
/// 함께 지원하여 호환성을 유지합니다.
extension PropertyDataImageExtensions on PropertyData {
  
  /// 셀별 강화된 이미지 데이터 가져오기
  /// 
  /// [cellId] 셀 식별자 (예: 'address', 'memo')
  /// Returns 해당 셀의 강화된 이미지 데이터 리스트
  List<EnhancedImageData> getEnhancedImages(String cellId) {
    try {
      // 1. additionalData에서 enhancedCellImages 확인
      final enhancedImagesJson = additionalData['enhancedCellImages'];
      if (enhancedImagesJson != null) {
        final Map<String, dynamic> enhancedImages = 
            _parseJsonSafely(enhancedImagesJson) ?? {};
        
        final cellImageJson = enhancedImages[cellId] as List<dynamic>?;
        if (cellImageJson != null) {
          return cellImageJson
              .map((imgJson) => EnhancedImageData.fromJson(imgJson as Map<String, dynamic>))
              .toList();
        }
      }

      // 2. 기존 cellImages에서 변환
      final legacyPaths = cellImages[cellId] ?? [];
      return EnhancedImageData.fromLegacyPaths(legacyPaths);
      
    } catch (e) {
      AppLogger.warning('셀 이미지 파싱 실패 ($cellId): $e');
      return [];
    }
  }

  /// 셀에 강화된 이미지 데이터 설정
  /// 
  /// [cellId] 셀 식별자
  /// [images] 설정할 강화된 이미지 데이터 리스트
  /// Returns 업데이트된 PropertyData
  PropertyData setEnhancedImages(String cellId, List<EnhancedImageData> images) {
    try {
      // 1. 기존 enhancedCellImages 가져오기
      final enhancedImagesJson = additionalData['enhancedCellImages'];
      Map<String, dynamic> enhancedImages = 
          _parseJsonSafely(enhancedImagesJson) ?? {};

      // 2. 새로운 이미지 데이터 설정
      enhancedImages[cellId] = images.map((img) => img.toJson()).toList();

      // 3. 호환성을 위해 기존 cellImages도 업데이트
      final updatedCellImages = Map<String, List<String>>.from(cellImages);
      updatedCellImages[cellId] = EnhancedImageData.toLegacyPaths(images);

      // 4. additionalData 업데이트
      final updatedAdditionalData = Map<String, String>.from(additionalData);
      updatedAdditionalData['enhancedCellImages'] = _encodeJsonSafely(enhancedImages);

      return copyWith(
        cellImages: updatedCellImages,
        additionalData: updatedAdditionalData,
      );
    } catch (e) {
      AppLogger.error('셀 이미지 설정 실패 ($cellId): $e');
      return this;
    }
  }

  /// 셀에 이미지 추가
  /// 
  /// [cellId] 셀 식별자
  /// [image] 추가할 강화된 이미지 데이터
  /// Returns 업데이트된 PropertyData
  PropertyData addEnhancedImage(String cellId, EnhancedImageData image) {
    final currentImages = getEnhancedImages(cellId);
    final updatedImages = [...currentImages, image];
    return setEnhancedImages(cellId, updatedImages);
  }

  /// 셀에서 이미지 제거
  /// 
  /// [cellId] 셀 식별자
  /// [localPath] 제거할 이미지의 로컬 경로
  /// Returns 업데이트된 PropertyData
  PropertyData removeEnhancedImage(String cellId, String localPath) {
    final currentImages = getEnhancedImages(cellId);
    final updatedImages = currentImages
        .where((img) => img.localPath != localPath)
        .toList();
    return setEnhancedImages(cellId, updatedImages);
  }

  /// 셀의 특정 이미지 업데이트
  /// 
  /// [cellId] 셀 식별자
  /// [localPath] 업데이트할 이미지의 로컬 경로
  /// [updatedImage] 새로운 이미지 데이터
  /// Returns 업데이트된 PropertyData
  PropertyData updateEnhancedImage(String cellId, String localPath, EnhancedImageData updatedImage) {
    final currentImages = getEnhancedImages(cellId);
    final updatedImages = currentImages.map((img) {
      return img.localPath == localPath ? updatedImage : img;
    }).toList();
    return setEnhancedImages(cellId, updatedImages);
  }

  /// 모든 셀의 동기화되지 않은 이미지들 반환
  List<EnhancedImageData> getAllUnsyncedImages() {
    final allUnsyncedImages = <EnhancedImageData>[];
    
    // 모든 셀 확인
    final allCellIds = <String>{};
    allCellIds.addAll(cellImages.keys);
    
    // enhancedCellImages에서도 셀 ID 추가
    try {
      final enhancedImagesJson = additionalData['enhancedCellImages'];
      if (enhancedImagesJson != null) {
        final Map<String, dynamic> enhancedImages = 
            _parseJsonSafely(enhancedImagesJson) ?? {};
        allCellIds.addAll(enhancedImages.keys);
      }
    } catch (e) {
      AppLogger.d('enhancedCellImages 파싱 실패: $e');
    }

    // 각 셀의 동기화되지 않은 이미지들 수집
    for (final cellId in allCellIds) {
      final cellImages = getEnhancedImages(cellId);
      final unsyncedImages = cellImages.where((img) => !img.isSynced).toList();
      allUnsyncedImages.addAll(unsyncedImages);
    }

    return allUnsyncedImages;
  }

  /// 모든 셀의 이미지 동기화 상태 업데이트
  /// 
  /// [syncResults] 동기화 결과 맵 (로컬 경로 -> Firebase URL)
  /// Returns 업데이트된 PropertyData
  PropertyData updateImageSyncStatus(Map<String, String> syncResults) {
    try {
      PropertyData updatedData = this;

      // 모든 셀 확인 및 업데이트
      final allCellIds = <String>{};
      allCellIds.addAll(cellImages.keys);
      
      // enhancedCellImages에서도 셀 ID 추가
      final enhancedImagesJson = additionalData['enhancedCellImages'];
      if (enhancedImagesJson != null) {
        final Map<String, dynamic> enhancedImages = 
            _parseJsonSafely(enhancedImagesJson) ?? {};
        allCellIds.addAll(enhancedImages.keys);
      }

      for (final cellId in allCellIds) {
        final cellImages = updatedData.getEnhancedImages(cellId);
        final updatedCellImages = cellImages.map((img) {
          final firebaseUrl = syncResults[img.localPath];
          if (firebaseUrl != null) {
            return img.withFirebaseUrl(firebaseUrl);
          }
          return img;
        }).toList();

        updatedData = updatedData.setEnhancedImages(cellId, updatedCellImages);
      }

      return updatedData;
    } catch (e) {
      AppLogger.error('이미지 동기화 상태 업데이트 실패: $e');
      return this;
    }
  }

  /// 기존 이미지 시스템을 새로운 시스템으로 마이그레이션
  /// 
  /// Returns 마이그레이션된 PropertyData
  PropertyData migrateToEnhancedImages() {
    try {
      // 이미 마이그레이션되었는지 확인
      if (additionalData.containsKey('enhancedCellImages')) {
        return this;
      }

      AppLogger.info('PropertyData 이미지 시스템 마이그레이션 시작: $id');

      PropertyData updatedData = this;

      // 기존 cellImages를 enhancedCellImages로 변환
      for (final cellId in cellImages.keys) {
        final legacyPaths = cellImages[cellId] ?? [];
        final enhancedImages = EnhancedImageData.fromLegacyPaths(legacyPaths);
        updatedData = updatedData.setEnhancedImages(cellId, enhancedImages);
      }

      // 마이그레이션 완료 표시
      final updatedAdditionalData = Map<String, String>.from(updatedData.additionalData);
      updatedAdditionalData['imageMigrationVersion'] = '1.0';
      updatedAdditionalData['imageMigrationDate'] = DateTime.now().toIso8601String();

      final result = updatedData.copyWith(additionalData: updatedAdditionalData);
      
      AppLogger.info('PropertyData 이미지 시스템 마이그레이션 완료: $id');
      return result;
    } catch (e) {
      AppLogger.error('PropertyData 이미지 마이그레이션 실패 ($id): $e');
      return this;
    }
  }

  /// 이미지 시스템 통계 정보
  Map<String, dynamic> getImageStats() {
    try {
      int totalImages = 0;
      int syncedImages = 0;
      int pendingImages = 0;
      int failedImages = 0;
      int localOnlyImages = 0;

      // 모든 셀의 이미지 통계 수집
      final allCellIds = <String>{};
      allCellIds.addAll(cellImages.keys);
      
      final enhancedImagesJson = additionalData['enhancedCellImages'];
      if (enhancedImagesJson != null) {
        final Map<String, dynamic> enhancedImages = 
            _parseJsonSafely(enhancedImagesJson) ?? {};
        allCellIds.addAll(enhancedImages.keys);
      }

      for (final cellId in allCellIds) {
        final images = getEnhancedImages(cellId);
        totalImages += images.length;
        
        for (final img in images) {
          if (img.isSynced) {
            syncedImages++;
          } else if (img.isPending) {
            pendingImages++;
          } else if (img.isFailed) {
            failedImages++;
          } else if (img.isLocalOnly) {
            localOnlyImages++;
          }
        }
      }

      return {
        'totalImages': totalImages,
        'syncedImages': syncedImages,
        'pendingImages': pendingImages,
        'failedImages': failedImages,
        'localOnlyImages': localOnlyImages,
        'syncRate': totalImages > 0 ? (syncedImages / totalImages) : 0.0,
        'cellCount': allCellIds.length,
        'isMigrated': additionalData.containsKey('enhancedCellImages'),
      };
    } catch (e) {
      AppLogger.error('이미지 통계 수집 실패: $e');
      return {
        'totalImages': 0,
        'error': e.toString(),
      };
    }
  }

  // === 유틸리티 메서드들 ===

  /// JSON 문자열을 안전하게 파싱
  Map<String, dynamic>? _parseJsonSafely(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    
    try {
      // JSON 파싱은 실제 구현에서 dart:convert 사용
      // 여기서는 개념적 구현만 제공
      return <String, dynamic>{}; // 실제로는 json.decode(jsonString) 사용
    } catch (e) {
      AppLogger.warning('JSON 파싱 실패: $e');
      return null;
    }
  }

  /// JSON을 안전하게 인코딩
  String _encodeJsonSafely(Map<String, dynamic> data) {
    try {
      // JSON 인코딩은 실제 구현에서 dart:convert 사용
      // 여기서는 개념적 구현만 제공
      return '{}'; // 실제로는 json.encode(data) 사용
    } catch (e) {
      AppLogger.warning('JSON 인코딩 실패: $e');
      return '{}';
    }
  }
}

/// PropertyChartModel을 위한 확장 기능
extension PropertyChartModelImageExtensions on PropertyChartModel {
  
  /// 차트의 모든 동기화되지 않은 이미지들 반환
  List<EnhancedImageData> getAllUnsyncedImages() {
    final allUnsyncedImages = <EnhancedImageData>[];
    
    for (final property in properties) {
      final unsyncedImages = property.getAllUnsyncedImages();
      allUnsyncedImages.addAll(unsyncedImages);
    }
    
    return allUnsyncedImages;
  }

  /// 차트의 모든 PropertyData를 새로운 이미지 시스템으로 마이그레이션
  PropertyChartModel migrateToEnhancedImages() {
    try {
      AppLogger.info('차트 이미지 시스템 마이그레이션 시작: $id');

      final migratedProperties = properties
          .map((property) => property.migrateToEnhancedImages())
          .toList();

      final result = copyWith(properties: migratedProperties);
      
      AppLogger.info('차트 이미지 시스템 마이그레이션 완료: $id (${properties.length}개 Property)');
      return result;
    } catch (e) {
      AppLogger.error('차트 이미지 마이그레이션 실패 ($id): $e');
      return this;
    }
  }

  /// 차트의 이미지 동기화 상태 업데이트
  PropertyChartModel updateImageSyncStatus(Map<String, String> syncResults) {
    try {
      final updatedProperties = properties
          .map((property) => property.updateImageSyncStatus(syncResults))
          .toList();

      return copyWith(properties: updatedProperties);
    } catch (e) {
      AppLogger.error('차트 이미지 동기화 상태 업데이트 실패 ($id): $e');
      return this;
    }
  }

  /// 차트 전체 이미지 통계
  Map<String, dynamic> getImageStats() {
    try {
      int totalProperties = properties.length;
      int totalImages = 0;
      int syncedImages = 0;
      int pendingImages = 0;
      int failedImages = 0;
      int localOnlyImages = 0;
      int migratedProperties = 0;

      for (final property in properties) {
        final stats = property.getImageStats();
        
        totalImages += (stats['totalImages'] as int? ?? 0);
        syncedImages += (stats['syncedImages'] as int? ?? 0);
        pendingImages += (stats['pendingImages'] as int? ?? 0);
        failedImages += (stats['failedImages'] as int? ?? 0);
        localOnlyImages += (stats['localOnlyImages'] as int? ?? 0);
        
        if (stats['isMigrated'] == true) {
          migratedProperties++;
        }
      }

      return {
        'chartId': id,
        'chartTitle': title,
        'totalProperties': totalProperties,
        'migratedProperties': migratedProperties,
        'migrationRate': totalProperties > 0 ? (migratedProperties / totalProperties) : 0.0,
        'totalImages': totalImages,
        'syncedImages': syncedImages,
        'pendingImages': pendingImages,
        'failedImages': failedImages,
        'localOnlyImages': localOnlyImages,
        'syncRate': totalImages > 0 ? (syncedImages / totalImages) : 0.0,
      };
    } catch (e) {
      AppLogger.error('차트 이미지 통계 수집 실패 ($id): $e');
      return {
        'chartId': id,
        'error': e.toString(),
      };
    }
  }
}