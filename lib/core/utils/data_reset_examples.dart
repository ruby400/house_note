import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/data_reset_dialog.dart';
import '../../services/data_reset_service.dart';
import 'logger.dart';

/// 데이터 초기화 기능 사용 예시들
/// 
/// 이 파일은 앱의 다양한 화면에서 데이터 초기화 기능을 
/// 어떻게 사용할 수 있는지 보여주는 예시 코드들을 포함합니다.
class DataResetExamples {
  
  /// 예시 1: 설정 화면에서 "모든 데이터 초기화" 버튼
  static Widget buildResetAllDataButton(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.delete_forever,
        color: Colors.red,
      ),
      title: const Text(
        '모든 데이터 초기화',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: const Text('모든 차트 데이터와 이미지를 삭제합니다'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        final success = await DataResetDialogUtils.executeReset(
          context,
          ResetType.all,
        );
        
        if (success) {
          // 필요한 경우 추가 작업 (예: 첫 화면으로 이동)
          // Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      },
    );
  }

  /// 예시 2: 차트 화면에서 "현재 차트 초기화" 버튼
  static Widget buildClearCurrentChartButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        await DataResetDialogUtils.executeReset(
          context,
          ResetType.currentChart,
          customTitle: '현재 차트 초기화',
          customMessage: '현재 차트의 모든 데이터를 삭제하고 빈 차트로 만듭니다.',
        );
      },
      icon: const Icon(Icons.clear_all),
      label: const Text('차트 비우기'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// 예시 3: 설정 화면에서 여러 초기화 옵션 제공
  static Widget buildResetOptionsButton(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.settings_backup_restore),
        title: const Text('데이터 초기화'),
        subtitle: const Text('다양한 초기화 옵션을 선택할 수 있습니다'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => DataResetOptionsDialog.showOptionsDialog(context),
      ),
    );
  }

  /// 예시 4: Consumer를 사용한 직접적인 서비스 호출
  static Widget buildDirectServiceCallExample() {
    return Consumer(
      builder: (context, ref, child) {
        return ElevatedButton(
          onPressed: () async {
            final dataResetService = ref.read(dataResetServiceProvider);
            
            // 직접 서비스 호출
            final result = await dataResetService.resetToDefaultChart();
            
            if (context.mounted) {
              DataResetDialogUtils.showResultSnackBar(context, result);
            }
          },
          child: const Text('기본 차트로 리셋'),
        );
      },
    );
  }

  /// 예시 5: 앱 시작 시 개발자 도구에서 사용할 수 있는 초기화 함수
  static void developmentResetData(WidgetRef ref) {
    final dataResetService = ref.read(dataResetServiceProvider);
    
    // 개발 중에만 사용하는 데이터 초기화
    dataResetService.resetAllData().then((result) {
      AppLogger.info('Development reset result: ${result.message}');
    });
  }

  /// 예시 6: FloatingActionButton에서 초기화 옵션 표시
  static Widget buildResetFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => DataResetOptionsDialog.showOptionsDialog(context),
      icon: const Icon(Icons.refresh),
      label: const Text('초기화'),
      backgroundColor: Colors.red,
    );
  }

  /// 예시 7: 조건부 초기화 (특정 상황에서만 초기화)
  static Widget buildConditionalResetButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final dataResetService = ref.read(dataResetServiceProvider);
        
        return ElevatedButton(
          onPressed: () async {
            // 로그인 상태에 따른 조건부 초기화
            if (!dataResetService.isSignedIn) {
              // 로그인하지 않은 경우: 모든 데이터 초기화
              await DataResetDialogUtils.executeReset(
                context,
                ResetType.all,
                customMessage: '로그인하지 않은 상태에서 모든 로컬 데이터를 초기화합니다.',
              );
            } else {
              // 로그인한 경우: 로컬 데이터만 초기화하고 Firebase 경고 표시
              await DataResetDialogUtils.executeReset(
                context,
                ResetType.chartsToDefault,
                customMessage: '로컬 데이터를 기본값으로 초기화합니다. Firebase 데이터는 다시 동기화될 수 있습니다.',
              );
            }
          },
          child: Text(
            dataResetService.isSignedIn ? '로컬 데이터 리셋' : '모든 데이터 초기화',
          ),
        );
      },
    );
  }
}

/// 데이터 초기화 기능을 포함한 데모 화면
class DataResetDemoScreen extends StatelessWidget {
  const DataResetDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('데이터 초기화 데모'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '데이터 초기화 기능 예시',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          const Text(
            '1. 설정 화면 스타일',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DataResetExamples.buildResetAllDataButton(context),
          const SizedBox(height: 8),
          DataResetExamples.buildResetOptionsButton(context),
          const SizedBox(height: 20),
          
          const Text(
            '2. 버튼 스타일',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DataResetExamples.buildClearCurrentChartButton(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DataResetExamples.buildDirectServiceCallExample(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          const Text(
            '3. 조건부 초기화',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DataResetExamples.buildConditionalResetButton(context),
        ],
      ),
      floatingActionButton: DataResetExamples.buildResetFAB(context),
    );
  }
}

/// 앱에서 데이터 초기화 기능을 사용하는 방법:
/// 
/// 1. 간단한 사용법:
/// ```dart
/// // 특정 초기화 타입으로 바로 실행
/// final success = await DataResetDialogUtils.executeReset(
///   context,
///   ResetType.all,
/// );
/// ```
/// 
/// 2. 옵션 선택 다이얼로그 표시:
/// ```dart
/// await DataResetOptionsDialog.showOptionsDialog(context);
/// ```
/// 
/// 3. 직접 서비스 호출:
/// ```dart
/// final dataResetService = ref.read(dataResetServiceProvider);
/// final result = await dataResetService.resetAllData();
/// DataResetDialogUtils.showResultSnackBar(context, result);
/// ```
/// 
/// 4. Consumer 내에서 사용:
/// ```dart
/// Consumer(
///   builder: (context, ref, child) {
///     return ElevatedButton(
///       onPressed: () async {
///         final service = ref.read(dataResetServiceProvider);
///         final result = await service.clearAllCharts();
///         if (context.mounted) {
///           DataResetDialogUtils.showResultSnackBar(context, result);
///         }
///       },
///       child: Text('모든 차트 삭제'),
///     );
///   },
/// )
/// ```