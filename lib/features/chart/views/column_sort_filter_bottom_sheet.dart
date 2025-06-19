import 'package:flutter/material.dart';

// 새로운 정렬/필터링 바텀시트
class ColumnSortFilterBottomSheet extends StatefulWidget {
  final String columnName;
  final String columnType;
  final String? currentSortColumn;
  final bool sortAscending;
  final dynamic currentFilter;
  final List<String> existingValues;
  final Function(bool) onSort;
  final Function(dynamic) onFilter;
  final Function(List<String>) onCustomSort;
  final Function(String) onRename;
  final Function() onDelete;
  final VoidCallback onQuickSort;
  final VoidCallback onColumnManagement;
  final VoidCallback onDirectSort;
  final VoidCallback onResetOrder;

  const ColumnSortFilterBottomSheet({
    super.key,
    required this.columnName,
    required this.columnType,
    required this.currentSortColumn,
    required this.sortAscending,
    this.currentFilter,
    this.existingValues = const [],
    required this.onSort,
    required this.onFilter,
    required this.onCustomSort,
    required this.onRename,
    required this.onDelete,
    required this.onQuickSort,
    required this.onColumnManagement,
    required this.onDirectSort,
    required this.onResetOrder,
  });

  @override
  State<ColumnSortFilterBottomSheet> createState() =>
      _ColumnSortFilterBottomSheetState();
}

