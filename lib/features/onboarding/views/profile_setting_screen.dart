import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_note/core/utils/logger.dart';
import 'package:house_note/core/widgets/loading_indicator.dart';
import 'package:house_note/features/card_list/views/card_list_screen.dart';
import 'package:house_note/features/onboarding/viewmodels/profile_setting_viewmodel.dart';

class ProfileSettingScreen extends ConsumerStatefulWidget {
  static const routeName = 'profile-setting';
  static const routePath = '/onboarding/profile';
  const ProfileSettingScreen({super.key});

  @override
  ConsumerState<ProfileSettingScreen> createState() =>
      _ProfileSettingScreenState();
}

class _ProfileSettingScreenState extends ConsumerState<ProfileSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppLogger.warning('폼 검증 실패');
      return;
    }

    final notifier = ref.read(profileSettingViewModelProvider.notifier);
    final nickname = _displayNameController.text.trim();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = GoRouter.of(context);

    final error = await notifier.saveProfile(nickname);

    if (!mounted) return;

    if (error == null) {
      AppLogger.info('프로필 저장 성공, 메인 화면으로 이동');
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('프로필이 설정되었습니다!'),
          duration: Duration(milliseconds: 800),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      navigator.go(CardListScreen.routePath);
    } else {
      AppLogger.error('프로필 저장 실패: $error');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('오류: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileSettingViewModelProvider);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '프로필 설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFF8A65),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // 환영 아이콘
              Container(
                height: 120,
                width: 120,
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A65).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add,
                  size: 60,
                  color: Color(0xFFFF8A65),
                ),
              ),
              Text(
                '안녕하세요! 👋',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF8A65),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '사용하실 닉네임을 입력해주세요',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // 닉네임 입력 필드
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _displayNameController,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: '닉네임',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    hintText: '예: 홍길동',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Color(0xFFFF8A65),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF8A65),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '닉네임을 입력해주세요.';
                    }
                    if (value.trim().length < 2) {
                      return '닉네임은 2자 이상 입력해주세요.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 30),
              profileState.isLoading
                  ? const LoadingIndicator()
                  : Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8A65).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _submitProfile,
                        child: const Text(
                          '완료하고 시작하기',
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
      ),
    );
  }
}
