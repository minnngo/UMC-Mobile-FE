/// 쓰기 요청(회원가입·평점 등록) 한 번의 진행 상태입니다.
///
/// 조회 상태(loading/empty/success/error)와 분리해,
/// "저장 실패"와 "저장 후 목록 재조회 실패"를 섞지 않습니다.
enum SubmitStatus { idle, submitting, success, error }

/// 쓰기 요청이 실패했을 때 Dialog에 그대로 보여줄 문구를 담아 던지는 예외입니다.
///
/// ViewModel이 DioException을 서버 message로 바꿔 던지므로,
/// Dialog(화면)는 Dio를 몰라도 실패 문구를 표시할 수 있습니다.
class WriteFailure implements Exception {
  const WriteFailure(this.message);

  final String message;

  @override
  String toString() => 'WriteFailure: $message';
}
