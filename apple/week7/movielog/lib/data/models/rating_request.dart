/// 별점 입력 위젯이 돌려준 double을 서버 score(1~5 정수)로 바꿉니다.
///
/// 입력 위젯이 이미 정수 단위로 막아 주지만, 반 점이 들어오면 조용히 toInt()하지 않고
/// 오류로 알리는 안전장치입니다.
int validateServerScore(double value) {
  if (value < 1 || value > 5 || value != value.roundToDouble()) {
    throw ArgumentError('서버 평점은 1~5 사이 정수여야 합니다.');
  }
  return value.toInt();
}

/// 평점 등록 요청 body — POST /v6/members/{memberId}/ratings
class CreateRatingRequest {
  const CreateRatingRequest({
    required this.movieId,
    required this.score,
    this.comment,
  });

  /// TMDB 영화 id (`TmdbMovieDto.id`) — 배열 index나 임의 번호가 아닙니다.
  final int movieId;
  final int score;
  final String? comment;

  /// comment는 선택 항목이라 비어 있으면 빈 문자열 대신 아예 생략합니다. (collection if)
  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'score': score,
    if (comment != null && comment!.trim().isNotEmpty)
      'comment': comment!.trim(),
  };
}

/// 평점 수정 요청 body — PATCH /v6/members/{memberId}/ratings/{ratingId}
///
/// PATCH지만 score는 필수입니다. comment를 생략하면 기존 후기가 null로 덮이는 계약이므로
/// 후기를 유지하려면 기존 값을 그대로 보내고, 지우려면 null을 명시적으로 보냅니다.
class UpdateRatingRequest {
  const UpdateRatingRequest({required this.score, this.comment});

  final int score;
  final String? comment;

  Map<String, dynamic> toJson() => {'score': score, 'comment': comment};
}
