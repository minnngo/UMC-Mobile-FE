/// v6 닉네임·이메일 중복 체크 API의 성공 응답입니다. 예) { "available": true }
///
/// 성공 응답은 공통 형식(CommonResponse)이 아닌 직접 객체라 body를 그대로 [CheckResult.fromJson]에 넘깁니다.
/// 오류 응답만 공통 형식이므로 회원가입 POST의 `result` 파싱과 구분합니다.
class CheckResult {
  const CheckResult({required this.available});

  /// 사용할 수 있는 값이면 true, 이미 사용 중이면 false
  final bool available;

  factory CheckResult.fromJson(Map<String, dynamic> json) {
    return CheckResult(available: json['available'] as bool);
  }
}
