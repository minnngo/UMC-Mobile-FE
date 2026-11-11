import 'movie.dart';

/// W3-03 영화 상세 화면에 표시할 정보입니다.
/// Mock 영화는 Mock 상세 데이터나 [Movie] 기본 정보로, TMDB 영화는 상세 API 응답으로 만듭니다.
class MovieDetail {
  const MovieDetail({
    required this.title,
    this.heroAsset,
    this.posterPath,
    required this.year,
    required this.genres,
    required this.rating,
    this.runtimeMinutes,
    this.reviewCount,
    this.tags = const [],
    this.synopsis = const [],
  });

  /// 상세 내용이 없는 영화는 목록 정보만으로 상세 화면을 구성합니다.
  MovieDetail.fromMovie(Movie movie)
    : title = movie.title,
      heroAsset = movie.posterAsset,
      posterPath = null,
      year = movie.year,
      genres = [movie.genre],
      rating = movie.rating,
      runtimeMinutes = null,
      reviewCount = null,
      tags = [movie.genre],
      synopsis = const [];

  final String title;

  /// 상단 히어로 이미지 에셋 (2:3으로 잘라 표시) — Mock 영화
  final String? heroAsset;

  /// 상단 히어로 이미지의 TMDB poster_path — TMDB 영화
  final String? posterPath;

  /// 개봉 연도 — 개봉일 정보가 없으면 null이고 표시하지 않습니다.
  final int? year;
  final List<String> genres;
  final double rating;
  final int? runtimeMinutes;

  /// 별점 참여 수 — 예: (1,245)
  final int? reviewCount;

  /// 장르 칩 — 예: 로맨스, 드라마, 감동적인
  final List<String> tags;

  /// 시놉시스 문단
  final List<String> synopsis;
}
