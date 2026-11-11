/// v6 회원별 평점 조회 API(GET /v6/members/{memberId}/ratings) 응답 배열의 항목 하나입니다.
///
/// 영화 제목·포스터는 없으므로 [movieId]로 TMDB 영화와 연결합니다.
///
/// 예) { "ratingId": 12, "movieId": 550, "score": 5, "comment": "최고의 영화!",
///       "createdAt": "2026-09-06T12:14:03.000Z", ... }
class RatingDto {
  const RatingDto({
    required this.ratingId,
    required this.movieId,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  final int ratingId;

  /// TMDB 영화 id 그대로입니다.
  final int movieId;
  final int score;

  /// 명세에서 nullable: true — 한줄평 없이 점수만 남긴 평점이면 null입니다.
  final String? comment;
  final DateTime createdAt;

  factory RatingDto.fromJson(Map<String, dynamic> json) => RatingDto(
    ratingId: (json['ratingId'] as num).toInt(),
    movieId: (json['movieId'] as num).toInt(),
    score: (json['score'] as num).toInt(),
    comment: json['comment'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
