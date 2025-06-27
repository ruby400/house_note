import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/features/auth/viewmodels/auth_viewmodel.dart';
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
  bool _isLogin = true; // true면 로그인, false면 회원가입
  bool _isTermsAgreed = false; // 약관동의 체크 상태

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

  Future<void> _naverSignIn() async {
    final viewModel = ref.read(authViewModelProvider.notifier);
    bool success = await viewModel.signInWithNaver();
    if (success && mounted) {
      // 네이버 로그인 성공 후 처리 (GoRouter redirect에 의해 처리될 수 있음)
      // 예시: context.go(PrioritySettingScreen.routePath);
    }
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('개인정보처리방침'),
          content: const SingleChildScrollView(
            child: Text(
              '''하우스노트 개인정보처리방침

【 제1조 (개인정보의 처리목적) 】
하우스노트(이하 "회사")는 다음의 목적을 위하여 개인정보를 처리합니다. 처리하고 있는 개인정보는 다음의 목적 이외의 용도로는 이용되지 않으며, 이용 목적이 변경되는 경우에는 개인정보보호법 제18조에 따라 별도의 동의를 받는 등 필요한 조치를 이행할 예정입니다.

1. 회원가입 및 관리
   - 회원 가입의사 확인, 회원제 서비스 제공에 따른 본인 식별·인증, 회원자격 유지·관리, 서비스 부정이용 방지, 각종 고지·통지 목적으로 개인정보를 처리합니다.

2. 서비스 제공
   - 부동산 정보 관리 서비스 제공, 콘텐츠 제공, 맞춤서비스 제공, 본인인증을 목적으로 개인정보를 처리합니다.

3. 고충처리
   - 민원인의 신원 확인, 민원사항 확인, 사실조사를 위한 연락·통지, 처리결과 통보의 목적으로 개인정보를 처리합니다.

【 제2조 (개인정보의 처리 및 보유기간) 】
1. 회사는 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집 시에 동의받은 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.

2. 각각의 개인정보 처리 및 보유 기간은 다음과 같습니다:
   - 회원가입 및 관리: 회원탈퇴 시까지
   - 서비스 제공: 서비스 이용계약 종료 시까지
   - 부정이용 기록: 부정이용 행위 종료 후 1년

【 제3조 (개인정보의 제3자 제공) 】
회사는 정보주체의 개인정보를 제1조(개인정보의 처리목적)에서 명시한 범위 내에서만 처리하며, 정보주체의 동의, 법률의 특별한 규정 등 개인정보보호법 제17조에 해당하는 경우에만 개인정보를 제3자에게 제공합니다.

【 제4조 (개인정보처리의 위탁) 】
1. 회사는 원활한 개인정보 업무처리를 위하여 다음과 같이 개인정보 처리업무를 위탁하고 있습니다:
   - 클라우드 서비스 제공업체: Google Firebase
   - 위탁업무 내용: 개인정보가 포함된 데이터의 보관 및 관리

2. 회사는 위탁계약 체결시 개인정보보호법 제26조에 따라 위탁업무 수행목적 외 개인정보 처리금지, 기술적·관리적 보호조치, 재위탁 제한, 수탁자에 대한 관리·감독, 손해배상 등 책임에 관한 사항을 계약서 등 문서에 명시하고, 수탁자가 개인정보를 안전하게 처리하는지를 감독하고 있습니다.

【 제5조 (정보주체의 권리·의무 및 행사방법) 】
1. 정보주체는 회사에 대해 언제든지 다음 각 호의 개인정보 보호 관련 권리를 행사할 수 있습니다:
   가. 개인정보 처리현황 통지요구
   나. 개인정보 열람요구
   다. 개인정보 정정·삭제요구
   라. 개인정보 처리정지요구

2. 제1항에 따른 권리 행사는 회사에 대해 서면, 전화, 전자우편, 모사전송(FAX) 등을 통하여 하실 수 있으며 회사는 이에 대해 지체없이 조치하겠습니다.

【 제6조 (처리하는 개인정보 항목) 】
회사는 다음의 개인정보 항목을 처리하고 있습니다:

1. 회원가입 및 관리
   - 필수항목: 이메일주소, 비밀번호, 이름
   - 선택항목: 프로필 사진

2. 서비스 이용과정에서 자동으로 생성되는 정보
   - IP주소, 쿠키, MAC주소, 서비스 이용기록, 방문기록

【 제7조 (개인정보의 파기) 】
1. 회사는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체없이 해당 개인정보를 파기합니다.

2. 개인정보 파기의 절차 및 방법은 다음과 같습니다:
   - 파기절차: 불필요한 개인정보 및 개인정보파일은 개인정보책임자의 책임 하에 파기됩니다.
   - 파기방법: 전자적 파일형태로 기록·저장된 개인정보는 기록을 재생할 수 없도록 파기하며, 종이문서에 기록·저장된 개인정보는 분쇄기로 분쇄하거나 소각하여 파기합니다.

【 제8조 (개인정보의 안전성 확보조치) 】
회사는 개인정보보호법 제29조에 따라 다음과 같이 안전성 확보에 필요한 기술적/관리적 및 물리적 조치를 하고 있습니다:

1. 정기적인 자체 감사 실시
2. 개인정보 취급 직원의 최소화 및 교육
3. 내부관리계획의 수립 및 시행
4. 해킹 등에 대비한 기술적 대책
5. 개인정보의 암호화
6. 접속기록의 보관 및 위변조 방지
7. 개인정보에 대한 접근 제한
8. 문서보안을 위한 잠금장치 사용

【 제9조 (개인정보 자동 수집 장치의 설치·운영 및 거부) 】
1. 회사는 이용자에게 개별적인 맞춤서비스를 제공하기 위해 이용정보를 저장하고 수시로 불러오는 '쿠키(cookie)'를 사용합니다.

2. 쿠키는 웹사이트를 운영하는데 이용되는 서버(http)가 이용자의 컴퓨터 브라우저에게 보내는 소량의 정보이며 이용자들의 PC 컴퓨터내의 하드디스크에 저장되기도 합니다.

3. 쿠키의 사용목적: 이용자가 방문한 각 서비스와 웹 사이트들에 대한 방문 및 이용형태, 인기 검색어, 보안접속 여부, 등을 파악하여 이용자에게 최적화된 정보 제공을 위해 사용됩니다.

【 제10조 (개인정보보호책임자) 】
1. 회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위하여 아래와 같이 개인정보보호책임자를 지정하고 있습니다:

   개인정보보호책임자
   - 성명: 홍길동
   - 직책: 개발팀장
   - 연락처: privacy@housenote.com, 1588-0000

2. 정보주체께서는 회사의 서비스를 이용하시면서 발생한 모든 개인정보 보호 관련 문의, 불만처리, 피해구제 등에 관한 사항을 개인정보보호책임자에게 문의하실 수 있습니다.

【 제11조 (개인정보 처리방침 변경) 】
이 개인정보처리방침은 시행일로부터 적용되며, 법령 및 방침에 따른 변경내용의 추가, 삭제 및 정정이 있는 경우에는 변경사항의 시행 7일 전부터 공지사항을 통하여 고지할 것입니다.

【 부칙 】
이 방침은 2024년 6월 24일부터 시행됩니다.

개인정보 관련 문의
이메일: privacy@housenote.com
전화: 1588-0000 (평일 09:00~18:00)

※ 개인정보보호법, 정보통신망법 등 관련 법령에 따라 작성되었습니다.''',
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

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('서비스 이용약관'),
          content: const SingleChildScrollView(
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
이 약관은 2024년 6월 24일부터 적용됩니다.

문의사항이 있으시면 고객센터로 연락주시기 바랍니다.
이메일: support@housenote.com
전화: 1588-0000 (평일 09:00~18:00)

※ 본 서비스는 부동산 정보 관리 도구이며, 실제 부동산 거래나 중개업무를 수행하지 않습니다.''',
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
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: _showTermsDialog,
                                  child: const Text(
                                    '서비스 이용약관',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const Text(
                                  ' 및 ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _showPrivacyDialog,
                                  child: const Text(
                                    '개인정보처리방침',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const Text(
                                  '에 동의합니다.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
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
                authState.isLoading
                    ? const SizedBox.shrink() // 로딩 중에는 소셜 로그인 버튼 숨김
                    : Column(
                        children: [
                          SizedBox(
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
                          const SizedBox(height: 12),
                          SizedBox(
                            key: _naverButtonKey,
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              icon: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF03C75A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    'N',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              label: const Text(
                                '네이버로 계속하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF03C75A),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF03C75A)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.white,
                              ),
                              onPressed: _naverSignIn,
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
