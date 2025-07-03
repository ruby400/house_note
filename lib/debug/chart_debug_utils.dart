import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/core/utils/logger.dart';
import 'package:house_note/data/models/property_chart_model.dart';
import 'package:house_note/providers/property_chart_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 90차트의 현재 데이터 상태를 확인하는 디버그 유틸리티
class ChartDebugUtils {
  
  /// 90차트의 현재 상태를 상세히 분석하고 출력
  static Future<void> analyzeChart90Status(WidgetRef ref) async {
    AppLogger.info('=== 90차트 데이터 상태 분석 시작 ===');
    
    try {
      // 1. 현재 Provider에서 로드된 차트 목록 확인
      final chartList = ref.read(propertyChartListProvider);
      AppLogger.info('현재 로드된 차트 개수: ${chartList.length}');
      
      // 2. 90차트 찾기
      PropertyChartModel? chart90;
      int chart90Index = -1;
      
      for (int i = 0; i < chartList.length; i++) {
        final chart = chartList[i];
        AppLogger.info('차트 $i: ID="${chart.id}", Title="${chart.title}"');
        
        if (chart.id == '90' || chart.title.contains('90')) {
          chart90 = chart;
          chart90Index = i;
          AppLogger.info('>>> 90차트 발견! (인덱스: $i) <<<');
          break;
        }
      }
      
      if (chart90 != null) {
        await _analyzeChart90Details(chart90, chart90Index);
      } else {
        AppLogger.warning('90차트를 찾을 수 없습니다.');
        AppLogger.info('사용 가능한 차트 ID들: ${chartList.map((c) => c.id).toList()}');
      }
      
      // 3. 로컬 저장소에서도 확인
      await _analyzeLocalStorageData();
      
    } catch (e, stackTrace) {
      AppLogger.error('90차트 분석 중 오류 발생', error: e, stackTrace: stackTrace);
    }
    
    AppLogger.info('=== 90차트 데이터 상태 분석 완료 ===');
  }
  
  /// 90차트의 상세 정보 분석
  static Future<void> _analyzeChart90Details(PropertyChartModel chart90, int index) async {
    AppLogger.info('\n=== 90차트 상세 분석 (인덱스: $index) ===');
    AppLogger.info('ID: ${chart90.id}');
    AppLogger.info('Title: ${chart90.title}');
    AppLogger.info('Date: ${chart90.date}');
    AppLogger.info('Properties 개수: ${chart90.properties.length}');
    
    // PropertyData 분석
    if (chart90.properties.isNotEmpty) {
      AppLogger.info('\n--- PropertyData 상세 분석 ---');
      for (int i = 0; i < chart90.properties.length; i++) {
        final property = chart90.properties[i];
        AppLogger.info('PropertyData $i:');
        AppLogger.info('  ID: ${property.id}');
        AppLogger.info('  Name: "${property.name}"');
        AppLogger.info('  Address: "${property.address}"');
        AppLogger.info('  Deposit: "${property.deposit}"');
        AppLogger.info('  Rent: "${property.rent}"');
        AppLogger.info('  Direction: "${property.direction}"');
        AppLogger.info('  LandlordEnvironment: "${property.landlordEnvironment}"');
        AppLogger.info('  Rating: ${property.rating}');
        
        // AdditionalData 분석
        if (property.additionalData.isNotEmpty) {
          AppLogger.info('  AdditionalData (${property.additionalData.length}개):');
          property.additionalData.forEach((key, value) {
            AppLogger.info('    - $key: "$value"');
          });
        } else {
          AppLogger.info('  AdditionalData: 비어있음');
        }
        
        // CellImages 분석
        if (property.cellImages.isNotEmpty) {
          AppLogger.info('  CellImages (${property.cellImages.length}개):');
          property.cellImages.forEach((key, value) {
            AppLogger.info('    - $key: ${value.length}개 이미지');
          });
        } else {
          AppLogger.info('  CellImages: 비어있음');
        }
        
        AppLogger.info('');
      }
    } else {
      AppLogger.warning('PropertyData가 비어있습니다.');
    }
    
    // ColumnOptions 분석
    AppLogger.info('--- ColumnOptions 분석 ---');
    if (chart90.columnOptions.isNotEmpty) {
      AppLogger.info('ColumnOptions (${chart90.columnOptions.length}개):');
      chart90.columnOptions.forEach((key, value) {
        AppLogger.info('  - $key: ${value.length}개 옵션');
        if (value.isNotEmpty) {
          AppLogger.info('    옵션들: ${value.join(', ')}');
        }
      });
    } else {
      AppLogger.info('ColumnOptions: 비어있음');
    }
    
    // ColumnVisibility 분석
    AppLogger.info('\n--- ColumnVisibility 분석 ---');
    if (chart90.columnVisibility != null && chart90.columnVisibility!.isNotEmpty) {
      int visibleCount = 0;
      int hiddenCount = 0;
      AppLogger.info('ColumnVisibility (${chart90.columnVisibility!.length}개):');
      chart90.columnVisibility!.forEach((key, value) {
        if (value) {
          visibleCount++;
          AppLogger.info('  ✓ $key: 표시됨');
        } else {
          hiddenCount++;
          AppLogger.info('  ✗ $key: 숨김');
        }
      });
      AppLogger.info('총 ${chart90.columnVisibility!.length}개 컬럼 (표시: $visibleCount, 숨김: $hiddenCount)');
    } else {
      AppLogger.info('ColumnVisibility: 비어있음');
    }
    
    // ColumnWidths 분석
    AppLogger.info('\n--- ColumnWidths 분석 ---');
    if (chart90.columnWidths.isNotEmpty) {
      AppLogger.info('ColumnWidths (${chart90.columnWidths.length}개):');
      chart90.columnWidths.forEach((index, width) {
        AppLogger.info('  - 컬럼 $index: ${width}px');
      });
    } else {
      AppLogger.info('ColumnWidths: 비어있음');
    }
    
    // ColumnOrder 분석
    AppLogger.info('\n--- ColumnOrder 분석 ---');
    if (chart90.columnOrder != null && chart90.columnOrder!.isNotEmpty) {
      AppLogger.info('ColumnOrder (${chart90.columnOrder!.length}개):');
      for (int i = 0; i < chart90.columnOrder!.length; i++) {
        AppLogger.info('  $i: ${chart90.columnOrder![i]}');
      }
    } else {
      AppLogger.info('ColumnOrder: 비어있음');
    }
  }
  
