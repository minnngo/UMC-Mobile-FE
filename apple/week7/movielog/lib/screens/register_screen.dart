import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';

/// 입력값을 검사해 오류 메시지를 돌려주는 함수 타입입니다. 통과하면 null입니다.
typedef FieldValidator = String? Function(String? value);

/// 회원가입 화면입니다. (2주차 W2-01에서 가져옴) Figma 프레임 388 기준으로 배치합니다.
///
/// Guided Practice 구조:
/// - Step 1. Scaffold + SafeArea + SingleChildScrollView + Form(GlobalKey)
/// - Step 2. Controller / FocusNode / 약관 동의 bool / dispose
/// - Step 3. 닉네임 TextFormField (label, hint, 빈 값·2자 미만 검사, onChanged setState)
///
/// 화면은 의미 단위로 나뉩니다.
/// - [_WelcomeMessage] 환영 문구
/// - [_SignupFields] 닉네임·이메일·비밀번호 입력창 묶음
/// - [_SignupFooter] 약관 동의, 가입하기 버튼, 로그인 링크
///
/// 6주차 — 형식 검사는 validator가, 서버 중복 여부는 [SignUpViewModel]이 담당합니다.
/// 두 결과를 함께 보여주고, 닉네임·이메일이 모두 사용 가능해야 가입하기가 켜집니다.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Step 1. Form 전체를 제어할 키
  final _formKey = GlobalKey<FormState>();

  // Step 2. 입력값을 읽고 지울 Controller
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Step 2. 이메일에서 "다음"을 누르면 비밀번호로 포커스를 옮기기 위한 FocusNode
  final _passwordFocusNode = FocusNode();

  // Step 2. 약관 동의 여부
  bool _agreedToTerms = false;

  @override
  void dispose() {
    // Step 2. State가 사라질 때 리소스를 반드시 해제합니다.
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validator — TextFormField와 버튼 활성화 판단에서 함께 사용합니다.
  // 형식만 검사하고, 서버 중복 여부는 SignUpViewModel의 errorText로 보여줍니다.
  // ---------------------------------------------------------------------------

  String? _validateNickname(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '닉네임을 입력해주세요.';
    if (text.length < 2) return '닉네임은 2자 이상이어야 합니다.';
    return null;
  }

  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '이메일을 입력해주세요.';
    if (!_emailPattern.hasMatch(text)) return '올바른 이메일 형식이 아닙니다.';
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return '비밀번호를 입력해주세요.';
    if (text.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    return null;
  }

  /// 세 입력이 모두 유효하고, 닉네임·이메일 중복 확인을 통과하고,
  /// 약관에 동의했을 때만 가입하기 버튼을 켭니다.
  bool _canSubmit(SignUpViewModel viewModel) =>
      _validateNickname(_nicknameController.text) == null &&
      _validateEmail(_emailController.text) == null &&
      _validatePassword(_passwordController.text) == null &&
      viewModel.nicknameCheckStatus == CheckStatus.available &&
      viewModel.emailCheckStatus == CheckStatus.available &&
      _agreedToTerms;

  /// 가입하기 — Form 전체를 다시 검증한 뒤 홈으로 이동합니다.
  /// v5에는 회원가입 API가 없어 실제 계정은 만들지 않습니다.
  /// go로 이동해 회원가입 화면을 스택에서 빼므로 홈에서 뒤로 돌아오지 않습니다.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.go('/home');
  }

  /// 시작 화면에서 go로 들어와 돌아갈 화면이 쌓여 있지 않으므로 시작 화면으로 go합니다.
  void _backToStart() => context.go('/start');

  @override
  Widget build(BuildContext context) {
    // 시스템 뒤로가기(Android 뒤로 버튼 등)도 헤더 화살표와 같이 시작 화면으로 보냅니다.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _backToStart();
      },
      child: Scaffold(
        appBar: CommonAppBar(
          title: '회원가입',
          titleStyle: AppTheme.appBarTitleBold,
          onBack: _backToStart,
        ),
        body: SafeArea(
          // 키보드가 올라와도 입력창이 가려지지 않도록 스크롤 가능하게 만듭니다.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                // 내용이 짧아도 하단 영역이 화면 아래에 붙도록 최소 높이를 보장합니다.
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  // 사용자가 입력을 시작한 필드부터 즉시 검사합니다. (W2-02)
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  // 메인 컨테이너: padding 24 / 16, gap 32
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    // Expanded를 스크롤 뷰 안에서 쓰기 위해 IntrinsicHeight로 높이를 확정합니다.
                    child: IntrinsicHeight(
                      // 중복 확인 상태가 바뀌면 입력창 에러와 가입하기 버튼을 다시 그립니다.
                      child: Consumer<SignUpViewModel>(
                        builder: (context, viewModel, child) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _WelcomeMessage(),
                            const SizedBox(height: 32),
                            _SignupFields(
                              viewModel: viewModel,
                              nicknameController: _nicknameController,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              passwordFocusNode: _passwordFocusNode,
                              validateNickname: _validateNickname,
                              validateEmail: _validateEmail,
                              validatePassword: _validatePassword,
                              // 입력이 바뀔 때마다 버튼 활성화와 상태 아이콘을 다시 계산합니다.
                              onChanged: () => setState(() {}),
                              onPasswordSubmitted: _canSubmit(viewModel)
                                  ? _submit
                                  : null,
                            ),
                            const SizedBox(height: 32),
                            // 하단 컨테이너(Fill)는 남은 공간을 채우고 내용은 아래에 붙입니다.
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: _SignupFooter(
                                  agreedToTerms: _agreedToTerms,
                                  onAgreedChanged: (value) =>
                                      setState(() => _agreedToTerms = value),
                                  onSubmit: _canSubmit(viewModel)
                                      ? _submit
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 환영합니다 — padding-bottom 16, 가운데 정렬 (W6-01)
/// - 환영합니다! Manrope 700 / 16
/// - 안내 문구 Manrope 400 / 14, 제목과 gap 10
class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Text(
            '환영합니다!',
            textAlign: TextAlign.center,
            style: AppTheme.signupWelcomeTitle,
          ),
          SizedBox(height: 10),
          Text(
            '간단한 정보만 입력하고 시작해보세요.',
            textAlign: TextAlign.center,
            style: AppTheme.signupWelcomeBody,
          ),
        ],
      ),
    );
  }
}

