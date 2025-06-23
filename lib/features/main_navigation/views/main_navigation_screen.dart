import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_note/features/card_list/views/card_list_screen.dart';
import 'package:house_note/features/chart/views/chart_screen.dart';
import 'package:house_note/features/map/views/map_screen.dart';
import 'package:house_note/features/my_page/views/my_page_screen.dart';
// import 'package:house_note/features/main_navigation/viewmodels/main_navigation_viewmodel.dart'; // ViewModel 필요시

// 현재 선택된 탭 인덱스를 관리하는 간단한 Provider (StateProvider)
final selectedPageIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigationScreen extends ConsumerStatefulWidget {
  final Widget child; // ShellRoute의 자식 라우트 (현재 탭의 화면)

  const MainNavigationScreen({required this.child, super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  // 각 탭에 해당하는 경로
  static const List<String> _tabPaths = [
    CardListScreen.routePath,
    ChartScreen.routePath,
    MapScreen.routePath,
    MyPageScreen.routePath,
  ];

  void _onItemTapped(int index, BuildContext context, WidgetRef ref) {
    ref.read(selectedPageIndexProvider.notifier).state = index;
    context.go(_tabPaths[index]);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedPageIndexProvider);

    return Scaffold(
      body: widget.child, // 현재 선택된 탭의 화면이 여기에 표시됨
      bottomNavigationBar: Container(
        key: CardListScreen.bottomNavKey,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(index, context, ref),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFFF8A65),
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(
            fontSize: 0,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
          elevation: 0,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.format_list_bulleted, size: 33),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.bar_chart, size: 33),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.location_on_outlined, size: 33),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline, size: 33),
              ),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
