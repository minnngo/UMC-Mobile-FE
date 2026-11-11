import 'tmdb_genre_dto.dart';

/// TMDB 영화 상세 응답(GET /movie/{movie_id})입니다.
/// 목록 응답([TmdbMovieDto])과 달리 장르 이름, 러닝타임, 평점 참여 수가 함께 옵니다.
class TmdbMovieDetailDto {
  const TmdbMovieDetailDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.releaseDate,
    required this.genres,
    required this.runtime,
    required this.voteAverage,
    required this.voteCount,
  });

  final int id;
  final String title;

  /// 한국어 번역이 없으면 빈 문자열로 옵니다.
  final String overview;
  final String? posterPath;
  final String? releaseDate;
  final List<TmdbGenreDto> genres;

  /// 분 단위 — 정보가 없으면 null 또는 0으로 옵니다.
  final int? runtime;
  final double voteAverage;
  final int voteCount;

  factory TmdbMovieDetailDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieDetailDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '제목 없음',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      releaseDate: json['release_date'] as String?,
      genres: (json['genres'] as List<dynamic>? ?? const [])
          .map((item) => TmdbGenreDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      runtime: (json['runtime'] as num?)?.toInt(),
      voteAverage: (json['vote_average'] as num? ?? 0).toDouble(),
      voteCount: (json['vote_count'] as num? ?? 0).toInt(),
    );
  }
}
