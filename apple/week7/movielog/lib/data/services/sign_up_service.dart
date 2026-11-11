import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

/// 회원가입 관련 v6 API를 호출합니다. (6주차 MemberCheckService에서 이름을 바꿈)
/// - GET  /v6/members/nickname/{nickname} — 성공은 직접 객체 { "available": true }
/// - GET  /v6/members/email/{email}       — 성공은 직접 객체
/// - POST /v6/members                     — 성공은 201 + `CommonResponse<SignUpResult>`
///
/// 오류는 모두 v6 공통 형식이며, DioException 그대로 ViewModel로 넘깁니다.
class SignUpService {
  SignUpService(this._dio);

  final Dio _dio;

  /// 사용할 수 있는 닉네임이면 true
  Future<bool> checkNickname(String nickname) async {
    // 한글·특수문자가 경로를 깨뜨리지 않도록 인코딩합니다.
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v6/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  /// 사용할 수 있는 이메일이면 true
  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v6/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  /// 회원가입 — 요청 body는 [CreateMemberRequest.toJson],
  /// 응답은 공통 형식을 한 번 파싱한 뒤 `result`에서 [SignUpResult]를 읽습니다.
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post('/v6/members', data: request.toJson());

    return CommonResponse<SignUpResult>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
  }
}

/// 회원가입 실패(400 비밀번호 형식, 409 이메일·닉네임 중복)는 서버 `message`가
/// 이미 사용자에게 보여줄 문장이므로 그대로 씁니다. 공통 형식이 아니면 기본 문구입니다.
String writeSignUpErrorMessage(DioException error) {
  return CommonResponse.tryParseError(error.response?.data)?.message ??
      '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}
