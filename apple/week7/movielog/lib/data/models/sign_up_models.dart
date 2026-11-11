/// 회원가입 성공 응답의 `result` payload입니다.
///
/// 응답 전체는 `CommonResponse<SignUpResult>`로 한 번만 파싱하고,
/// `response.result?.memberId`가 null이면 가입 완료로 표시하지 않고 계약 오류로 처리합니다.
class SignUpResult {
  const SignUpResult({
    required this.memberId,
    required this.email,
    required this.nickname,
  });

  /// v6 평점 path에 쓰는 학습용 식별자 — 이 값만 알고 있다고 인증된 것은 아닙니다.
  final int memberId;
  final String email;
  final String nickname;

  /// 서버 응답 JSON → Dart 객체
  factory SignUpResult.fromJson(Map<String, dynamic> json) {
    return SignUpResult(
      memberId: (json['memberId'] as num).toInt(),
      email: json['email'] as String,
      nickname: json['nickname'] as String,
    );
  }
}
