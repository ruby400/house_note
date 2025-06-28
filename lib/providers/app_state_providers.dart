import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 첫 실행 여부를 관리하는 간단한 프로바이더
final firstLaunchProvider = StateNotifierProvider<FirstLaunchNotifier, bool>((ref) {
  return FirstLaunchNotifier();
});

class FirstLaunchNotifier extends StateNotifier<bool> {
  FirstLaunchNotifier() : super(true) {
    // 비동기 초기화는 별도로 수행
    _checkFirstLaunch();
  }

  static const String _firstLaunchKey = 'first_launch';

  Future<void> _checkFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasLaunchedBefore = prefs.getBool(_firstLaunchKey) ?? false;
      state = !hasLaunchedBefore; // 이전에 실행한 적이 없으면 첫 실행
    } catch (e) {
      // 오류 시 첫 실행으로 간주
      state = true;
    }
  }

  Future<void> markAsNotFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstLaunchKey, true); // 실행한 적이 있다고 표시
      state = false;
    } catch (e) {
      // 오류 시에도 상태는 업데이트
      state = false;
    }
  }
}