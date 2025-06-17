// lib/providers/general_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_note/core/navigation/app_router.dart'; // 경로 확인

final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter(ref).router;
});
