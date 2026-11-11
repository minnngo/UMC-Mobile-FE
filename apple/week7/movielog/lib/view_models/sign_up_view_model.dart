import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/create_member_request.dart';
import '../data/services/sign_up_service.dart';
import 'submit_status.dart';

export 'submit_status.dart';

/// 중복 확인 한 칸의 상태입니다. 버튼 활성화와 Form 에러 문구가 모두 이 값에서 나옵니다.
enum CheckStatus {
  /// 아직 확인하지 않았거나, 입력이 바뀌어 이전 결과가 무효화된 상태
  idle,

  /// 요청 진행 중
  checking,

  /// 서버가 사용 가능하다고 응답
  available,

  /// 서버가 이미 사용 중이라고 응답 (available: false)
  duplicated,

  /// 통신 자체가 실패
  error,
}

/// 회원가입 화면의 닉네임·이메일 중복 확인과 가입 제출 상태를 관리합니다.
///
/// 두 입력란은 상태·요청 버전·현재 입력값을 따로 관리해 결과가 서로 섞이지 않게 합니다.
/// 입력이 바뀌면 기다리던 이전 응답은 무시합니다.
///
/// 이전에 중복으로 확인한 값을 다시 입력하면 API 없이 바로 중복으로 표시합니다.
/// 서버 상태는 그 사이 바뀔 수 있으므로 최종 기준은 회원가입 POST의 409입니다.
///
/// 7주차 — [submit]이 POST /v6/members를 보내고, 성공하면 [createdMemberId]에
/// 응답 result의 memberId를 담습니다. 세션 저장은 화면이 합니다.
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);

  final SignUpService _service;

  static const _duplicatedNicknameText = '이미 사용 중인 닉네임입니다.';
  static const _duplicatedEmailText = '이미 사용 중인 이메일입니다.';
  static const _checkFailedText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';

  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // 닉네임
  // ---------------------------------------------------------------------------

  CheckStatus nicknameCheckStatus = CheckStatus.idle;
  String? nicknameErrorText;
  String? _duplicatedNickname;
  String _currentNickname = '';
  int _nicknameRequestVersion = 0;

  /// 요청 중이거나 이미 중복으로 확인된 값이면 중복 확인 버튼을 끕니다.
  bool get canCheckNickname =>
      nicknameCheckStatus != CheckStatus.checking &&
      nicknameCheckStatus != CheckStatus.duplicated;

  void onNicknameChanged(String value) {
    final trimmed = value.trim();
    _currentNickname = trimmed;
    _nicknameRequestVersion++; // 이전 요청의 응답을 무효화합니다.
    if (_duplicatedNickname != null && trimmed == _duplicatedNickname) {
      nicknameCheckStatus = CheckStatus.duplicated;
      nicknameErrorText = _duplicatedNicknameText;
    } else {
      nicknameCheckStatus = CheckStatus.idle;
      nicknameErrorText = null;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> checkNickname(String value) async {
    final requested = value.trim();
    if (requested.isEmpty ||
        requested != _currentNickname ||
        !canCheckNickname) {
      return;
    }

    final version = ++_nicknameRequestVersion;
    nicknameCheckStatus = CheckStatus.checking;
    nicknameErrorText = null;
    notifyListeners();

    // 응답을 기다리는 사이 화면이 닫혔거나 입력이 바뀌었으면 결과를 버립니다.
    bool isStale() =>
        _disposed ||
        version != _nicknameRequestVersion ||
        _currentNickname != requested;

    try {
      final available = await _service.checkNickname(requested);
      if (isStale()) return;
      nicknameCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated;
      nicknameErrorText = available ? null : _duplicatedNicknameText;
      if (!available) _duplicatedNickname = requested;
    } catch (_) {
      // 통신 실패(DioException)뿐 아니라 응답 모양이 예상과 달라도
      // checking에 멈추지 않도록 error로 바꿉니다.
      if (isStale()) return;
      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = _checkFailedText;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 이메일 — 닉네임과 같은 구조, 상태는 따로
  // ---------------------------------------------------------------------------

  CheckStatus emailCheckStatus = CheckStatus.idle;
  String? emailErrorText;
  String? _duplicatedEmail;
  String _currentEmail = '';
  int _emailRequestVersion = 0;

  bool get canCheckEmail =>
      emailCheckStatus != CheckStatus.checking &&
      emailCheckStatus != CheckStatus.duplicated;

  void onEmailChanged(String value) {
    final trimmed = value.trim();
    _currentEmail = trimmed;
    _emailRequestVersion++;
    if (_duplicatedEmail != null && trimmed == _duplicatedEmail) {
      emailCheckStatus = CheckStatus.duplicated;
      emailErrorText = _duplicatedEmailText;
    } else {
      emailCheckStatus = CheckStatus.idle;
      emailErrorText = null;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> checkEmail(String value) async {
    final requested = value.trim();
    if (requested.isEmpty || requested != _currentEmail || !canCheckEmail) {
      return;
    }

    final version = ++_emailRequestVersion;
    emailCheckStatus = CheckStatus.checking;
    emailErrorText = null;
    notifyListeners();

    bool isStale() =>
        _disposed ||
        version != _emailRequestVersion ||
        _currentEmail != requested;

    try {
      final available = await _service.checkEmail(requested);
      if (isStale()) return;
      emailCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated;
      emailErrorText = available ? null : _duplicatedEmailText;
      if (!available) _duplicatedEmail = requested;
    } catch (_) {
      if (isStale()) return;
      emailCheckStatus = CheckStatus.error;
      emailErrorText = _checkFailedText;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 회원가입 제출 (POST /v6/members)
  // ---------------------------------------------------------------------------

  SubmitStatus submitStatus = SubmitStatus.idle;

  /// 가입 성공 응답의 result에서 읽은 실제 memberId
  int? createdMemberId;

  /// 400 중 비밀번호 형식 위반 — 비밀번호 입력칸에 붙이는 필드 단위 오류
  String? passwordErrorText;

  /// 409 중복 등 어느 입력칸에도 붙일 수 없는 화면 단위 오류 — Snackbar로 한 번 보여줍니다.
  String? snackbarMessage;

  bool get isSubmitting => submitStatus == SubmitStatus.submitting;

  /// 비밀번호를 고치면 이전 서버 오류를 지웁니다.
  void onPasswordChanged() {
    if (passwordErrorText == null) return;
    passwordErrorText = null;
    if (!_disposed) notifyListeners();
  }

  Future<void> submit(CreateMemberRequest request) async {
    if (isSubmitting) return; // 중복 탭 방지
    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();

    try {
      final response = await _service.signUp(request);
      final id = response.result?.memberId;
      // memberId가 없으면 가입 완료로 표시하지 않고 계약 오류로 처리합니다.
      if (id == null) throw StateError('회원가입 결과에 memberId가 없습니다.');
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      submitStatus = SubmitStatus.error;
      final message = writeSignUpErrorMessage(error);
      // 400이라도 비밀번호 문구일 때만 입력칸에 붙이고, 그 밖의 400·409는 Snackbar로 보여줍니다.
      if (error.response?.statusCode == 400 && message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
      }
    } catch (_) {
      // 201은 왔지만 응답 모양이 계약과 다름 — 서버에는 이미 가입됐을 수 있습니다.
      submitStatus = SubmitStatus.error;
      snackbarMessage = '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nicknameRequestVersion++;
    _emailRequestVersion++;
    super.dispose();
  }
}
