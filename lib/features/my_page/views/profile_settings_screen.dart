import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_note/core/widgets/loading_indicator.dart';
import 'package:house_note/features/my_page/viewmodels/profile_settings_viewmodel.dart';
import 'package:house_note/providers/user_providers.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  static const routeName = 'profile-settings';
  static const routePath = '/profile-settings';

  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // initState에서는 ref.read를 사용하는 것이 안전합니다.
    final user = ref.read(userModelProvider).value;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _nicknameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileSettingsState = ref.watch(profileSettingsViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '내 정보 설정',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileImage(),
                  const SizedBox(height: 8),
                  const Text(
                    '편집',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  _buildFormField(
                    label: '사용자 이름',
                    controller: _nameController,
                    validator: (value) => (value == null || value.isEmpty)
                        ? '사용자 이름을 입력해주세요'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    label: '닉네임',
                    controller: _nicknameController,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? '닉네임을 입력해주세요' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    label: '이메일',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력해주세요';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return '올바른 이메일 형식을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    label: '비밀번호',
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    validator: (value) =>
                        (value != null && value.isNotEmpty && value.length < 6)
                            ? '비밀번호는 6자리 이상이어야 합니다'
                            : null,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    label: '비밀번호 확인',
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(() =>
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible),
                    ),
                    validator: (value) {
                      if (_passwordController.text.isNotEmpty &&
                          value != _passwordController.text) {
                        return '비밀번호가 일치하지 않습니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  _buildSaveButton(profileSettingsState.isLoading),
                  const SizedBox(height: 20),
                  _buildWithdrawButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (profileSettingsState.isLoading)
            Positioned.fill(
              child: Container(
                color: const Color.fromARGB(77, 0, 0, 0),
                child: const LoadingIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF8A65), width: 3),
              color: Colors.grey[300],
            ),
            child: const Icon(Icons.person, size: 60, color: Colors.grey),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                // TODO: 이미지 선택 기능 구현
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('이미지 선택 기능 구현 예정'),
                    duration: Duration(milliseconds: 800),
                  ),
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFF8A65),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: suffixIcon,
            // 그림자 효과는 `Container`로 감싸는 대신 `InputDecoration`의 일부로 처리할 수 있습니다.
            // 하지만 기존 디자인 유지를 위해 `Container` 사용도 괜찮습니다.
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8A65),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          '저장',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildWithdrawButton() {
    return TextButton(
      onPressed: _showWithdrawDialog,
      child: const Text(
        '회원탈퇴',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 16,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  // ❗️❗️ 비동기 처리 후 BuildContext를 안전하게 사용하도록 수정
  void _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final notifier = ref.read(profileSettingsViewModelProvider.notifier);

      final success = await notifier.updateProfile(
        displayName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
      );

      // async-await 후에는 위젯이 여전히 화면에 있는지(mounted) 확인하는 것이 안전합니다.
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('프로필이 업데이트되었습니다'),
              duration: Duration(milliseconds: 800),
            ),
          );
        context.pop();
      } else {
        final error = ref.read(profileSettingsViewModelProvider).error;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('오류: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(milliseconds: 800),
            ),
          );
      }
    }
  }

  // ❗️❗️ 비동기 처리 후 BuildContext를 안전하게 사용하도록 수정
  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('회원탈퇴'),
          content: const Text('정말로 회원탈퇴를 하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                // 다이얼로그를 먼저 닫고 비동기 작업을 수행합니다.
                Navigator.of(dialogContext).pop();

                final notifier =
                    ref.read(profileSettingsViewModelProvider.notifier);
                final success = await notifier.deleteAccount();

                if (!mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('회원탈퇴가 완료되었습니다'),
                        duration: Duration(milliseconds: 800),
                      ),
                    );
                  context.go('/auth');
                } else {
                  final error =
                      ref.read(profileSettingsViewModelProvider).error;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text('오류: $error'),
                        backgroundColor: Colors.red,
                        duration: const Duration(milliseconds: 800),
                      ),
                    );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('탈퇴'),
            ),
          ],
        );
      },
    );
  }
}
