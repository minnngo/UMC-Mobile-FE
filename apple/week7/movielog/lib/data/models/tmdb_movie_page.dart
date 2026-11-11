import 'tmdb_movie_dto.dart';

/// Popular·Discover의 페이지 응답입니다.
/// 영화 배열과 함께 page·total_pages를 담아 다음 페이지 요청 여부를 판단합니다.
class TmdbMoviePageDto {
  const TmdbMoviePageDto({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  final int page;
  final List<TmdbMovieDto> results;
  final int totalPages;

  /// 전체 탐색 결과 개수 — 이만큼 모두 내려받는다는 뜻은 아닙니다.
  final int totalResults;

  factory TmdbMoviePageDto.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];

    return TmdbMoviePageDto(
      page: (json['page'] as num).toInt(),
      results: rawResults
          .map((item) => TmdbMovieDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalPages: (json['total_pages'] as num).toInt(),
      totalResults: (json['total_results'] as num).toInt(),
    );
  }
}