  /// 로컬 저장소 데이터 분석
  static Future<void> _analyzeLocalStorageData() async {
    try {
      AppLogger.info('\n=== 로컬 저장소 데이터 분석 ===');
      
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      AppLogger.info('저장된 모든 키들:');
      for (String key in allKeys) {
        if (key.contains('chart')) {
          AppLogger.info('  - $key');
        }
      }
      
      // 게스트 사용자 키 확인
      String guestKey = 'local_charts_guest';
      String? chartsJson = prefs.getString(guestKey);
      
      if (chartsJson != null) {
        AppLogger.info('\n게스트 사용자 차트 데이터 발견');
        await _analyzeLocalChartData(chartsJson, 'guest');
      } else {
        AppLogger.info('게스트 사용자 차트 데이터 없음');
      }
      
      // 다른 사용자 키들도 확인
      for (String key in allKeys) {
        if (key.startsWith('local_charts_') && key != guestKey) {
          String? userData = prefs.getString(key);
          if (userData != null) {
            String userId = key.replaceFirst('local_charts_', '');
            AppLogger.info('\n사용자 "$userId" 차트 데이터 발견');
            await _analyzeLocalChartData(userData, userId);
          }
        }
      }
      
    } catch (e) {
      AppLogger.error('로컬 저장소 분석 중 오류', error: e);
    }
  }
  
