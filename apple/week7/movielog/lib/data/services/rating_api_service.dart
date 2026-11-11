import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

/// v6 회원별 평점 API를 호출합니다.
///
/// | 동작 | 요청                                         | 성공                  |
/// | ---- | -------------------------------------------- | --------------------- |
/// | 조회 | GET    /v6/members/{memberId}/ratings            | 200 + 직접 배열       |
/// | 등록 | POST   /v6/members/{memberId}/ratings            | 201 + 공통 형식       |
/// | 수정 | PATCH  /v6/members/{memberId}/ratings/{ratingId} | 200 + result null     |
/// | 삭제 | DELETE /v6/members/{memberId}/ratings/{ratingId} | 204 + body 없음       |
///
/// 실패는 v6 공통 형식이며 DioException 그대로 ViewModel로 넘깁니다.
class RatingApiService {
  RatingApiService(this._dio);

  final Dio _dio;

  /// 평점이 하나도 없으면 빈 목록을 돌려줍니다. 성공 응답은 공통 형식이 아닌 배열 그대로입니다.
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v6/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 평점 등록 — 201만 성공으로 봅니다.
  ///
  /// Swagger 설명은 result가 ratingId 숫자라고 하지만 같은 schema의 예시는 null이라
  /// 계약이 확정되기 전에는 result를 파싱하지 않고, 성공 뒤 목록을 다시 조회해 확인합니다.
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    if (response.statusCode != 201) {
      throw StateError('예상하지 못한 등록 응답: ${response.statusCode}');
    }
  }

  /// 평점 수정 — comment를 생략하면 기존 후기가 null로 덮이므로 항상 명시적으로 보냅니다.
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    await _dio.patch(
      '/v6/members/$memberId/ratings/$ratingId',
      data: UpdateRatingRequest(score: score, comment: comment).toJson(),
    );
  }

  /// 평점 삭제 — 204는 body가 없으므로 JSON으로 파싱하지 않고 상태 코드만 확인합니다.
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _dio.delete(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    if (response.statusCode != 204) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

/// 평점 조회 실패를 상태 코드별 안내 문구로 바꿉니다.
/// - 400: memberId 형식 오류
/// - 404: 존재하지 않는 유저
/// - 그 외(통신 실패, 5xx 등): 잠시 후 다시 시도
String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 평점 쓰기(등록·수정·삭제) 실패 문구 — 서버 `message`를 그대로 씁니다.
///
/// 같은 COMMON404라도 등록은 "유저", 수정·삭제는 "평점"을 가리키므로
/// code만 보고 문구를 새로 만들지 않습니다.
String writeErrorMessage(DioException error) {
  return CommonResponse.tryParseError(error.response?.data)?.message ??
      '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 쓰기 실패 뒤 목록을 다시 조회할지 정합니다. code는 문구가 아니라 다음 UI 행동에만 씁니다.
///
/// - 403·404: 화면에 남은 목록이 서버 상태와 어긋났다는 뜻이므로 다시 조회합니다.
/// - 400(별점 범위)·409(중복 등록): 값만 고쳐 다시 시도하면 되므로 다시 조회하지 않습니다.
bool shouldRefreshAfterRatingError(DioException error) {
  final code = CommonResponse.tryParseError(error.response?.data)?.code;
  return code == 'COMMON403' || code == 'COMMON404';
}
