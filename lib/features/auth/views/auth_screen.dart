import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_note/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:house_note/features/auth/views/signup_screen.dart';
import 'package:house_note/providers/auth_providers.dart';
import 'package:house_note/core/widgets/loading_indicator.dart';
import 'package:house_note/core/utils/logger.dart';
import 'package:house_note/core/utils/app_info.dart';
import 'package:house_note/features/onboarding/views/interactive_guide_overlay.dart';

class AuthScreen extends ConsumerStatefulWidget {
  static const routeName = 'auth';
  static const routePath = '/auth';

  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 튜토리얼 관련 GlobalKey들
  final GlobalKey _emailFieldKey = GlobalKey();
  final GlobalKey _passwordFieldKey = GlobalKey();
  final GlobalKey _loginButtonKey = GlobalKey();
  final GlobalKey _googleButtonKey = GlobalKey();
  final GlobalKey _naverButtonKey = GlobalKey();
  final GlobalKey _switchModeKey = GlobalKey();
  final GlobalKey _helpButtonKey = GlobalKey();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final viewModel = ref.read(authViewModelProvider.notifier);

      AppLogger.d('🔄 로그인 시작: $email');

      final success = await viewModel.signInWithEmail(email, password);

      AppLogger.d('🏁 로그인 결과: ${success ? "성공" : "실패"}');