  /// 로컬 차트 데이터 분석
  static Future<void> _analyzeLocalChartData(String chartsJson, String userId) async {
    try {
      final chartsList = jsonDecode(chartsJson) as List;
      AppLogger.info('  총 차트 개수: ${chartsList.length}');
      
      // 90차트 찾기
      bool found90Chart = false;
      
      for (int i = 0; i < chartsList.length; i++) {
        final chart = chartsList[i] as Map<String, dynamic>;
        String title = chart['title'] ?? '';
        String id = chart['id'] ?? '';
        
        AppLogger.info('  차트 $i: ID="$id", Title="$title"');
        
        if (id == '90' || title.contains('90')) {
          found90Chart = true;
          AppLogger.info('    >>> 로컬 저장소에서 90차트 발견! <<<');
          
          // 간단한 분석
          List<dynamic>? properties = chart['properties'] as List<dynamic>?;
          AppLogger.info('    PropertyData 개수: ${properties?.length ?? 0}');
          
          Map<String, dynamic>? columnOptions = chart['columnOptions'] as Map<String, dynamic>?;
          AppLogger.info('    ColumnOptions 개수: ${columnOptions?.length ?? 0}');
          
          Map<String, dynamic>? columnVisibility = chart['columnVisibility'] as Map<String, dynamic>?;
          AppLogger.info('    ColumnVisibility 개수: ${columnVisibility?.length ?? 0}');
        }
      }
      
      if (!found90Chart) {
        AppLogger.info('  로컬 저장소에서 90차트를 찾을 수 없음');
      }
      
    } catch (e) {
      AppLogger.error('로컬 차트 데이터 분석 중 오류', error: e);
    }
  }
  
  /// 90차트의 잘못된 데이터 정리 (옵션)
  static Future<void> cleanupChart90Data(WidgetRef ref) async {
    AppLogger.info('=== 90차트 데이터 정리 시작 ===');
    
    try {
      final chartList = ref.read(propertyChartListProvider);
      PropertyChartModel? chart90;
      
      // 90차트 찾기
      for (int i = 0; i < chartList.length; i++) {
        final chart = chartList[i];
        if (chart.id == '90' || chart.title.contains('90')) {
          chart90 = chart;
          break;
        }
      }
      
      if (chart90 != null) {
        AppLogger.info('90차트 발견, 데이터 정리 중...');
        
        // 빈 PropertyData 제거
        final cleanedProperties = chart90.properties.where((property) {
          // 모든 필드가 비어있는 PropertyData 제거
          return property.name.isNotEmpty || 
                 property.address.isNotEmpty || 
                 property.deposit.isNotEmpty || 
                 property.rent.isNotEmpty ||
                 property.additionalData.isNotEmpty;
        }).toList();
        
        // 잘못된 AdditionalData 키 정리
        final cleanedPropertiesWithValidData = cleanedProperties.map((property) {
          final cleanedAdditionalData = <String, String>{};
          property.additionalData.forEach((key, value) {
            // col_* 형태의 키만 유지하거나 의미있는 데이터만 유지
            if (key.startsWith('col_') || value.trim().isNotEmpty) {
              cleanedAdditionalData[key] = value.trim();
            }
          });
          return property.copyWith(additionalData: cleanedAdditionalData);
        }).toList();
        
        // 업데이트된 차트 저장
        final cleanedChart = chart90.copyWith(properties: cleanedPropertiesWithValidData);
        ref.read(propertyChartListProvider.notifier).updateChart(cleanedChart);
        
        AppLogger.info('90차트 데이터 정리 완료');
        AppLogger.info('정리 전 PropertyData: ${chart90.properties.length}개');
        AppLogger.info('정리 후 PropertyData: ${cleanedPropertiesWithValidData.length}개');
        
      } else {
        AppLogger.warning('90차트를 찾을 수 없어 정리를 건너뜁니다.');
      }
      
    } catch (e, stackTrace) {
      AppLogger.error('90차트 데이터 정리 중 오류 발생', error: e, stackTrace: stackTrace);
    }
    
    AppLogger.info('=== 90차트 데이터 정리 완료 ===');
  }
  
  /// 특정 차트 ID로 차트 상세 분석
  static Future<void> analyzeChartById(WidgetRef ref, String chartId) async {
    AppLogger.info('=== 차트 ID "$chartId" 분석 시작 ===');
    
    try {
      final chart = ref.read(propertyChartListProvider.notifier).getChart(chartId);
      
      if (chart != null) {
        await _analyzeChart90Details(chart, -1);
      } else {
        AppLogger.warning('차트 ID "$chartId"를 찾을 수 없습니다.');
        
        final chartList = ref.read(propertyChartListProvider);
        AppLogger.info('사용 가능한 차트 ID들: ${chartList.map((c) => c.id).toList()}');
      }
      
    } catch (e, stackTrace) {
      AppLogger.error('차트 분석 중 오류 발생', error: e, stackTrace: stackTrace);
    }
    
    AppLogger.info('=== 차트 ID "$chartId" 분석 완료 ===');
  }
}