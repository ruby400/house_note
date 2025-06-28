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
  final _nicknameController = TextEditingController();
  final _realNameController = TextEditingController();
  
  String? _selectedAgeGroup;
  String? _selectedGender;
  
  final List<String> _ageGroups = ['20대', '30대', '40대', '50대', '60대 이상'];
  final List<String> _genders = ['여성', '남성'];

  @override
  void dispose() {
    _nicknameController.dispose();
    _realNameController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppLogger.warning('폼 검증 실패');
      return;
    }

    // 필수 필드 검증
    if (_selectedAgeGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('나이대를 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('성별을 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final notifier = ref.read(profileSettingViewModelProvider.notifier);
    final nickname = _nicknameController.text.trim();
    final realName = _realNameController.text.trim();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = GoRouter.of(context);

    final error = await notifier.saveProfile(
      nickname: nickname,
      realName: realName.isNotEmpty ? realName : null,
      ageGroup: _selectedAgeGroup!,
      gender: _selectedGender!,
    );

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
                  color: const Color(0xFFFF8A65).withValues(alpha: 0.1),
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
                '프로필을 설정해주세요',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // 닉네임 입력 필드 (필수)
              _buildInputField(
                controller: _nicknameController,
                labelText: '닉네임',
                hintText: '예: 길동이',
                prefixIcon: Icons.person,
                isRequired: true,
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
              
              const SizedBox(height: 20),
              
              // 실명 입력 필드 (선택)
              _buildInputField(
                controller: _realNameController,
                labelText: '실명',
                hintText: '예: 홍길동',
                prefixIcon: Icons.badge,
                isRequired: false,
                validator: null, // 선택사항이므로 validator 없음
              ),
              
              const SizedBox(height: 20),
              
              // 나이대 선택 (필수)
              _buildDropdownField(
                labelText: '나이대',
                value: _selectedAgeGroup,
                items: _ageGroups,
                onChanged: (value) => setState(() => _selectedAgeGroup = value),
                prefixIcon: Icons.cake,
                isRequired: true,
              ),
              
              const SizedBox(height: 20),
              
              // 성별 선택 (필수)
              _buildDropdownField(
                labelText: '성별',
                value: _selectedGender,
                items: _genders,
                onChanged: (value) => setState(() => _selectedGender = value),
                prefixIcon: Icons.person_outline,
                isRequired: true,
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
                            color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
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
  
  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    bool isRequired = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        controller: controller,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          label: isRequired 
              ? RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: labelText,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Color(0xFFFF8A65),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : Text(labelText),
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(
            prefixIcon,
            color: const Color(0xFFFF8A65),
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
        validator: validator,
      ),
    );
  }
  
  Widget _buildDropdownField({
    required String labelText,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData prefixIcon,
    bool isRequired = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          label: isRequired 
              ? RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: labelText,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Color(0xFFFF8A65),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : Text(labelText),
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(
            prefixIcon,
            color: const Color(0xFFFF8A65),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: isRequired && value == null 
                ? const BorderSide(color: Colors.red, width: 1)
                : BorderSide.none,
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
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }
}
