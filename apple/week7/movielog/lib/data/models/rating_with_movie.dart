import 'rating_dto.dart';
import 'tmdb_movie_detail_dto.dart';

/// 자체 서버의 평점 하나와, 그 movieId로 TMDB에서 찾은 영화 정보를 한 쌍으로 묶습니다.
///
/// 평점은 자체 서버가 진짜 주인이므로 영화 정보를 찾지 못해도 평점은 남깁니다.
class RatingWithMovie {
  const RatingWithMovie({required this.rating, this.movie});

  final RatingDto rating;

  /// TMDB에서 찾지 못했거나 불러오지 못했으면 null — 화면은 제목·포스터를 placeholder로 표시합니다.
  final TmdbMovieDetailDto? movie;
}
