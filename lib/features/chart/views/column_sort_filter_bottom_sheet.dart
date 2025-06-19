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

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController(text: widget.columnName);
  }

  @override
  void dispose() {
    _renameController.dispose();
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
              Text(
                '${widget.columnName} 정렬 순서 정하기',
                style: const TextStyle(
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
          // 순서 직접 설정 및 초기화 버튼 (위치 변경)
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8A65).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showCustomSortOrderDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.tune, size: 20),
                    label: const Text(
                      '순서 직접 설정',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onResetOrder();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    side: BorderSide(color: Colors.grey[400]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('순서 초기화'),
                ),
              ),
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: Text(_getSortLabel(false)),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _renameController,
            decoration: InputDecoration(
              labelText: '컬럼 이름',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8A65),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sort, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${widget.columnName} 정렬 순서',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 내용
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFCC80),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        '선호하는 순서대로 드래그해서 배치하세요',
                        style: TextStyle(
                          color: Color(0xFFE65100),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.existingValues.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          '정렬할 항목들을 선택하세요:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
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
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _sortOrder.isEmpty
                            ? const Center(
                                child: Text(
                                  '위에서 항목들을 선택하여 순서를 정하세요',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ReorderableListView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                onReorder: (oldIndex, newIndex) {
                                  setState(() {
                                    if (newIndex > oldIndex) {
                                      newIndex -= 1;
                                    }
                                    final item = _sortOrder.removeAt(oldIndex);
                                    _sortOrder.insert(newIndex, item);
                                  });
                                },
                                children: _sortOrder.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  String item = entry.value;
                                  
                                  return Container(
                                    key: ValueKey(item),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Dismissible(
                                      key: ValueKey('dismissible_$item'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.red[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.delete, color: Colors.red[400]),
                                      ),
                                      onDismissed: (direction) {
                                        _removeItem(index);
                                      },
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
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          item,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              margin: const EdgeInsets.only(right: 12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.drag_handle,
                                                color: Colors.grey[600],
                                                size: 24,
                                              ),
                                            ),
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
                                }).toList(),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 버튼들
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[400]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onOrderSet(_sortOrder);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A65),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '적용',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _sortOrder.removeAt(index);
    });
  }
}
