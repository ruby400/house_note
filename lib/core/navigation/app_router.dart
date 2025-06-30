import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/features/auth/views/auth_screen.dart';
import 'package:house_note/features/auth/views/signup_screen.dart';
import 'package:house_note/features/card_list/views/card_detail_screen.dart';
import 'package:house_note/features/card_list/views/card_list_screen.dart';
import 'package:house_note/features/card_list/views/property_detail_screen.dart';
import 'package:house_note/features/chart/views/chart_screen.dart';
// import 'package:house_note/features/chart/views/column_sort_filter_bottom_sheet.dart'; // 라우터에서 사용되지 않으므로 제거
import 'package:house_note/features/chart/views/filtering_chart_screen.dart';
import 'package:house_note/features/main_navigation/views/main_navigation_screen.dart';
import 'package:house_note/features/map/views/map_screen.dart';
import 'package:house_note/features/my_page/views/my_page_screen.dart';
import 'package:house_note/features/my_page/views/profile_settings_screen.dart';
import 'package:house_note/features/my_page/views/user_guide_screen.dart';
import 'package:house_note/features/splash/views/splash_screen.dart';
import 'package:house_note/providers/auth_providers.dart';
import 'package:house_note/data/models/property_chart_model.dart';

// 전역 Navigator Key (한 번만 생성되도록 보장)
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'Shell');

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
      GoRoute(
        path: SignupScreen.routePath,
        name: SignupScreen.routeName,
        builder: (context, state) => const SignupScreen(),
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
    // 리다이렉트 로직 - 로그인 없이도 앱 둘러보기 허용
    redirect: (BuildContext context, GoRouterState state) {
      if (state.matchedLocation == SplashScreen.routePath) return null;

      final isAuthenticated = _ref.read(authStateChangesProvider).value != null;

      final isOnboardingFlow = state.matchedLocation.startsWith('/onboarding');

      // 로그인된 사용자의 경우
      if (isAuthenticated) {
        // 회원가입 화면에서는 리다이렉트하지 않음 (회원가입 후 로그아웃 처리를 위해)
        if (state.matchedLocation == SignupScreen.routePath) {
          return null;
        }
        // 로그인 화면에 있다면 카드목록으로 이동
        if (state.matchedLocation == AuthScreen.routePath) {
          return CardListScreen.routePath;
        }
        // 온보딩 화면에 있다면 메인으로
        if (isOnboardingFlow) {
          return CardListScreen.routePath;
        }
      }

      // 로그인하지 않은 사용자는 자유롭게 앱을 둘러볼 수 있음
      // 단, 온보딩 화면에는 접근 불가
      if (!isAuthenticated && isOnboardingFlow) {
        return CardListScreen.routePath;
      }

      return null;
    },
  );

}

// GoRouter의 상태 변화를 감지하는 클래스
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    _authSubscription =
        ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
  }

  late final ProviderSubscription _authSubscription;

  @override
  void dispose() {
    _authSubscription.close();
    super.dispose();
  }
}
