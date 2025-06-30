import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_note/core/widgets/loading_indicator.dart';
import 'package:house_note/features/my_page/viewmodels/profile_settings_viewmodel.dart';
import 'package:house_note/features/onboarding/views/interactive_guide_overlay.dart';
import 'package:house_note/providers/user_providers.dart';
import 'package:house_note/providers/auth_providers.dart';
import 'package:house_note/services/image_service.dart';
import 'package:house_note/core/utils/logger.dart';
import 'dart:io';

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

  // 튜토리얼 관련
  final GlobalKey _profileImageKey = GlobalKey();
  final GlobalKey _nameFieldKey = GlobalKey();
  final GlobalKey _saveButtonKey = GlobalKey();

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
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _showTutorial,
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
                  Container(
                    key: _nameFieldKey,
                    child: _buildFormField(
                      label: '사용자 이름',
                      controller: _nameController,
                      validator: (value) => (value == null || value.isEmpty)
                          ? '사용자 이름을 입력해주세요'
                          : null,
                    ),
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
    final userAsync = ref.watch(userModelProvider);
    final user = userAsync.asData?.value;

    return Center(
      child: GestureDetector(
        key: _profileImageKey,
        onTap: _showImageSelectionDialog,
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
              child: ClipOval(
                child: user?.photoURL != null
                    ? _buildProfileImageWidget(user!.photoURL!)
                    : const Icon(Icons.person, size: 60, color: Colors.grey),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
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
          ],
        ),
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
        key: _saveButtonKey,
        onPressed: isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8A65),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
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
      barrierDismissible: false,
      builder: (dialogContext) {
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
                // 경고 아이콘
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 24),

                // 제목
                const Text(
                  '회원탈퇴',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // 경고 메시지
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '⚠️ 주의사항',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• 모든 매물 데이터가 영구 삭제됩니다\n• 작성한 차트와 기록이 모두 사라집니다\n• 이 작업은 되돌릴 수 없습니다',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 버튼들
                Row(
                  children: [
                    // 취소 버튼
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
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

                    // 탈퇴 버튼
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.red, Color(0xFFE53935)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            // 다이얼로그를 먼저 닫고 비동기 작업을 수행합니다.
                            Navigator.of(dialogContext).pop();
                            
                            // 재인증 다이얼로그 표시
                            _showReauthenticationDialog();
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
                            '탈퇴하기',
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

  Widget _buildProfileImageWidget(String photoURL) {
    // 로컬 파일 경로인지 URL인지 확인
    if (photoURL.startsWith('http')) {
      // 네트워크 이미지
      return Image.network(
        photoURL,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 60, color: Colors.grey);
        },
      );
    } else {
      // 로컬 파일
      return Image.file(
        File(photoURL),
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 60, color: Colors.grey);
        },
      );
    }
  }

  void _showImageSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        elevation: 8,
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF8A65),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.photo_camera, color: Colors.white, size: 22),
                    SizedBox(width: 16),
                    Text(
                      '프로필 사진 변경',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
              // 내용
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECE0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '카메라로 촬영하거나 갤러리에서 사진을 선택하세요.',
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF6D4C41)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 버튼들
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF8A65)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _takePicture();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 20),
                              label: const Text(
                                '카메라',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey[700]!, Colors.grey[800]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _pickFromGallery();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.photo_library,
                                  color: Colors.white, size: 20),
                              label: const Text(
                                '갤러리',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
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
              // 하단 버튼
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('취소',
                          style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    try {
      final imagePath = await ImageService.takePicture();
      if (imagePath != null) {
        await _updateProfileImage(imagePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('카메라 사용 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final imagePath = await ImageService.pickImageFromGallery();
      if (imagePath != null) {
        await _updateProfileImage(imagePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('갤러리 사용 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProfileImage(String imagePath) async {
    try {
      // 여기서 실제로는 서버에 이미지를 업로드하고 URL을 받아야 하지만,
      // 현재는 로컬 파일 경로를 사용합니다.
      final userAsync = ref.read(userModelProvider);
      final user = userAsync.asData?.value;
      if (user != null) {
        // TODO: 실제 구현에서는 서버에 이미지 업로드 후 URL 업데이트
        // 현재는 로컬 파일 경로로 임시 저장
        final userRepository = ref.read(userRepositoryProvider);
        await userRepository.updateUserProfile(user.uid, photoURL: imagePath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('프로필 사진이 변경되었습니다.'),
              backgroundColor: Color(0xFFFF8A65),
              duration: Duration(milliseconds: 1000),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 사진 업데이트 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReauthenticationDialog() {
    AppLogger.d('🔍 _showReauthenticationDialog 호출됨');
    
    // Firebase Auth 상태를 직접 확인
    final authState = ref.read(authStateChangesProvider);
    final firebaseUser = authState.asData?.value;
    final userModel = ref.read(userModelProvider).value;
    
    AppLogger.d('🔍 Firebase User: ${firebaseUser?.email}');
    AppLogger.d('🔍 UserModel: ${userModel?.email}');
    
    if (firebaseUser == null) {
      AppLogger.error('❌ Firebase User가 null임');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 상태를 확인할 수 없습니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 구글 계정인지 확인 (Firebase Auth 정보 우선 사용)
    final userEmail = userModel?.email ?? firebaseUser.email;
    final isGoogleAccount = firebaseUser.providerData
        .any((info) => info.providerId == 'google.com') ||
        userEmail?.contains('@gmail.com') == true;

    AppLogger.d('🔍 이메일: $userEmail');
    AppLogger.d('🔍 구글 계정 여부: $isGoogleAccount');
    AppLogger.d('🔍 Provider 정보: ${firebaseUser.providerData.map((p) => p.providerId).toList()}');

    if (isGoogleAccount) {
      AppLogger.d('✅ 구글 계정 - 즉시 탈퇴 진행');
      // 구글 계정의 경우 즉시 탈퇴 진행
      _performAccountDeletion();
    } else {
      AppLogger.d('✅ 이메일 계정 - 비밀번호 확인 다이얼로그 표시');
      // 이메일 계정의 경우 비밀번호 확인
      _showPasswordConfirmationDialog();
    }
  }

  void _showPasswordConfirmationDialog() {
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
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
                // 잠금 아이콘
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A65).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: Color(0xFFFF8A65),
                  ),
                ),
                const SizedBox(height: 24),

                // 제목
                const Text(
                  '비밀번호 확인',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // 설명
                const Text(
                  '보안을 위해 현재 비밀번호를 입력해주세요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 비밀번호 입력 필드
                TextFormField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '현재 비밀번호',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(
                          () => isPasswordVisible = !isPasswordVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 버튼들
                Row(
                  children: [
                    // 취소 버튼
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
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

                    // 확인 버튼
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.red, Color(0xFFE53935)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _performAccountDeletion(password: passwordController.text);
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
                            '확인',
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
        ),
      ),
    );
  }

  Future<void> _performAccountDeletion({String? password}) async {
    AppLogger.d('🚀 _performAccountDeletion 호출됨 - 비밀번호: ${password != null ? '있음' : '없음'}');
    
    final notifier = ref.read(profileSettingsViewModelProvider.notifier);
    
    try {
      AppLogger.d('🔥 deleteAccount 호출 시작');
      final success = await notifier.deleteAccount(password: password);
      AppLogger.d('🔥 deleteAccount 결과: $success');

      if (!mounted) {
        AppLogger.warning('⚠️ Widget이 unmounted됨');
        return;
      }

      if (success) {
        AppLogger.d('✅ 회원탈퇴 성공');
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
        final error = ref.read(profileSettingsViewModelProvider).error;
        AppLogger.error('❌ 회원탈퇴 실패: $error');
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
    } catch (e) {
      AppLogger.error('💥 _performAccountDeletion 예외 발생', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('예상치 못한 오류: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(milliseconds: 800),
            ),
          );
      }
    }
  }

  void _showTutorial() {
    final steps = [
      GuideStep(
        title: '프로필 사진',
        description: '프로필 사진을 변경할 수 있습니다.\n사진을 터치하여 갤러리에서 선택하세요.',
        targetKey: _profileImageKey,
        icon: Icons.camera_alt,
        tooltipPosition: GuideTooltipPosition.bottom,
      ),
      GuideStep(
        title: '이름 수정',
        description: '표시될 이름을 변경할 수 있습니다.',
        targetKey: _nameFieldKey,
        icon: Icons.edit,
        tooltipPosition: GuideTooltipPosition.bottom,
      ),
      GuideStep(
        title: '변경사항 저장',
        description: '모든 변경사항을 저장하려면 이 버튼을 눌러주세요.',
        targetKey: _saveButtonKey,
        icon: Icons.save,
        tooltipPosition: GuideTooltipPosition.top,
      ),
    ];

    InteractiveGuideManager.showGuide(
      context,
      steps: steps,
      onCompleted: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필 설정 가이드가 완료되었습니다!'),
            backgroundColor: Color(0xFFFF8A65),
          ),
        );
      },
      onSkipped: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('가이드를 건너뛰었습니다.')),
        );
      },
    );
  }
}
