/// v6 공통 응답 형식입니다. 신규 쓰기 API의 성공 응답과 모든 v6 오류 응답이 이 모양입니다.
///
/// 예) 성공 { "isSuccess": true,  "code": "COMMON201", "message": "...", "result": { ... } }
///     실패 { "isSuccess": false, "code": "COMMON409", "message": "이미 사용 중인 이메일입니다.", "result": null }
///
/// - [result]는 API마다 담기는 값이 달라 제네릭 [T]로 받습니다.
/// - 값이 없거나 실패 응답이면 [result]는 null입니다.
///
/// 닉네임·이메일 중복 확인과 회원별 평점 조회는 성공 시 v5처럼 직접 객체/배열을 돌려주므로
/// 이 형식으로 파싱하지 않습니다. 오류일 때만 이 형식입니다.
class CommonResponse<T> {
  const CommonResponse({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
  });

  final bool isSuccess;

  /// 처리 결과 code (예: COMMON201, COMMON404) — 다음 UI 행동을 정할 때 씁니다.
  final String code;

  /// 사용자에게 그대로 보여줄 수 있는 안내 문구
  final String message;

  final T? result;

  /// [parseResult]는 `result`가 null이 아닐 때만 호출합니다.
  factory CommonResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parseResult,
  ) {
    final rawResult = json['result'];
    return CommonResponse<T>(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: rawResult == null ? null : parseResult(rawResult),
    );
  }

  /// 오류 응답 body가 공통 형식이면 파싱하고, 아니면(연결 실패, HTML 오류 등) null을 돌려줍니다.
  static CommonResponse<Object?>? tryParseError(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    try {
      return CommonResponse<Object?>.fromJson(data, (value) => value);
    } catch (_) {
      return null;
    }
  }
}