class _ColumnSortFilterBottomSheetState
    extends State<ColumnSortFilterBottomSheet> {
  late TextEditingController _renameController;
  late TextEditingController _filterController;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController(text: widget.columnName);
    _filterController = TextEditingController(
      text: widget.currentFilter?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _renameController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 헤더
              Row(
                children: [
                  const Icon(Icons.tune, color: Color(0xFFFF8A65), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${widget.columnName} 설정',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 정렬 섹션
              _buildSortSection(),

              // 필터링 섹션
              _buildFilterSection(),

              // 컬럼 편집 섹션
              _buildEditSection(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortSection() {
    final bool isCurrentSort = widget.currentSortColumn == widget.columnName;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            const Color(0xFFFF8A65).withAlpha(25), // withOpacity -> withAlpha
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFFF8A65)
                .withAlpha(76)), // withOpacity -> withAlpha
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sort, color: Color(0xFFFF8A65)),
              const SizedBox(width: 8),
              const Text(
                '정렬',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isCurrentSort) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF8A65),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: const Text(
                    '활성',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onSort(true);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrentSort && widget.sortAscending
                        ? const Color(0xFFFF8A65)
                        : Colors.grey[200],
                    foregroundColor: isCurrentSort && widget.sortAscending
                        ? Colors.white
                        : Colors.grey[700],
                  ),
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  label: Text(_getSortLabel(true)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onSort(false);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrentSort && !widget.sortAscending
                        ? const Color(0xFFFF8A65)
                        : Colors.grey[200],
                    foregroundColor: isCurrentSort && !widget.sortAscending
                        ? Colors.white
                        : Colors.grey[700],
                  ),
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: Text(_getSortLabel(false)),
                ),
              ),
            ],
          ),
          // 정렬 순서 직접 설정 및 초기화 버튼
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCustomSortOrderDialog();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF8A65),
                    side: BorderSide(
                        color: const Color(0xFFFF8A65).withAlpha(128)),
                  ),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('순서 직접 설정'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onResetOrder();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('순서 초기화'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                '컬럼 편집',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _renameController,
            decoration: InputDecoration(
              labelText: '컬럼 이름',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFFF8A65), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    widget.onDelete();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('삭제'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_renameController.text.trim().isNotEmpty &&
                        _renameController.text.trim() != widget.columnName) {
                      widget.onRename(_renameController.text.trim());
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A65),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('저장'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCustomSortOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomSortOrderDialog(
        columnName: widget.columnName,
        existingValues: widget.existingValues,
        onOrderSet: (customOrder) {
          widget.onCustomSort(customOrder);
        },
      ),
    );
  }

  String _getSortLabel(bool ascending) {
    switch (widget.columnType) {
      case 'price':
        return ascending ? '낮은 가격순' : '높은 가격순';
      case 'rating':
        return ascending ? '낮은 별점순' : '높은 별점순';
      case 'date':
        return ascending ? '오래된 순' : '최신순';
      case 'select':
        if (widget.columnName.contains('방향') ||
            widget.columnName.contains('재계')) {
          return ascending ? '선호 순서대로' : '일반 순서대로';
        }
        return ascending ? '오름차순' : '내림차순';
      default:
        return ascending ? '오름차순' : '내림차순';
    }
  }

  String _getFilterLabel() {
    switch (widget.columnType) {
      case 'price':
        return '가격 필터';
      case 'rating':
        return '별점 필터';
      case 'date':
        return '날짜 필터';
      case 'select':
        return '옵션 필터';
      default:
        return '텍스트 필터';
    }
  }

  String _getFilterHint() {
    switch (widget.columnType) {
      case 'price':
        return '예: 1000000 (이상), <5000000 (미만)';
      case 'rating':
        return '예: 4 (이상), <3 (미만)';
      case 'date':
        return '예: 2024-01-01';
      case 'select':
        return '옵션값 입력';
      default:
        return '검색할 텍스트 입력';
    }
  }

  Widget _buildFilterSection() {
    final bool hasFilter = widget.currentFilter != null &&
        widget.currentFilter.toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                _getFilterLabel(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasFilter) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: const Text(
                    '활성',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _filterController,
            decoration: InputDecoration(
              hintText: _getFilterHint(),
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onFilter(_filterController.text.trim().isEmpty
                        ? null
                        : _filterController.text.trim());
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('필터 적용'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    widget.onFilter(null);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                  ),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('필터 해제'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

// 커스텀 정렬 순서 설정 다이얼로그
class CustomSortOrderDialog extends StatefulWidget {
  final String columnName;
  final List<String> existingValues;
  final Function(List<String>) onOrderSet;

  const CustomSortOrderDialog({
    super.key,
    required this.columnName,
    this.existingValues = const [],
    required this.onOrderSet,
  });

  @override
  State<CustomSortOrderDialog> createState() => _CustomSortOrderDialogState();
}

class _CustomSortOrderDialogState extends State<CustomSortOrderDialog> {
  List<String> _sortOrder = [];

  @override
  void initState() {
    super.initState();
    _sortOrder = [];
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.sort, color: Color(0xFFFF8A65)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.columnName} 정렬 순서',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '선호하는 순서대로 드래그해서 배치하세요',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (widget.existingValues.isNotEmpty) ...[
              const Text(
                '정렬할 항목들을 선택하세요:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.existingValues.map((value) {
                      final isSelected = _sortOrder.contains(value);
                      return FilterChip(
                        label: Text(value),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected && !_sortOrder.contains(value)) {
                              _sortOrder.add(value);
                            } else if (!selected) {
                              _sortOrder.remove(value);
                            }
                          });
                        },
                        selectedColor: const Color(0xFFFF8A65).withAlpha(76),
                        checkmarkColor: const Color(0xFFFF8A65),
                        backgroundColor: Colors.grey[100],
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFFFF8A65)
                              : Colors.grey[700],
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _sortOrder.isEmpty
                  ? const Center(
                      child: Text(
                        '위에서 항목들을 선택하여 순서를 정하세요',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: _sortOrder.length,
                      onReorder: _reorderItems,
                      itemBuilder: (context, index) {
                        return ReorderableDragStartListener(
                          key: ValueKey(_sortOrder[index]),
                          index: index,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF8A65),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                _sortOrder[index],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.drag_handle,
                                      color: Color(0xFFFF8A65), size: 24),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _removeItem(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.close,
                                          color: Colors.red[400], size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onOrderSet(_sortOrder);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8A65),
            foregroundColor: Colors.white,
          ),
          child: const Text('적용'),
        ),
      ],
    );
  }

  void _removeItem(int index) {
    setState(() {
      _sortOrder.removeAt(index);
    });
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _sortOrder.removeAt(oldIndex);
      _sortOrder.insert(newIndex, item);
    });
  }
}
