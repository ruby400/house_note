import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:house_note/providers/auth_providers.dart';
import 'package:house_note/core/widgets/loading_indicator.dart';

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

      print('🔄 인증 시작: ${_isLogin ? "로그인" : "회원가입"} - $email'); // 디버깅용

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

      print('🏁 인증 결과: ${success ? "성공" : "실패"}'); // 디버깅용

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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
                const SizedBox(height: 24),
                if (authState.isLoading)
                  const LoadingIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A65),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _submit,
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
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
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
                        print('✅ 테스트 계정 로그인 완료');
                      } else {
                        print('❌ 테스트 계정 로그인 실패');
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
}
