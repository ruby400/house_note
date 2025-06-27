import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/features/auth/views/auth_screen.dart';
import 'package:house_note/features/card_list/views/card_detail_screen.dart';
import 'package:house_note/features/card_list/views/card_list_screen.dart';
import 'package:house_note/features/card_list/views/property_detail_screen.dart';
import 'package:house_note/features/chart/views/chart_screen.dart';
// import 'package:house_note/features/chart/views/column_sort_filter_bottom_sheet.dart'; // 라우터에서 사용되지 않으므로 제거
import 'package:house_note/features/chart/views/filtering_chart_screen.dart';
import 'package:house_note/features/main_navigation/views/main_navigation_screen.dart';
import 'package:house_note/features/map/views/map_screen.dart';
import 'package:house_note/features/my_page/views/my_page_screen.dart';
import 'package:house_note/features/my_page/views/priority_settings_page.dart';
import 'package:house_note/features/my_page/views/profile_settings_screen.dart';
import 'package:house_note/features/my_page/views/user_guide_screen.dart';
import 'package:house_note/features/onboarding/views/interactive_tutorial_screen.dart';
import 'package:house_note/features/onboarding/views/priority_setting_screen.dart';
import 'package:house_note/features/onboarding/views/profile_setting_screen.dart';
import 'package:house_note/features/splash/views/splash_screen.dart';
import 'package:house_note/providers/auth_providers.dart';
import 'package:house_note/providers/user_providers.dart';
import 'package:house_note/data/models/property_chart_model.dart';

// 앱의 라우팅 로직을 담당하는 클래스
class AppRouter {
  final Ref _ref;

  AppRouter(this._ref);

