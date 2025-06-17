import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_note/core/widgets/loading_indicator.dart';
import 'package:house_note/features/onboarding/viewmodels/priority_setting_viewmodel.dart';

class PrioritySettingsPage extends ConsumerStatefulWidget {
  static const routeName = 'priority-settings-page';
  static const routePath = '/priority-settings';
  const PrioritySettingsPage({super.key});

  @override
  ConsumerState<PrioritySettingsPage> createState() =>
      _PrioritySettingsPageState();
}

class _PrioritySettingsPageState extends ConsumerState<PrioritySettingsPage> {
  final Map<String, String> _prioritySelections = {
    '수도 수납': '보통',
    '공광비': '보통',
    '재산/방화': '보통',
    '소음': '보통',
    '월세/보증금': '보통',
    '편의점': '보통',
  };


  void _updatePriority(String priority, String level) {
    setState(() => _prioritySelections[priority] = level);
  }

  void _removePriority(String priority) {
    setState(() => _prioritySelections.remove(priority));
  }

  Future<void> _savePriorities() async {
    final notifier = ref.read(prioritySettingViewModelProvider.notifier);
    final priorities =
        _prioritySelections.entries.map((e) => '${e.key}: ${e.value}').toList();
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = GoRouter.of(context);

    final error = await notifier.savePriorities(priorities);

    if (!mounted) return;

    if (error == null) {
      scaffoldMessenger
          .showSnackBar(const SnackBar(
            content: Text('우선순위가 저장되었습니다'),
            duration: Duration(milliseconds: 800),
          ));
      navigator.pop();
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('오류: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(milliseconds: 800)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(prioritySettingViewModelProvider);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
          title: const Text('우선순위 설정',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFFF8A65),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop())),
      body: viewModel.isLoading
          ? const LoadingIndicator()
          : Column(children: [
              _buildHeader(),
              Expanded(child: _buildPriorityList()),
              _buildActionButtons(),
            ]),
    );
  }

  Widget _buildHeader() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: const Column(children: [
          CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Icon(Icons.pets, size: 40, color: Color(0xFFFF8A65))),
          SizedBox(height: 20),
          Text('우선순위를 수정해주세요',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
              textAlign: TextAlign.center),
          SizedBox(height: 8),
          Text('변경된 설정이 즉시 적용됩니다.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center),
        ]),
      );

  Widget _buildPriorityList() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          itemCount: _prioritySelections.length,
          itemBuilder: (context, index) {
            final priority = _prioritySelections.keys.elementAt(index);
            final selectedLevel = _prioritySelections[priority]!;
            return Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ]),
              child: Row(children: [
                Expanded(
                    child: Text(priority,
                        style: const TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.w500))),
                Row(children: [
                  _buildPriorityButton('낮음', selectedLevel == '낮음',
                      () => _updatePriority(priority, '낮음')),
                  const SizedBox(width: 8),
                  _buildPriorityButton('보통', selectedLevel == '보통',
                      () => _updatePriority(priority, '보통')),
                  const SizedBox(width: 8),
                  _buildPriorityButton('높음', selectedLevel == '높음',
                      () => _updatePriority(priority, '높음')),
                ]),
                if (!['수도 수납', '공광비', '재산/방화', '소음', '월세/보증금', '편의점']
                    .contains(priority))
                  IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removePriority(priority)),
              ]),
            );
          },
        ),
      );

  Widget _buildActionButtons() => Container(
        margin: const EdgeInsets.all(16.0),
        child: Column(children: [
          SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF8A65),
                      side: const BorderSide(color: Color(0xFFFF8A65)),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () {},
                  child: const Text('+ 항목 추가',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)))),
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A65),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  onPressed: _savePriorities,
                  child: const Text('저장',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)))),
        ]),
      );

  Widget _buildPriorityButton(
          String label, bool isSelected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFCDD2) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF8A65)
                      : Colors.grey[300]!)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color:
                      isSelected ? const Color(0xFFFF8A65) : Colors.grey[600],
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal)),
        ),
      );
}
