import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_note/core/widgets/loading_indicator.dart';
import 'package:house_note/features/my_page/viewmodels/my_page_viewmodel.dart';
import 'package:house_note/providers/user_providers.dart'; // userModelProvider
import 'package:house_note/features/onboarding/views/interactive_guide_overlay.dart';
import 'dart:io';

class MyPageScreen extends ConsumerStatefulWidget {
  static const routeName = 'my-page';
  static const routePath = '/my-page';

  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  // 가이드용 GlobalKey들
  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _editKey = GlobalKey();
  final GlobalKey _priorityKey = GlobalKey();
  final GlobalKey _guideKey = GlobalKey();
  final GlobalKey _logoutKey = GlobalKey();

  void _showInteractiveGuide() {
    final steps = [
      GuideStep(
        title: '프로필 정보',
        description: '내 프로필 사진과 기본 정보 확인 가능',
        targetKey: _profileKey,
        icon: Icons.person,
        tooltipPosition: GuideTooltipPosition.bottom,
      ),
      GuideStep(
        title: '프로필 편집',
        description: '프로필 사진과 닉네임 수정 가능',
        targetKey: _editKey,
        icon: Icons.edit,
        tooltipPosition: GuideTooltipPosition.bottom,
      ),
      GuideStep(
        title: '우선순위 설정',
        description: '중요한 항목의 우선순위 설정 가능',
        targetKey: _priorityKey,
        icon: Icons.tune,
        tooltipPosition: GuideTooltipPosition.bottom,
      ),
      GuideStep(
        title: '사용법 가이드',
        description: '자세한 사용법과 튜토리얼 확인 가능',
        targetKey: _guideKey,
        icon: Icons.help_outline,
        tooltipPosition: GuideTooltipPosition.bottom,
      ),
      GuideStep(
        title: '로그아웃',
        description: '로그아웃 및 다른 계정 로그인 가능',
        targetKey: _logoutKey,
        icon: Icons.logout,
        tooltipPosition: GuideTooltipPosition.top,
      ),
    ];

    InteractiveGuideManager.showGuide(
      context,
      steps: steps,
      onCompleted: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('마이페이지 가이드가 완료되었습니다!'),
            backgroundColor: Color(0xFFFF8A65),
          ),
        );
      },
      onSkipped: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('가이드를 건너뛰었습니다.'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => _showInteractiveGuide(),
          ),
        ],
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
                    key: _profileKey,
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
                              ? ClipOval(
                                  child:
                                      _buildProfileImageWidget(user!.photoURL!),
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '이메일 정보 없음',
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 편집 버튼
                        Container(
                          key: _editKey,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.push('/profile-settings');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            label: const Text(
                              '편집',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
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
                            key: _priorityKey,
                            icon: Icons.tune,
                            title: '우선순위 설정',
                            onTap: () {
                              context.push('/priority-settings');
                            },
                          ),
                          const Divider(height: 1),
                          _buildMenuItem(
                            key: _guideKey,
                            icon: Icons.help_outline,
                            title: '사용법 가이드',
                            onTap: () {
                              context.push('/user-guide');
                            },
                          ),
                          const Divider(height: 1),
                          _buildMenuItem(
                            key: _logoutKey,
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
    Key? key,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      key: key,
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

  Widget _buildProfileImageWidget(String photoURL) {
    // 로컬 파일 경로인지 URL인지 확인
    if (photoURL.startsWith('http')) {
      // 네트워크 이미지
      return Image.network(
        photoURL,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 40, color: Colors.grey);
        },
      );
    } else {
      // 로컬 파일
      return Image.file(
        File(photoURL),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 40, color: Colors.grey);
        },
      );
    }
  }
}
