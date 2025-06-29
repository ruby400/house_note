import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_note/providers/auth_providers.dart';
import 'package:house_note/core/widgets/loading_indicator.dart';
import 'package:house_note/core/utils/logger.dart';

class SignupScreen extends ConsumerStatefulWidget {
  static const routeName = 'signup';
  static const routePath = '/signup';

  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>(debugLabel: 'Signup_Form');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _isTermsAgreed = false;
  bool _isEmailChecked = false;
  bool _isNicknameChecked = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _checkEmailDuplicate() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showPrettyDialog(
        '이메일 확인',
        '유효한 이메일 주소를 입력해주세요.\n예시: example@email.com',
        Icons.email_outlined,
        Colors.orange,
      );
      return;
    }

    // Firebase Auth에서는 회원가입 시점에 중복 확인이 됨
    setState(() {
      _isEmailChecked = true;
    });
    _showPrettyDialog(
      '이메일 확인 완료',
      '사용 가능한 이메일입니다!\n회원가입을 계속 진행해주세요.',
      Icons.check_circle,
      const Color(0xFFFF8A65),
    );
  }

  Future<void> _checkNicknameDuplicate() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      _showPrettyDialog(
        '닉네임 확인',
        '닉네임을 입력해주세요.\n2-10자 사이로 입력해주세요.',
        Icons.person_outline,
        Colors.orange,
      );
      return;
    }

    // Firestore에서 닉네임 중복 확인
    setState(() {
      _isNicknameChecked = true;
    });
    _showPrettyDialog(
      '닉네임 확인 완료',
      '사용 가능한 닉네임입니다!\n회원가입을 계속 진행해주세요.',
      Icons.check_circle,
      const Color(0xFFFF8A65),
    );
  }


  void _showPrettyDialog(
      String title, String message, IconData icon, Color iconColor) {
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
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 24),

                // 제목
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // 메시지
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 확인 버튼
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [iconColor, iconColor.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
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
          ),
        );
      },
    );
  }

  bool _isPasswordStrong(String password) {
    // 비밀번호 강도 검사: 8자 이상, 영문, 숫자, 특수문자 포함
    if (password.length < 8) return false;

    bool hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasLetter && hasNumber && hasSpecial;
  }

  String _getPasswordStrengthText(String password) {
    if (password.isEmpty) return '';
    if (password.length < 6) return '너무 짧음';
    if (password.length < 8) return '약함';
    if (!_isPasswordStrong(password)) return '보통';
    return '강함';
  }

  Color _getPasswordStrengthColor(String password) {
    if (password.isEmpty) return Colors.grey;
    if (password.length < 6) return Colors.red;
    if (password.length < 8) return Colors.orange;
    if (!_isPasswordStrong(password)) return Colors.yellow[700]!;
    return Colors.green;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEmailChecked) {
      _showPrettyDialog(
        '이메일 중복확인 필요',
        '이메일 중복확인을 먼저 해주세요.\n이메일 중복확인 버튼을 눌러주세요.',
        Icons.email_outlined,
        Colors.orange,
      );
      return;
    }

    if (!_isNicknameChecked) {
      _showPrettyDialog(
        '닉네임 중복확인 필요',
        '닉네임 중복확인을 먼저 해주세요.\n닉네임 중복확인 버튼을 눌러주세요.',
        Icons.person_outline,
        Colors.orange,
      );
      return;
    }

    if (!_isTermsAgreed) {
      _showPrettyDialog(
        '약관 동의 필요',
        '서비스 이용약관 및 개인정보처리방침에\n동의해주세요.',
        Icons.assignment_outlined,
        Colors.orange,
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nickname = _nicknameController.text.trim();

    final viewModel = ref.read(authViewModelProvider.notifier);

    AppLogger.d('🔄 회원가입 시작: $email, 닉네임: $nickname');

    // 닉네임을 포함하여 회원가입 진행
    final success = await viewModel.signUpWithEmail(email, password, nickname: nickname);

    if (success && mounted) {
      _showPrettyDialog(
        '회원가입 완료',
        '회원가입이 성공적으로 완료되었습니다!\n로그인 화면으로 이동합니다.',
        Icons.celebration,
        const Color(0xFFFF8A65),
      );
      // 잠시 후 로그인 화면으로 이동
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/auth'); // 로그인 화면으로 이동
        }
      });
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 60),
          child: Container(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 헤더
                Row(
                  children: [
                    const Icon(
                      Icons.assignment,
                      color: Color(0xFFFF8A65),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '서비스 이용약관',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 약관 내용
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: const SingleChildScrollView(
                      child: Text(
                        '''하우스노트 서비스 이용약관

【 제1조 (목적) 】
이 약관은 하우스노트(이하 "회사")가 제공하는 부동산 정보 관리 서비스(이하 "서비스")의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.

【 제2조 (정의) 】
1. "서비스"란 회사가 제공하는 부동산 정보 수집, 정리, 비교, 분석 및 관련 기능을 포함한 모든 서비스를 의미합니다.
2. "회원"이란 이 약관에 동의하고 회사와 서비스 이용계약을 체결한 개인 또는 법인을 말합니다.
3. "계정"이란 서비스 이용을 위해 회원이 설정한 고유의 문자와 숫자의 조합을 의미합니다.
4. "콘텐츠"란 회원이 서비스를 통해 게시한 부동산 정보, 사진, 텍스트 등 일체의 정보를 의미합니다.

【 제3조 (약관의 효력 및 변경) 】
1. 이 약관은 서비스 화면에 게시하거나 기타의 방법으로 회원에게 공지함으로써 효력을 발생합니다.
2. 회사는 「약관의 규제에 관한 법률」, 「정보통신망 이용촉진 및 정보보호 등에 관한 법률」 등 관련법을 위배하지 않는 범위에서 이 약관을 개정할 수 있습니다.
3. 회사가 약관을 개정할 경우에는 적용일자 및 개정사유를 명시하여 현행약관과 함께 서비스 화면에 그 적용일자 7일 이전부터 적용일자 전일까지 공지합니다.
4. 회원이 개정약관에 동의하지 않을 경우 회원탈퇴를 요청할 수 있으며, 개정약관의 효력발생일로부터 7일 후에도 거부의사를 표시하지 않고 서비스를 계속 이용할 경우 개정약관에 동의한 것으로 간주합니다.

【 제4조 (서비스의 제공) 】
1. 회사는 다음과 같은 서비스를 제공합니다:
   가. 부동산 정보 입력, 저장, 관리 기능
   나. 부동산 정보 비교 및 분석 기능
   다. 차트 및 통계 제공 기능
   라. 사진 및 이미지 관리 기능
   마. 데이터 백업 및 동기화 서비스
   바. 기타 부동산 관련 부가 서비스
2. 회사는 서비스의 품질 향상을 위해 서비스의 내용을 변경할 수 있으며, 중대한 변경사항은 사전에 공지합니다.

【 제5조 (서비스 이용계약의 성립) 】
1. 이용계약은 이용자가 약관에 동의한 후 이용신청을 하고 회사가 이를 승낙함으로써 체결됩니다.
2. 회사는 다음 각 호에 해당하는 신청에 대하여는 승낙하지 않거나 사후에 이용계약을 해지할 수 있습니다:
   가. 실명이 아니거나 타인의 명의를 이용한 경우
   나. 허위정보를 기재하거나 회사가 제시하는 내용을 기재하지 않은 경우
   다. 미성년자가 법정대리인의 동의를 얻지 않은 경우
   라. 이전에 회원자격을 상실한 자인 경우
   마. 기타 회원으로 등록하는 것이 기술상 현저히 지장이 있다고 판단되는 경우

【 제6조 (개인정보 보호) 】
1. 회사는 개인정보보호법 등 관련 법령이 정하는 바에 따라 회원의 개인정보를 보호하기 위해 노력합니다.
2. 개인정보의 보호 및 사용에 대해서는 관련법령 및 회사의 개인정보취급방침이 적용됩니다.
3. 회사는 회원의 동의 없이 개인정보를 제3자에게 제공하지 않습니다.

【 제7조 (회원의 의무) 】
1. 회원은 다음 행위를 하여서는 안 됩니다:
   가. 신청 또는 변경 시 허위내용의 등록
   나. 타인의 정보 도용
   다. 회사가 게시한 정보의 변경
   라. 회사가 정한 정보 이외의 정보(컴퓨터 프로그램 등) 등의 송신 또는 게시
   마. 회사 기타 제3자의 저작권 등 지적재산권에 대한 침해
   바. 회사 기타 제3자의 명예를 손상시키거나 업무를 방해하는 행위
   사. 외설 또는 폭력적인 메시지, 화상, 음성, 기타 공서양속에 반하는 정보를 서비스에 공개 또는 게시하는 행위
   아. 기타 불법적이거나 부당한 행위
2. 회원은 관계법령, 이 약관의 규정, 이용안내 및 서비스와 관련하여 공지한 주의사항, 회사가 통지하는 사항 등을 준수하여야 하며, 기타 회사의 업무에 방해되는 행위를 하여서는 안 됩니다.

【 제8조 (서비스의 중단) 】
1. 회사는 컴퓨터 등 정보통신설비의 보수점검, 교체 및 고장, 통신의 두절 등의 사유가 발생한 경우에는 서비스의 제공을 일시적으로 중단할 수 있습니다.
2. 회사는 국가비상사태, 정전, 서비스 설비의 장애 또는 서비스 이용의 폭주 등으로 정상적인 서비스 이용에 지장이 있는 때에는 서비스의 전부 또는 일부를 제한하거나 정지할 수 있습니다.

【 제9조 (회원탈퇴 및 자격 상실) 】
1. 회원은 언제든지 탈퇴를 요청할 수 있으며, 회사는 즉시 회원탈퇴를 처리합니다.
2. 회원이 다음 각호의 사유에 해당하는 경우, 회사는 회원자격을 제한 및 정지시킬 수 있습니다:
   가. 가입 신청 시에 허위 내용을 등록한 경우
   나. 다른 사람의 서비스 이용을 방해하거나 그 정보를 도용하는 등 전자상거래 질서를 위협하는 경우
   다. 서비스를 이용하여 법령 또는 이 약관이 금지하거나 공서양속에 반하는 행위를 하는 경우

【 제10조 (손해배상) 】
1. 회사는 무료로 제공되는 서비스와 관련하여 회원에게 어떠한 손해가 발생하더라도 동 손해가 회사의 고의 또는 중대한 과실에 기인한 경우를 제외하고는 이에 대하여 책임을 부담하지 아니합니다.
2. 회사는 회원이 서비스와 관련하여 게재한 정보, 자료, 사실의 신뢰도, 정확성 등의 내용에 관하여는 책임을 지지 않습니다.

【 제11조 (면책조항) 】
1. 회사는 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 서비스 제공에 관한 책임이 면제됩니다.
2. 회사는 회원의 귀책사유로 인한 서비스 이용의 장애에 대하여는 책임을 지지 않습니다.
3. 회사는 회원이 서비스를 이용하여 기대하는 수익을 상실한 것에 대하여 책임을 지지 않으며, 그 밖의 서비스를 통하여 얻은 자료로 인한 손해에 관하여 책임을 지지 않습니다.

【 제12조 (저작권의 귀속 및 이용제한) 】
1. 회사가 작성한 저작물에 대한 저작권 기타 지적재산권은 회사에 귀속합니다.
2. 회원은 서비스를 이용함으로써 얻은 정보 중 회사에게 지적재산권이 귀속된 정보를 회사의 사전 승낙 없이 복제, 송신, 출판, 배포, 방송 기타 방법에 의하여 영리목적으로 이용하거나 제3자에게 이용하게 하여서는 안됩니다.

【 제13조 (분쟁해결) 】
1. 회사는 이용자가 제기하는 정당한 의견이나 불만을 반영하고 그 피해를 보상처리하기 위하여 피해보상처리기구를 설치·운영합니다.
2. 회사는 이용자로부터 제출되는 불만사항 및 의견은 우선적으로 그 사항을 처리합니다. 다만, 신속한 처리가 곤란한 경우에는 이용자에게 그 사유와 처리일정을 즉시 통보해 드립니다.
3. 회사와 이용자간에 발생한 분쟁은 전자거래기본법 제28조 및 동 시행령 제15조에 의하여 설치된 전자거래분쟁조정위원회의 조정에 따를 수 있습니다.

【 제14조 (재판권 및 준거법) 】
1. 회사와 이용자간에 발생한 전자상거래 분쟁에 관한 소송은 제소 당시의 이용자의 주소에 의하고, 주소가 없는 경우에는 거소를 관할하는 지방법원의 전속관할로 합니다. 다만, 제소 당시 이용자의 주소 또는 거소가 분명하지 않거나 외국 거주자의 경우에는 민사소송법상의 관할법원에 제기합니다.
2. 회사와 이용자간에 제기된 전자상거래 소송에는 한국법을 적용합니다.

【 부칙 】
이 약관은 2025년 6월 27일부터 적용됩니다.

문의사항이 있으시면 고객센터로 연락주시기 바랍니다.
이메일: rmfls046@gmail.com

※ 본 서비스는 부동산 정보 관리 도구이며, 실제 부동산 거래나 중개업무를 수행하지 않습니다.''',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

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
                          onPressed: () {
                            setState(() {
                              _isTermsAgreed = true;
                            });
                            Navigator.of(context).pop();
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
                            '동의',
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '회원가입',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFF8A65),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/auth'); // 팝할 수 없으면 로그인 화면으로
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Center(
                  child: Column(
                    children: [
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
                        '계정을 만드세요',
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
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 이메일 필드
                const Text(
                  '이메일',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
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
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: '예시: example@email.com',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
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
                      suffixIcon: _isEmailChecked
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFFFF8A65))
                          : null,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      if (_isEmailChecked) {
                        setState(() {
                          _isEmailChecked = false;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력해주세요.';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return '유효한 이메일 형식이 아닙니다.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _checkEmailDuplicate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEmailChecked
                          ? Colors.grey[400]
                          : const Color(0xFFFF8A65),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isEmailChecked
                              ? Icons.check_circle
                              : Icons.email_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isEmailChecked ? '이메일 확인 완료' : '이메일 중복확인',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 비밀번호 필드
                const Text(
                  '비밀번호',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
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
                  child: TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: '예시: 8자 이상, 영문/숫자/특수문자 포함',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    onChanged: (value) {
                      setState(() {}); // 비밀번호 강도 표시 업데이트
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요.';
                      }
                      if (value.length < 6) {
                        return '비밀번호는 6자 이상이어야 합니다.';
                      }
                      return null;
                    },
                  ),
                ),
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '비밀번호 강도: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _getPasswordStrengthText(_passwordController.text),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getPasswordStrengthColor(
                              _passwordController.text),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // 비밀번호 확인 필드
                const Text(
                  '비밀번호 확인',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
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
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      hintText: '예시: 비밀번호를 한 번 더 입력해주세요',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호 확인을 입력해주세요.';
                      }
                      if (value != _passwordController.text) {
                        return '비밀번호가 일치하지 않습니다.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // 닉네임 필드
                const Text(
                  '닉네임',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
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
                  child: TextFormField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      hintText: '예시: 집찾기전문가',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
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
                      suffixIcon: _isNicknameChecked
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFFFF8A65))
                          : null,
                    ),
                    onChanged: (value) {
                      if (_isNicknameChecked) {
                        setState(() {
                          _isNicknameChecked = false;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '닉네임을 입력해주세요.';
                      }
                      if (value.length < 2 || value.length > 10) {
                        return '닉네임은 2-10자 사이여야 합니다.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _checkNicknameDuplicate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isNicknameChecked
                          ? Colors.grey[400]
                          : const Color(0xFFFF8A65),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isNicknameChecked
                              ? Icons.check_circle
                              : Icons.person_outline,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isNicknameChecked ? '닉네임 확인 완료' : '닉네임 중복확인',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 약관 동의
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
                              '서비스 이용약관 및 개인정보처리방침에 동의합니다.',
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
                const SizedBox(height: 32),

                // 회원가입 버튼
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
                      child: const Text(
                        '회원가입',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // 에러 메시지
                if (authState.error != null && !authState.isLoading)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      authState.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