  late final GoRouter router = GoRouter(
    initialLocation: SplashScreen.routePath,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(_ref),
    routes: <RouteBase>[
      // 스플래시, 인증, 온보딩 등 메인 탭 외의 화면들
      GoRoute(
        path: SplashScreen.routePath,
        name: SplashScreen.routeName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AuthScreen.routePath,
        name: AuthScreen.routeName,
        builder: (context, state) => const AuthScreen(),
      ),
      // 온보딩 - 프로필 설정
      GoRoute(
        path: ProfileSettingScreen.routePath, // /onboarding/profile
        name: ProfileSettingScreen.routeName,
        builder: (context, state) => const ProfileSettingScreen(),
      ),
      // 온보딩 - 인터렉티브 튜토리얼
      GoRoute(
        path: InteractiveTutorialScreen.routePath,
        name: InteractiveTutorialScreen.routeName,
        builder: (context, state) => const InteractiveTutorialScreen(),
      ),
      // 온보딩 - 우선순위 설정
      GoRoute(
        path: PrioritySettingScreen.routePath, // /onboarding/priority
        name: PrioritySettingScreen.routeName,
        builder: (context, state) => const PrioritySettingScreen(),
      ),
      // 마이페이지 - 우선순위 편집
      GoRoute(
        path: PrioritySettingsPage.routePath,
        name: PrioritySettingsPage.routeName,
        builder: (context, state) => const PrioritySettingsPage(),
      ),
      // 마이페이지 - 프로필 설정
      GoRoute(
        path: ProfileSettingsScreen.routePath,
        name: ProfileSettingsScreen.routeName,
        builder: (context, state) => const ProfileSettingsScreen(),
      ),
      // 사용법 가이드
      GoRoute(
        path: UserGuideScreen.routePath,
        name: UserGuideScreen.routeName,
        builder: (context, state) => const UserGuideScreen(),
      ),

      // 메인 탭들을 위한 ShellRoute
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainNavigationScreen(child: child);
        },
        routes: [
          // 카드 목록 탭
          GoRoute(
              path: CardListScreen.routePath, // /cards
              name: CardListScreen.routeName,
              pageBuilder: (context, state) => const NoTransitionPage(
                    child: CardListScreen(),
                  ),
              routes: [
                GoRoute(
                  path: CardDetailScreen.routePath, // :cardId
                  name: CardDetailScreen.routeName,
                  builder: (context, state) {
                    final cardId = state.pathParameters['cardId']!;
                    final extra = state.extra;
                    
                    // Map 형태로 전달된 경우 (새 카드 생성 플로우)
                    if (extra is Map<String, dynamic>) {
                      final propertyData = extra['property'] as PropertyData?;
                      final chartId = extra['chartId'] as String?;
                      final isNewProperty = extra['isNewProperty'] as bool? ?? false;
                      
                      return CardDetailScreen(
                        cardId: cardId, 
                        propertyData: propertyData,
                        chartId: chartId,
                        isNewProperty: isNewProperty,
                      );
                    }
                    // PropertyData가 extra로 전달되었는지 확인
                    else if (extra is PropertyData) {
                      return CardDetailScreen(cardId: cardId, propertyData: extra);
                    } else {
                      // PropertyData가 없으면 cardId만으로 생성
                      return CardDetailScreen(cardId: cardId);
                    }
                  },
                ),
                GoRoute(
                  path: 'property-detail', // /cards/property-detail
                  name: PropertyDetailScreen.routeName,
                  builder: (context, state) {
                    final extra = state.extra;

                    // PropertyData 타입인지 확인합니다.
                    if (extra is PropertyData) {
                      // 타입이 올바르다면 화면에 데이터를 전달합니다.
                      return PropertyDetailScreen(propertyData: extra);
                    } else {
                      // 데이터가 없거나 타입이 올바르지 않으면 에러 화면을 표시합니다.
                      return const Scaffold(
                        body: Center(
                          child: Text('오류: 부동산 정보를 불러올 수 없습니다.'),
                        ),
                      );
                    }
                  },
                ),
              ]),
          // 차트 탭
          GoRoute(
            path: ChartScreen.routePath, // /charts
            name: ChartScreen.routeName,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChartScreen(),
            ),
            routes: [
              GoRoute(
                path: ':chartId', // 예: 123
                name: 'filtering-chart', // 이름은 그대로 유지
                builder: (context, state) {
                  final chartId = state.pathParameters['chartId']!;
                  // [수정된 부분] 클래스 생성자를 올바르게 호출
                  return FilteringChartScreen(chartId: chartId);
                },
              ),
            ],
          ),
          // 지도 탭
          GoRoute(
            path: MapScreen.routePath, // /map
            name: MapScreen.routeName,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MapScreen(),
            ),
          ),
          // 마이페이지 탭
          GoRoute(
            path: MyPageScreen.routePath, // /my-page
            name: MyPageScreen.routeName,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MyPageScreen(),
            ),
          ),
        ],
      ),
    ],
    // 리다이렉트 로직
    redirect: (BuildContext context, GoRouterState state) {
      if (state.matchedLocation == SplashScreen.routePath) return null;

      final isAuthenticated = _ref.read(authStateChangesProvider).value != null;
      final userModel = _ref.read(userModelProvider).value;
      final onboardingCompleted = userModel?.onboardingCompleted ?? false;

      final isLoggingIn = state.matchedLocation == AuthScreen.routePath;
      final isOnboardingFlow = state.matchedLocation.startsWith('/onboarding');

      if (!isAuthenticated) {
        return isLoggingIn ? null : AuthScreen.routePath;
      }

      // 로그인 되어 있는 경우
      if (onboardingCompleted) {
        // 온보딩 완료 시: 로그인/온보딩 화면에 있다면 메인으로
        if (isLoggingIn || isOnboardingFlow) {
          return CardListScreen.routePath;
        }
      } else {
        // 온보딩 미완료 시: 온보딩 플로우에 있는게 아니라면 튜토리얼로
        if (!isOnboardingFlow) {
          return InteractiveTutorialScreen.routePath;
        }
      }

      return null;
    },
  );

  static final _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'Shell');
}

// GoRouter의 상태 변화를 감지하는 클래스
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    _authSubscription =
        ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
    _userSubscription =
        ref.listen(userModelProvider, (_, __) => notifyListeners());
  }

  late final ProviderSubscription _authSubscription;
  late final ProviderSubscription _userSubscription;

  @override
  void dispose() {
    _authSubscription.close();
    _userSubscription.close();
    super.dispose();
  }
}
