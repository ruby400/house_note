class PropertyChartModel {
  final String id;
  final String title;
  final DateTime date;
  final List<PropertyData> properties;
  final Map<int, double> columnWidths;
  final Map<String, List<String>> columnOptions;
  final List<String>? columnOrder;
  final Map<String, bool>? columnVisibility; // 컬럼 표시 여부
  
  PropertyChartModel({
    required this.id,
    required this.title,
    required this.date,
    this.properties = const [],
    this.columnWidths = const {},
    this.columnOptions = const {},
    this.columnOrder,
    this.columnVisibility,
  });
  
  PropertyChartModel copyWith({
    String? id,
    String? title,
    DateTime? date,
    List<PropertyData>? properties,
    Map<int, double>? columnWidths,
    Map<String, List<String>>? columnOptions,
    List<String>? columnOrder,
    Map<String, bool>? columnVisibility,
  }) {
    return PropertyChartModel(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      properties: properties ?? this.properties,
      columnWidths: columnWidths ?? this.columnWidths,
      columnOptions: columnOptions ?? this.columnOptions,
      columnOrder: columnOrder ?? this.columnOrder,
      columnVisibility: columnVisibility ?? this.columnVisibility,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'properties': properties.map((p) => p.toJson()).toList(),
      'columnWidths': columnWidths.map((k, v) => MapEntry(k.toString(), v)),
      'columnOptions': columnOptions,
      'columnOrder': columnOrder,
      'columnVisibility': columnVisibility,
    };
  }
  
  factory PropertyChartModel.fromJson(Map<String, dynamic> json) {
    try {
      // null 체크 및 타입 검증 강화
      if (json.isEmpty) {
        return _createDefaultChart();
      }

      // 안전한 ID 파싱
      final id = _parseId(json['id']);
      
      // 안전한 제목 파싱
      final title = _parseTitle(json['title']);
      
      // 안전한 날짜 파싱
      final date = _parseDate(json['date']);
      
      // 안전한 프로퍼티 목록 파싱
      final properties = _parseProperties(json['properties']);
      
      // 안전한 컬럼 너비 파싱
      final columnWidths = _parseColumnWidths(json['columnWidths']);
      
      // 안전한 컬럼 옵션 파싱
      final columnOptions = _parseColumnOptions(json['columnOptions']);
      
      // 안전한 컬럼 순서 파싱
      final columnOrder = _parseColumnOrder(json['columnOrder']);
      
      // 안전한 컬럼 표시 여부 파싱
      final columnVisibility = _parseColumnVisibility(json['columnVisibility']);

      return PropertyChartModel(
        id: id,
        title: title,
        date: date,
        properties: properties,
        columnWidths: columnWidths,
        columnOptions: columnOptions,
        columnOrder: columnOrder,
        columnVisibility: columnVisibility,
      );
    } catch (e) {
      // 상세한 에러 로깅은 production에서 제거
      
      // 파싱 실패시 기본값 반환
      return _createDefaultChart();
    }
  }

  // 안전한 파싱을 위한 헬퍼 메서드들
  static String _parseId(dynamic value) {
    if (value == null) return DateTime.now().millisecondsSinceEpoch.toString();
    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : stringValue;
  }

  static String _parseTitle(dynamic value) {
    if (value == null) return '새 차트';
    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? '새 차트' : stringValue;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    
    try {
      if (value is String) {
        return DateTime.parse(value);
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is DateTime) {
        return value;
      }
    } catch (e) {
      // 날짜 파싱 실패는 현재 시간으로 대체
    }
    
    return DateTime.now();
  }

  static List<PropertyData> _parseProperties(dynamic value) {
    if (value == null || value is! List) return [];
    
    final List<PropertyData> properties = [];
    for (int i = 0; i < value.length; i++) {
      try {
        final propertyJson = value[i];
        if (propertyJson is Map<String, dynamic>) {
          properties.add(PropertyData.fromJson(propertyJson));
        } else {
          // 기본 프로퍼티 추가
          properties.add(PropertyData(id: '${DateTime.now().millisecondsSinceEpoch}_$i'));
        }
      } catch (e) {
        // 에러 발생 시 기본 프로퍼티 추가
        properties.add(PropertyData(id: '${DateTime.now().millisecondsSinceEpoch}_$i'));
      }
    }
    
    return properties;
  }

  static Map<int, double> _parseColumnWidths(dynamic value) {
    if (value == null || value is! Map) return {};
    
    final Map<int, double> columnWidths = {};
    value.forEach((key, value) {
      try {
        final intKey = int.parse(key.toString());
        final doubleValue = double.parse(value.toString());
        
        // 유효한 범위 검증
        if (intKey >= 0 && doubleValue > 0 && doubleValue <= 1000) {
          columnWidths[intKey] = doubleValue;
        }
      } catch (e) {
        // 컬럼 너비 파싱 실패시 무시
      }
    });
    
    return columnWidths;
  }

  static PropertyChartModel _createDefaultChart() {
    return PropertyChartModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '새 차트',
      date: DateTime.now(),
      properties: [],
      columnWidths: {},
      columnOptions: {},
      columnOrder: null,
    );
  }
  
  static Map<String, List<String>> _parseColumnOptions(dynamic options) {
    try {
      if (options is Map) {
        final result = <String, List<String>>{};
        options.forEach((key, value) {
          if (value is List) {
            result[key.toString()] = value.map((e) => e.toString()).toList();
          }
        });
        return result;
      }
    } catch (e) {
      // 파싱 실패
    }
    return {};
  }
  
  static List<String>? _parseColumnOrder(dynamic order) {
    try {
      if (order is List) {
        return order.map((e) => e.toString()).toList();
      }
    } catch (e) {
      // 파싱 실패
    }
    return null;
  }
  
  static Map<String, bool>? _parseColumnVisibility(dynamic visibility) {
    try {
      if (visibility is Map) {
        Map<String, bool> result = {};
        visibility.forEach((key, value) {
          if (key is String && value is bool) {
            result[key] = value;
          }
        });
        return result.isNotEmpty ? result : null;
      }
    } catch (e) {
      // 파싱 실패
    }
    return null;
  }
}

