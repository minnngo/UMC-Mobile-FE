/// 회원가입 요청 body — POST /v6/members
///
/// 서버 제약 (클라이언트 검증은 빠른 안내용이며 서버 검증을 대체하지 않습니다)
/// - email: 올바른 이메일 형식
/// - nickname: 2~12자
/// - password: 8자 이상, 소문자·대문자·숫자·특수문자(!@#$%^&*)를 각각 하나 이상
class CreateMemberRequest {
  const CreateMemberRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });

  final String email;
  final String password;
  final String nickname;

  /// Dart 객체 → 요청 JSON
  ///
  /// 비밀번호는 입력한 문자 그대로가 의미 있으므로 trim()하지 않습니다.
  /// 앞뒤 공백 허용 여부는 Form validation에서 처리합니다.
  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
    'nickname': nickname.trim(),
  };

  /// 비밀번호가 로그에 찍히지 않도록 toString에서 가립니다.
  @override
  String toString() =>
      'CreateMemberRequest(email: $email, nickname: $nickname, password: ***)';
}