/// 입력창 묶음 — 닉네임·이메일·비밀번호, gap 16
class _SignupFields extends StatelessWidget {
  const _SignupFields({
    required this.viewModel,
    required this.nicknameController,
    required this.emailController,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.validateNickname,
    required this.validateEmail,
    required this.validatePassword,
    required this.onChanged,
    required this.onPasswordSubmitted,
  });

  final SignUpViewModel viewModel;
  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;
  final FieldValidator validateNickname;
  final FieldValidator validateEmail;
  final FieldValidator validatePassword;
  final VoidCallback onChanged;

  /// 비밀번호에서 키보드 완료를 눌렀을 때 실행합니다. null이면 아무 일도 하지 않습니다.
  final VoidCallback? onPasswordSubmitted;

  /// 입력 묶음 사이 간격 16 — 아래에 확인 중·사용 가능 문구가 있으면
  /// 문구 영역(6 + 16) 뒤 7만 띄워 W6-01처럼 다음 입력창 위치를 맞춥니다.
  static double _gapAfter(CheckStatus status) =>
      _DuplicateCheckRow.hasMessage(status) ? 7 : 16;

  /// 비어 있으면 suffixIcon 자리를 아예 만들지 않습니다. (W2-01)
  /// [serverErrorText]가 있으면 형식이 맞아도 오류 아이콘을 보여줍니다.
  Widget? _statusIcon(
    String value,
    FieldValidator validator, {
    String? serverErrorText,
  }) => value.isEmpty
      ? null
      : _StatusIcon(
          hasError: validator(value) != null || serverErrorText != null,
        );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step 3. 닉네임
        _LabeledField(
          label: '닉네임',
          child: _DuplicateCheckRow(
            status: viewModel.nicknameCheckStatus,
            checkingText: '닉네임 사용 가능 여부를 확인 중입니다.',
            availableText: '사용 가능한 닉네임입니다.',
            // 형식이 맞고 ViewModel이 허락할 때만 중복 확인을 누를 수 있습니다.
            onCheck:
                validateNickname(nicknameController.text) == null &&
                    viewModel.canCheckNickname
                ? () => viewModel.checkNickname(nicknameController.text)
                : null,
            field: TextFormField(
              controller: nicknameController,
              validator: validateNickname,
              onChanged: (value) {
                viewModel.onNicknameChanged(value);
                onChanged();
              },
              textInputAction: TextInputAction.next,
              style: textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: '닉네임을 입력해주세요',
                // validator가 통과해도 서버 중복이면 에러 상태로 보입니다.
                errorText: viewModel.nicknameErrorText,
                suffixIcon: _statusIcon(
                  nicknameController.text,
                  validateNickname,
                  serverErrorText: viewModel.nicknameErrorText,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: _gapAfter(viewModel.nicknameCheckStatus)),
        // 이메일
        _LabeledField(
          label: '이메일',
          child: _DuplicateCheckRow(
            status: viewModel.emailCheckStatus,
            checkingText: '이메일 사용 가능 여부를 확인 중입니다.',
            availableText: '사용 가능한 이메일입니다.',
            onCheck:
                validateEmail(emailController.text) == null &&
                    viewModel.canCheckEmail
                ? () => viewModel.checkEmail(emailController.text)
                : null,
            field: TextFormField(
              controller: emailController,
              validator: validateEmail,
              onChanged: (value) {
                viewModel.onEmailChanged(value);
                onChanged();
              },
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
              style: textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: '이메일 주소를 입력해주세요',
                errorText: viewModel.emailErrorText,
                suffixIcon: _statusIcon(
                  emailController.text,
                  validateEmail,
                  serverErrorText: viewModel.emailErrorText,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: _gapAfter(viewModel.emailCheckStatus)),
        // 비밀번호
        _LabeledField(
          label: '비밀번호',
          child: TextFormField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            validator: validatePassword,
            onChanged: (_) => onChanged(),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onPasswordSubmitted?.call(),
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: '비밀번호를 입력해주세요',
              suffixIcon: _statusIcon(
                passwordController.text,
                validatePassword,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 라벨(24px) + 입력창을 gap 4로 묶은 위젯입니다. (Figma: 356x70)
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

/// 입력창 오른쪽에 중복 확인 버튼을 나란히 두고, 아래에 확인 상태 문구를 붙입니다. (W6-01)
///
/// 버튼은 입력창 옆 좁은 자리라 width 없이 글자 길이만큼만 차지하고,
/// 입력창(Expanded)이 남은 너비를 씁니다. 입력창과 버튼 사이 10.
/// - 확인 중: [checkingText] #1565C0
/// - 사용 가능: [availableText] #2E7D32
/// - 중복·통신 실패는 입력창의 errorText(빨간 문구)로 보여줍니다.
class _DuplicateCheckRow extends StatelessWidget {
  const _DuplicateCheckRow({
    required this.field,
    required this.status,
    required this.checkingText,
    required this.availableText,
    required this.onCheck,
  });

  final Widget field;
  final CheckStatus status;
  final String checkingText;
  final String availableText;

  /// null이면 중복 확인 버튼이 비활성 상태로 그려집니다.
  final VoidCallback? onCheck;

  static bool hasMessage(CheckStatus status) =>
      status == CheckStatus.checking || status == CheckStatus.available;

  @override
  Widget build(BuildContext context) {
    final (message, color) = switch (status) {
      CheckStatus.checking => (checkingText, AppColors.checkInProgress),
      CheckStatus.available => (availableText, AppColors.checkAvailable),
      _ => (null, null),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          // 아래에 에러 문구가 붙어도 버튼은 입력창 높이에 맞춰 위에 둡니다.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field),
            const SizedBox(width: 10),
            MovieLogButton(
              label: '중복 확인',
              isLoading: status == CheckStatus.checking,
              onPressed: onCheck,
            ),
          ],
        ),
        if (message != null)
          // 입력창 아래 6, 문구 영역 높이 16, 왼쪽 1
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 1),
            child: SizedBox(
              height: 16,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message,
                  style: AppTheme.checkStatus.copyWith(color: color),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 입력 상태에 따라 오른쪽에 붙는 20x20 아이콘입니다.
/// 오류면 ! (W2-02), 통과하면 체크(W2-03)
class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.hasError});

  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      // 오른쪽 여백 12 (W6-01)
      padding: const EdgeInsets.only(right: 12),
      // 공통 에셋 SVG를 쓰고 colorFilter로 상태 색을 입힙니다.
      child: SvgPicture.asset(
        hasError
            ? 'assets/icons/error.svg'
            : 'assets/icons/check_circle_filled.svg',
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          hasError ? colors.error : colors.primary,
          BlendMode.srcIn,
        ),
        semanticsLabel: hasError ? '입력 오류' : '입력 확인',
      ),
    );
  }
}

/// 하단 컨테이너 — 약관 동의, 가입하기 버튼, 로그인 링크
/// padding-top 32, padding-bottom 16, gap 24
class _SignupFooter extends StatelessWidget {
  const _SignupFooter({
    required this.agreedToTerms,
    required this.onAgreedChanged,
    required this.onSubmit,
  });

  final bool agreedToTerms;
  final ValueChanged<bool> onAgreedChanged;

  /// null이면 가입하기 버튼이 비활성 상태로 그려집니다.
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Column(
        // 남은 공간을 채우지 않고 내용 높이만 차지해야 Align이 아래로 붙입니다.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 필수 약관 — 체크박스 26x26 + 텍스트(left 32)
          InkWell(
            onTap: () => onAgreedChanged(!agreedToTerms),
            borderRadius: BorderRadius.circular(AppTheme.checkboxRadius),
            child: Row(
              children: [
                SizedBox(
                  width: AppTheme.checkboxSize,
                  height: AppTheme.checkboxSize,
                  child: Checkbox(
                    value: agreedToTerms,
                    onChanged: (value) => onAgreedChanged(value ?? false),
                  ),
                ),
                const SizedBox(width: 32 - AppTheme.checkboxSize),
                const Text('필수 약관에 동의합니다', style: AppTheme.signupTerms),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 가입하기 — padding-bottom 16, 공용 버튼 전체 너비 (W6-01)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: MovieLogButton(
              label: '가입하기',
              width: double.infinity,
              onPressed: onSubmit,
            ),
          ),
          const SizedBox(height: 24),
          // 이미 계정이 있나요? 로그인 — gap 4
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '이미 계정이 있나요?',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {}, // 2주차에는 로그인 화면 이동을 연결하지 않습니다.
                child: Text(
                  '로그인',
                  style: textTheme.titleMedium?.copyWith(color: colors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
