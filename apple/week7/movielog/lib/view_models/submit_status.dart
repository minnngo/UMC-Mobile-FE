/// 쓰기 요청(회원가입·평점 등록) 한 번의 진행 상태입니다.
///
/// 조회 상태(loading/empty/success/error)와 분리해,
/// "저장 실패"와 "저장 후 목록 재조회 실패"를 섞지 않습니다.
enum SubmitStatus { idle, submitting, success, error }