class PropertyData {
  final String id;
  final String order; // 순번
  final String name; // 집 이름
  final String deposit; // 보증금
  final String rent; // 월세
  final String direction; // 재계/방향
  final String landlordEnvironment; // 집주인 환경
  final int rating; // 변천 (별점)
  final String? memo; // 메모
  final DateTime? createdAt; // 등록일
  final Map<String, List<String>> cellImages; // 셀별 사진
  final Map<String, String> additionalData; // 추가 데이터
  
  PropertyData({
    required this.id,
    this.order = '',
    this.name = '',
    this.deposit = '',
    this.rent = '',
    this.direction = '',
    this.landlordEnvironment = '',
    this.rating = 0,
    this.memo,
    this.createdAt,
    Map<String, List<String>>? cellImages,
    Map<String, String>? additionalData,
  }) : cellImages = cellImages ?? {},
       additionalData = additionalData ?? {};
  
  PropertyData copyWith({
    String? id,
    String? order,
    String? name,
    String? deposit,
    String? rent,
    String? direction,
    String? landlordEnvironment,
    int? rating,
    String? memo,
    DateTime? createdAt,
    Map<String, List<String>>? cellImages,
    Map<String, String>? additionalData,
  }) {
    return PropertyData(
      id: id ?? this.id,
      order: order ?? this.order,
      name: name ?? this.name,
      deposit: deposit ?? this.deposit,
      rent: rent ?? this.rent,
      direction: direction ?? this.direction,
      landlordEnvironment: landlordEnvironment ?? this.landlordEnvironment,
      rating: rating ?? this.rating,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      cellImages: cellImages ?? this.cellImages,
      additionalData: additionalData ?? this.additionalData,
    );
  }
  
  List<String> getRowData([int? maxColumns]) {
    final baseData = [
      order,
      name,
      deposit,
      rent,
      direction,
      landlordEnvironment,
      rating.toString(),
    ];
    
    // 추가된 컬럼 데이터를 포함
    final additionalValues = <String>[];
    
    // 디버그 로그 추가
    // AppLogger.d('getRowData for Property $id: maxColumns=$maxColumns');
    
    // ALWAYS use maxColumns logic to ensure consistency
    final targetColumns = maxColumns ?? (additionalData.isEmpty ? 7 : additionalData.keys.length + 7);
    // AppLogger.d('Target columns: $targetColumns');
    
    if (targetColumns > 7) {
      // AppLogger.d('Processing additional columns from 7 to ${targetColumns - 1}');
      for (int columnIndex = 7; columnIndex < targetColumns; columnIndex++) {
        // Force fetch each value individually to avoid reference issues
        final key = 'col_$columnIndex';
        final value = additionalData.containsKey(key) ? additionalData[key]! : '';
        additionalValues.add(value);
        // AppLogger.d('[$columnIndex] $key: "$value" (exists: ${additionalData.containsKey(key)})');
      }
    }
    
    final result = [...baseData, ...additionalValues];
    // AppLogger.d('Final result: $result, length: ${result.length}');
    
    return result;
  }
  
  // 새로운 컬럼명 기반 업데이트 메서드
  PropertyData updateCellByName(String columnName, String value, Map<String, String> columnKey) {
    try {
      final safeValue = value;
      // AppLogger.d('updateCellByName: column="$columnName", value="$safeValue", key=${columnKey['key']}');
      
      if (columnKey['type'] == 'base') {
        // 기본 컬럼 업데이트
        switch (columnKey['key']) {
          case 'order':
            return copyWith(order: safeValue);
          case 'name':
            return copyWith(name: safeValue);
          case 'deposit':
            return copyWith(deposit: safeValue);
          case 'rent':
            return copyWith(rent: safeValue);
          case 'direction':
            return copyWith(direction: safeValue);
          case 'landlordEnvironment':
            return copyWith(landlordEnvironment: safeValue);
          case 'rating':
            final ratingValue = int.tryParse(safeValue) ?? 0;
            return copyWith(rating: ratingValue.clamp(0, 5));
          case 'memo':
            return copyWith(memo: safeValue.isEmpty ? null : safeValue);
        }
      } else {
        // 추가 컬럼 업데이트
        final newAdditionalData = Map<String, String>.from(additionalData);
        newAdditionalData[columnKey['key']!] = safeValue;
        // AppLogger.d('Updated additionalData: $newAdditionalData');
        return copyWith(additionalData: newAdditionalData);
      }
      
      return this;
    } catch (e) {
      // AppLogger.error('updateCellByName error: $e');
      return this;
    }
  }