      if (success && mounted) {
        // 로그인 성공 후 리다이렉트는 GoRouter의 redirect 로직에 의해 처리됨
      }
    }
  }

  Future<void> _googleSignIn() async {
    final viewModel = ref.read(authViewModelProvider.notifier);
    bool success = await viewModel.signInWithGoogle();
    if (success && mounted) {
      // 구글 로그인 성공 후 처리 (GoRouter redirect에 의해 처리될 수 있음)
      // 예시: context.go(PrioritySettingScreen.routePath);
    }
  }

  Future<void> _naverSignIn() async {
    final viewModel = ref.read(authViewModelProvider.notifier);
    bool success = await viewModel.signInWithNaver();
    if (success && mounted) {
      // 네이버 로그인 성공 후 처리 (GoRouter redirect에 의해 처리될 수 있음)
      // 예시: context.go(PrioritySettingScreen.routePath);
    }
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final authError = authState.error;

    // 로그인 성공 시 GoRouter의 redirect 로직이 처리
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.user != null && !next.isLoading) {
        // authStateChangesProvider에 의해 GoRouter가 redirect를 처리하므로,
        // 명시적인 context.go()는 중복될 수 있습니다.
        // 다만, 특정 조건에 따라 다른 화면으로 보내고 싶다면 여기서 처리 가능.
        // 예: 신규 유저면 온보딩, 기존 유저면 메인
        // 현재는 GoRouter redirect 로직에서 온보딩 여부까지 판단합니다.
        // context.go(PrioritySettingScreen.routePath);
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '로그인',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFF8A65),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            key: _helpButtonKey,
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _showInteractiveGuide,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // 앱 아이콘
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pets,
                    size: 40,
                    color: Color(0xFFFF8A65),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '환영합니다!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '하노와 함께 완벽한 집을 찾아보세요',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  key: _emailFieldKey,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@')) {
                        return '유효한 이메일을 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  key: _passwordFieldKey,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return '비밀번호는 6자 이상이어야 합니다.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                if (authState.isLoading)
                  const LoadingIndicator()
                else
                  SizedBox(
                    key: _loginButtonKey,
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A65),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _submit,
                      child: const Text(
                        '로그인',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    TextButton(
                      key: _switchModeKey,
                      onPressed: () {
                        context.push(SignupScreen.routePath);
                      },
                      child: const Text('계정이 없으신가요? 회원가입'),
                    ),
                    TextButton(
                      onPressed: _showPasswordResetDialog,
                      child: const Text(
                        '비밀번호를 잊으셨나요?',
                        style: TextStyle(
                          color: Color(0xFFFF8A65),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Row(
                  children: <Widget>[
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("OR"),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                authState.isLoading
                    ? const SizedBox.shrink() // 로딩 중에는 소셜 로그인 버튼 숨김
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google 로그인 버튼
                          GestureDetector(
                            key: _googleButtonKey,
                            onTap: _googleSignIn,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Image.network(
                                  'https://developers.google.com/identity/images/g-logo.png',
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.g_mobiledata,
                                      size: 28,
                                      color: Color(0xFF4285F4),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Naver 로그인 버튼
                          GestureDetector(
                            key: _naverButtonKey,
                            onTap: _naverSignIn,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF03C75A),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'N',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Arial',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                if (authError != null && !authState.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        authError,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
                const SizedBox(height: 20),
                // 앱 버전 정보
                Text(
                  '${AppInfo.appName} ${AppInfo.fullVersion}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPasswordResetDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 아이콘
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A65).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    size: 40,
                    color: Color(0xFFFF8A65),
                  ),
                ),
                const SizedBox(height: 24),

                // 제목
                const Text(
                  '비밀번호 재설정',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // 설명
                const Text(
                  '가입하신 이메일 주소를 입력하시면\n비밀번호 재설정 링크를 보내드립니다.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // 이메일 입력 필드
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: emailController,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: '이메일',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      hintText: '예: example@email.com',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(
                        Icons.email,
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
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 32),

                // 버튼들
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8A65)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            final email = emailController.text.trim();
                            if (email.isEmpty || !email.contains('@')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('유효한 이메일 주소를 입력해주세요.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final navigator = Navigator.of(context);
                            final scaffoldMessenger =
                                ScaffoldMessenger.of(context);

                            navigator.pop();

                            final viewModel =
                                ref.read(authViewModelProvider.notifier);
                            final success =
                                await viewModel.sendPasswordResetEmail(email);

                            if (!mounted) return;

                            if (success) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('$email로 비밀번호 재설정 링크를 보냈습니다.'),
                                  backgroundColor: const Color(0xFFFF8A65),
                                ),
                              );
                            } else {
                              // 에러는 AuthViewModel에서 이미 처리됨
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '전송',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInteractiveGuide() {
    final steps = [
      GuideStep(
        title: '하우스노트에 오신걸 환영합니다!',
        description: '이 화면에서 계정에 로그인하거나 새 계정을 만들 수 있습니다.',
        targetKey: _helpButtonKey,
        tooltipPosition: GuideTooltipPosition.left,
        icon: Icons.waving_hand,
      ),
      GuideStep(
        title: '이메일 입력',
        description: '가입할 이메일 주소를 입력해주세요. 유효한 이메일 형식이어야 합니다.',
        targetKey: _emailFieldKey,
        tooltipPosition: GuideTooltipPosition.bottom,
        icon: Icons.email,
      ),
      GuideStep(
        title: '비밀번호 입력',
        description: '비밀번호는 6자 이상이어야 합니다. 안전한 비밀번호를 사용하세요.',
        targetKey: _passwordFieldKey,
        tooltipPosition: GuideTooltipPosition.bottom,
        icon: Icons.lock,
      ),
      GuideStep(
        title: '로그인/회원가입',
        description: '정보를 입력한 후 이 버튼을 눌러 로그인하거나 회원가입하세요.',
        targetKey: _loginButtonKey,
        tooltipPosition: GuideTooltipPosition.top,
        icon: Icons.login,
      ),
      GuideStep(
        title: '회원가입 링크',
        description: '아직 계정이 없다면 여기를 눌러 회원가입 화면으로 이동하세요.',
        targetKey: _switchModeKey,
        tooltipPosition: GuideTooltipPosition.top,
        icon: Icons.person_add,
      ),
      GuideStep(
        title: 'Google 로그인',
        description: 'Google 계정으로도 간편하게 로그인할 수 있습니다.',
        targetKey: _googleButtonKey,
        tooltipPosition: GuideTooltipPosition.top,
        icon: Icons.g_mobiledata,
      ),
      GuideStep(
        title: '네이버 로그인',
        description: '네이버 계정으로도 간편하게 로그인할 수 있습니다.',
        targetKey: _naverButtonKey,
        tooltipPosition: GuideTooltipPosition.top,
        icon: Icons.account_circle,
      ),
    ];

    InteractiveGuideManager.showGuide(
      context,
      steps: steps,
      onCompleted: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인 가이드를 완료했습니다!'),
            backgroundColor: Color(0xFFFF8A65),
          ),
        );
      },
      onSkipped: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('튜토리얼을 건너뛰었습니다.')),
        );
      },
    );
  }
}
