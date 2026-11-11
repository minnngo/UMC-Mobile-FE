import 'package:flutter/foundation.dart';

/// 회원가입으로 얻은 학습용 memberId를 앱 전체에서 함께 읽는 상태입니다.
///
/// 영화 상세(평점 등록)와 마이페이지(조회·수정·삭제)가 같은 값을 써서,
/// 6주차 고정 memberId 1(다른 회원의 path)로 요청하지 않게 합니다.
///
/// - 메모리에만 있으므로 앱을 재시작하면 사라집니다. (SharedPreferences에 저장하지 않음)
/// - memberId만 알고 있다는 사실은 인증이 아닙니다. JWT 주차에는 path의 memberId를 없애고
///   서버가 토큰으로 현재 회원을 식별하도록 바꿉니다.
class LearningMemberSession extends ChangeNotifier {
  int? _memberId;

  /// 아직 학습용 회원가입을 하지 않았으면 null
  int? get memberId => _memberId;

  void setMemberId(int id) {
    _memberId = id;
    notifyListeners();
  }

  void clear() {
    _memberId = null;
    notifyListeners();
  }
}