  PropertyData updateCell(int columnIndex, String value) {
    try {
      // 입력값 검증
      if (columnIndex < 0) {
        return this; // 잘못된 인덱스면 원본 반환
      }
      
      // 입력값을 그대로 사용 (자동 비워진 데이터 예방)
      final safeValue = value;
      
      switch (columnIndex) {
        case 0: 
          return copyWith(order: safeValue);
        case 1: 
          return copyWith(name: safeValue);
        case 2: 
          return copyWith(deposit: safeValue);
        case 3: 
          return copyWith(rent: safeValue);
        case 4: 
          return copyWith(direction: safeValue);
        case 5: 
          return copyWith(landlordEnvironment: safeValue);
        case 6: 
          final ratingValue = int.tryParse(safeValue) ?? 0;
          final clampedRating = ratingValue.clamp(0, 5);
          return copyWith(rating: clampedRating);
        default: 
          // 추가 컨럼의 경우
          final newAdditionalData = Map<String, String>.from(additionalData);
          newAdditionalData['col_$columnIndex'] = safeValue;
          return copyWith(additionalData: newAdditionalData);
      }
    } catch (e) {
      // 에러 발생시 원본 객체 반환
      return this;
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'name': name,
      'deposit': deposit,
      'rent': rent,
      'direction': direction,
      'landlordEnvironment': landlordEnvironment,
      'rating': rating,
      'memo': memo,
      'createdAt': createdAt?.toIso8601String(),
      'cellImages': cellImages,
      'additionalData': additionalData,
    };
  }
  
  factory PropertyData.fromJson(Map<String, dynamic> json) {
    try {
      // null 체크 및 타입 검증 강화
      if (json.isEmpty) {
        return PropertyData._createDefault();
      }

      return PropertyData(
        id: _parsePropertyId(json['id']),
        order: _parseString(json['order']),
        name: _parseString(json['name']),
        deposit: _parseString(json['deposit']),
        rent: _parseString(json['rent']),
        direction: _parseString(json['direction']),
        landlordEnvironment: _parseString(json['landlordEnvironment']),
        rating: _parseRating(json['rating']),
        memo: _parseString(json['memo']).isEmpty ? null : _parseString(json['memo']),
        createdAt: _parseDateTime(json['createdAt']),
        cellImages: _parseCellImages(json['cellImages']),
        additionalData: _parseAdditionalData(json['additionalData']),
      );
    } catch (e) {
      // 파싱 실패시 기본값 사용
      
      return PropertyData._createDefault();
    }
  }

  // 안전한 파싱을 위한 헬퍼 메서드들
  static String _parsePropertyId(dynamic value) {
    if (value == null) return DateTime.now().millisecondsSinceEpoch.toString();
    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : stringValue;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static int _parseRating(dynamic value) {
    try {
      if (value == null) return 0;
      
      int rating;
      if (value is int) {
        rating = value;
      } else if (value is String) {
        rating = int.tryParse(value) ?? 0;
      } else if (value is double) {
        rating = value.round();
      } else {
        return 0;
      }
      
      // 별점은 0-5 범위로 제한
      return rating.clamp(0, 5);
    } catch (e) {
      return 0;
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is String) {
        if (value.isEmpty) return null;
        return DateTime.parse(value);
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is DateTime) {
        return value;
      }
    } catch (e) {
      // 날짜 파싱 실패
    }
    
    return null;
  }

  static PropertyData _createDefault() {
    return PropertyData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      order: '',
      name: '',
      deposit: '',
      rent: '',
      direction: '',
      landlordEnvironment: '',
      rating: 0,
      memo: null,
      createdAt: DateTime.now(),
      cellImages: {},
      additionalData: {},
    );
  }
  
  static Map<String, List<String>> _parseCellImages(dynamic images) {
    try {
      if (images is Map) {
        final result = <String, List<String>>{};
        images.forEach((key, value) {
          if (value is List) {
            result[key.toString()] = value.map((e) => e.toString()).toList();
          }
        });
        return result;
      }
    } catch (e) {
      // 파싱 실패
    }
    return {};
  }
  
  static Map<String, String> _parseAdditionalData(dynamic data) {
    try {
      if (data is Map) {
        final result = <String, String>{};
        data.forEach((key, value) {
          result[key.toString()] = value.toString();
        });
        return result;
      }
    } catch (e) {
      // 파싱 실패
    }
    return {};
  }
}