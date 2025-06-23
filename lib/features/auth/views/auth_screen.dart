import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:house_note/providers/auth_providers.dart';
import 'package:house_note/core/widgets/loading_indicator.dart';
import 'package:house_note/core/utils/logger.dart';
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
  bool _isLogin = true; // true면 로그인, false면 회원가입
  bool _isTermsAgreed = false; // 약관동의 체크 상태

  // 튜토리얼 관련 GlobalKey들
  final GlobalKey _emailFieldKey = GlobalKey();
  final GlobalKey _passwordFieldKey = GlobalKey();
  final GlobalKey _loginButtonKey = GlobalKey();
  final GlobalKey _googleButtonKey = GlobalKey();
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
      // 회원가입일 때 약관동의 확인
      if (!_isLogin && !_isTermsAgreed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('약관에 동의해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final viewModel = ref.read(authViewModelProvider.notifier);

      AppLogger.d('🔄 인증 시작: ${_isLogin ? "로그인" : "회원가입"} - $email'); // 디버깅용

      bool success = false;
      if (_isLogin) {
        success = await viewModel.signInWithEmail(email, password);
      } else {
        success = await viewModel.signUpWithEmail(email, password);
        if (success) {
          // 회원가입 성공 시 바로 온보딩으로 (또는 로그인 후 온보딩)
          // 이 부분은 앱의 정책에 따라 결정
        }
      }

      AppLogger.d('🏁 인증 결과: ${success ? "성공" : "실패"}'); // 디버깅용

      if (success && mounted) {
        // 로그인/회원가입 성공 후 리다이렉트는 GoRouter의 redirect 로직에 의해 처리되거나,
        // 여기서 명시적으로 다음 화면으로 보낼 수 있습니다.
        // 일반적으로 authStateChanges를 listen하는 GoRouter redirect가 더 적합합니다.
        // 예시: context.go(PrioritySettingScreen.routePath);
        // 또는, authStateChangesProvider를 통해 GoRouter가 자동으로 리다이렉트할 것이므로 별도 호출 불필요
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

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('서비스 이용약관'),
          content: const SingleChildScrollView(
            child: Text(
              '''제1조 (목적)
이 약관은 하우스노트 서비스(이하 "서비스")의 이용과 관련하여 회사와 이용자의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (정의)
1. "서비스"란 하우스노트가 제공하는 부동산 정보 서비스를 의미합니다.
2. "이용자"란 이 약관에 따라 서비스를 이용하는 회원을 말합니다.

제3조 (약관의 효력 및 변경)
1. 이 약관은 서비스를 이용하고자 하는 모든 이용자에 대하여 그 효력을 발생합니다.
2. 회사는 합리적인 사유가 발생할 경우 이 약관을 변경할 수 있습니다.

제4조 (서비스의 제공 및 변경)
1. 회사는 다음과 같은 서비스를 제공합니다:
   - 부동산 정보 제공
   - 매물 비교 및 분석
   - 기타 부동산 관련 서비스

제5조 (개인정보 보호)
회사는 이용자의 개인정보를 관련 법령에 따라 보호합니다.

제6조 (이용자의 의무)
이용자는 서비스 이용 시 관련 법령을 준수해야 합니다.''',
              style: TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isTermsAgreed = true;
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A65),
                foregroundColor: Colors.white,
              ),
              child: const Text('동의'),
            ),
          ],
        );
      },
    );
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
        title: Text(
          _isLogin ? '로그인' : '회원가입',
          style: const TextStyle(
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
                Text(
                  _isLogin ? '환영합니다!' : '계정을 만드세요',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? '하노와 함께 완벽한 집을 찾아보세요' : '하노와 함께 시작해보세요',
                  style: const TextStyle(
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
                    borderRadius: BorderRadius.circular(12),
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
                        borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
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
                        borderRadius: BorderRadius.circular(12),
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
                if (!_isLogin) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _isTermsAgreed,
                            onChanged: (value) {
                              setState(() {
                                _isTermsAgreed = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFFFF8A65),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showTermsDialog,
                              child: const Text(
                                '서비스 이용약관에 동의합니다.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                        backgroundColor: (!_isLogin && !_isTermsAgreed) 
                            ? Colors.grey[300] 
                            : const Color(0xFFFF8A65),
                        foregroundColor: (!_isLogin && !_isTermsAgreed) 
                            ? Colors.grey[600] 
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: (!_isLogin && !_isTermsAgreed) ? null : _submit,
                      child: Text(
                        _isLogin ? '로그인' : '회원가입',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  key: _switchModeKey,
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      // 로그인/회원가입 모드 변경 시 약관동의 상태 초기화
                      _isTermsAgreed = false;
                    });
                  },
                  child:
                      Text(_isLogin ? '계정이 없으신가요? 회원가입' : '이미 계정이 있으신가요? 로그인'),
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
                // 디버깅용 테스트 계정 버튼
                if (!authState.isLoading)
                  TextButton(
                    onPressed: () async {
                      _emailController.text = 'test@example.com';
                      _passwordController.text = '123456';
                      
                      // 테스트 계정으로 로그인 시도
                      final viewModel = ref.read(authViewModelProvider.notifier);
                      final success = await viewModel.signInWithEmail('test@example.com', '123456');
                      
                      if (success) {
                        AppLogger.d('✅ 테스트 계정 로그인 완료');
                      } else {
                        AppLogger.d('❌ 테스트 계정 로그인 실패');
                      }
                    },
                    child: const Text(
                      '🧪 테스트 계정 사용 (test@example.com / 123456)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                authState.isLoading
                    ? const SizedBox.shrink() // 로딩 중에는 구글 버튼 숨김
                    : SizedBox(
                        key: _googleButtonKey,
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.g_mobiledata,
                            size: 24,
                            color: Color(0xFFFF8A65),
                          ),
                          label: const Text(
                            'Google로 계속하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF8A65),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFF8A65)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: _googleSignIn,
                        ),
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
              ],
            ),
          ),
        ),
      ),
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
        title: '모드 전환',
        description: '로그인과 회원가입 모드를 여기서 전환할 수 있습니다.',
        targetKey: _switchModeKey,
        tooltipPosition: GuideTooltipPosition.top,
        icon: Icons.swap_horiz,
      ),
      GuideStep(
        title: 'Google 로그인',
        description: 'Google 계정으로도 간편하게 로그인할 수 있습니다.',
        targetKey: _googleButtonKey,
        tooltipPosition: GuideTooltipPosition.top,
        icon: Icons.g_mobiledata,
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
