import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/data_reset_service.dart';

/// 데이터 초기화 확인 다이얼로그
class DataResetDialog extends ConsumerStatefulWidget {
  final ResetType resetType;
  final String? customTitle;
  final String? customMessage;

  const DataResetDialog({
    super.key,
    required this.resetType,
    this.customTitle,
    this.customMessage,
  });

  @override
  ConsumerState<DataResetDialog> createState() => _DataResetDialogState();
}

class _DataResetDialogState extends ConsumerState<DataResetDialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final dataResetService = ref.read(dataResetServiceProvider);
    
    return AlertDialog(
      title: Text(
        widget.customTitle ?? '${widget.resetType.displayName} 확인',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.customMessage ?? widget.resetType.description,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (dataResetService.isSignedIn) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dataResetService.firebaseWarning,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            '이 작업은 되돌릴 수 없습니다. 정말 진행하시겠습니까?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _performReset,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('초기화'),
        ),
      ],
    );
  }

  Future<void> _performReset() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final dataResetService = ref.read(dataResetServiceProvider);
      DataResetResult result;

      switch (widget.resetType) {
        case ResetType.all:
          result = await dataResetService.resetAllData();
          break;
        case ResetType.chartsToDefault:
          result = await dataResetService.resetToDefaultChart();
          break;
        case ResetType.chartsOnly:
          result = await dataResetService.clearAllCharts();
          break;
        case ResetType.currentChart:
          result = await dataResetService.clearCurrentChartData();
          break;
        case ResetType.imagesOnly:
          result = await dataResetService.cleanupImagesOnly();
          break;
      }

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(
          DataResetResult.failure(
            error: e.toString(),
            resetType: widget.resetType,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

/// 데이터 초기화 다이얼로그 표시 유틸리티
class DataResetDialogUtils {
  /// 데이터 초기화 다이얼로그 표시
  static Future<DataResetResult?> showResetDialog(
    BuildContext context,
    ResetType resetType, {
    String? customTitle,
    String? customMessage,
  }) async {
    return await showDialog<DataResetResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DataResetDialog(
        resetType: resetType,
        customTitle: customTitle,
        customMessage: customMessage,
      ),
    );
  }

  /// 결과 스낵바 표시
  static void showResultSnackBar(
    BuildContext context,
    DataResetResult result,
  ) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            result.isSuccess ? Icons.check_circle : Icons.error,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.message,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// 초기화 실행 및 결과 표시 (원스톱 함수)
  static Future<bool> executeReset(
    BuildContext context,
    ResetType resetType, {
    String? customTitle,
    String? customMessage,
  }) async {
    final result = await showResetDialog(
      context,
      resetType,
      customTitle: customTitle,
      customMessage: customMessage,
    );

    if (result != null) {
      showResultSnackBar(context, result);
      return result.isSuccess;
    }

    return false; // 사용자가 취소한 경우
  }
}

/// 데이터 초기화 옵션 선택 다이얼로그
class DataResetOptionsDialog extends StatelessWidget {
  const DataResetOptionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '데이터 초기화 옵션',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOptionTile(
            context,
            icon: Icons.delete_forever,
            title: ResetType.all.displayName,
            description: ResetType.all.description,
            color: Colors.red,
            onTap: () => _selectOption(context, ResetType.all),
          ),
          const Divider(),
          _buildOptionTile(
            context,
            icon: Icons.refresh,
            title: ResetType.chartsToDefault.displayName,
            description: ResetType.chartsToDefault.description,
            color: Colors.orange,
            onTap: () => _selectOption(context, ResetType.chartsToDefault),
          ),
          const Divider(),
          _buildOptionTile(
            context,
            icon: Icons.clear_all,
            title: ResetType.chartsOnly.displayName,
            description: ResetType.chartsOnly.description,
            color: Colors.blue,
            onTap: () => _selectOption(context, ResetType.chartsOnly),
          ),
          const Divider(),
          _buildOptionTile(
            context,
            icon: Icons.image_not_supported,
            title: ResetType.imagesOnly.displayName,
            description: ResetType.imagesOnly.description,
            color: Colors.green,
            onTap: () => _selectOption(context, ResetType.imagesOnly),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
      ],
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _selectOption(BuildContext context, ResetType resetType) {
    Navigator.of(context).pop();
    DataResetDialogUtils.executeReset(context, resetType);
  }

  /// 옵션 선택 다이얼로그 표시
  static Future<void> showOptionsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const DataResetOptionsDialog(),
    );
  }
}