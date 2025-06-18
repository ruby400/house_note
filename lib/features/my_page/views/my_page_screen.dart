import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_note/core/widgets/loading_indicator.dart';
import 'package:house_note/features/my_page/viewmodels/my_page_viewmodel.dart';
import 'package:house_note/providers/user_providers.dart'; // userModelProvider

class MyPageScreen extends ConsumerWidget {
  static const routeName = 'my-page';
  static const routePath = '/my-page';

  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userModelAsyncValue = ref.watch(userModelProvider);
    final myPageViewModel = ref.watch(myPageViewModelProvider);
    final myPageNotifier = ref.read(myPageViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '마이페이지',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF9575), // 좋은 중간조 주황색 (왼쪽 위)
                Color(0xFFFF8A65), // 메인 주황색 (중간)
                Color(0xFFFF8064), // 따뜻한 주황색 (오른쪽 아래)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
      body: userModelAsyncValue.when(
        data: (user) {
          if (user == null && !myPageViewModel.isLoggingOut) {
            return const Center(child: Text('사용자 정보를 불러올 수 없습니다.'));
          }
          return Stack(
            children: [
              Column(
                children: [
                  // 프로필 카드
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 251, 232, 226),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // 프로필 이미지
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF8A65),
                              width: 3,
                            ),
                            color: Colors.white,
                          ),
                          child: user?.photoURL != null
                              ? CircleAvatar(
                                  radius: 36,
                                  backgroundImage:
                                      NetworkImage(user!.photoURL!),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                        ),
                        const SizedBox(width: 16),
                        // 사용자 정보
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? '닉네임 없음',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '이메일 정보 없음',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 편집 버튼
                        TextButton(
                          onPressed: () {
                            context.push('/profile-settings');
                          },
                          child: const Text(
                            '편집',
                            style: TextStyle(
                              color: Color(0xFFFF8A65),
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 메뉴 리스트
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            icon: Icons.tune,
                            title: '우선순위 설정',
                            onTap: () {
                              context.push('/priority-settings');
                            },
                          ),
                          const Divider(height: 1),
                          _buildMenuItem(
                            icon: Icons.logout,
                            title: '로그인 / 로그아웃',
                            onTap: () async {
                              await myPageNotifier.signOut();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (myPageViewModel.isLoggingOut)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const LoadingIndicator(),
                  ),
                ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (err, stack) => Center(child: Text('오류 발생: $err')),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.grey[600],
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
