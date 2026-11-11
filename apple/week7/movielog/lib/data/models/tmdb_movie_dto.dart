/// TMDB Popular·Discover 응답의 영화 한 편입니다.
/// JSON은 snake_case(poster_path), Dart는 lowerCamelCase(posterPath)라 key를 직접 연결합니다.
class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.genreIds,
    required this.voteAverage,
    required this.popularity,
  });

  /// TMDB 영화 ID — 평점 저장 시 자체 API의 movieId로 그대로 사용합니다.
  final int id;
  final String title;

  /// 한국어 번역이 없으면 빈 문자열로 옵니다.
  final String overview;

  /// null이면 화면에서 placeholder를 보여줍니다.
  final String? posterPath;
  final String? backdropPath;

  /// 예) 2024-05-01 — null이면 출시 연도를 표시하지 않습니다.
  final String? releaseDate;
  final List<int> genreIds;
  final double voteAverage;
  final double popularity;

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '제목 없음',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String?,
      genreIds: (json['genre_ids'] as List<dynamic>? ?? const [])
          .map((value) => (value as num).toInt())
          .toList(),
      voteAverage: (json['vote_average'] as num? ?? 0).toDouble(),
      popularity: (json['popularity'] as num? ?? 0).toDouble(),
    );
  }
}
