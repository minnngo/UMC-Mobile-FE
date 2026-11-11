import 'package:dio/dio.dart';

import 'package:movielog/data/mock/movie_mock_data.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/models/movie.dart';

/// 테스트용 TMDB 장르 — Mock 영화에 쓰인 장르만 실제 TMDB id로 둡니다.
const fakeTmdbGenres = {
  18: '드라마',
  878: 'SF',
  16: '애니메이션',
  53: '스릴러',
  10749: '로맨스',
  99: '다큐멘터리',
  28: '액션',
};

/// Mock 영화를 TMDB 응답 모양으로 바꿉니다.
/// id·제목을 Mock과 같게 두어 목록·홈 → 상세 이동을 기존 Mock 상세로 확인할 수 있습니다.
/// 평점은 TMDB처럼 10점 만점, 포스터는 placeholder 확인을 위해 null입니다.
List<Map<String, Object?>> _toTmdbJson(List<Movie> mockMovies) => [
  for (final movie in mockMovies)
    {
      'id': movie.id,
      'title': movie.title,
      'overview': '',
      'poster_path': null,
      'release_date': '${movie.year}-01-01',
      'genre_ids': [
        fakeTmdbGenres.entries.firstWhere((e) => e.value == movie.genre).key,
      ],
      'vote_average': movie.rating * 2,
      'popularity': 100.0,
    },
];

/// Discover 응답 — 영화 목록 Mock 6개
final fakeTmdbMovies = _toTmdbJson(movies);

/// Popular 응답 — 홈 인기 영화 Mock 3개 (마션 레스큐 id 7 …)
final fakeTmdbPopularMovies = _toTmdbJson(popularMovies);

/// 서버 없이 TMDB 응답을 흉내 내는 [TmdbMovieService]를 만듭니다.
///
/// - /genre/movie/list → [fakeTmdbGenres]
/// - /discover/movie → [results]를 with_genres로 거른 뒤 20개씩 페이지로 나눔
/// - /movie/popular → [popularResults]를 20개씩 페이지로 나눔
/// - /movie/{id} → 같은 id의 Mock 상세(없는 id면 404)
/// - [resultsBuilder]가 있으면 요청할 때마다 Discover 결과를 새로 받음 (새로고침 확인용)
/// - [fail]이 true면 모든 요청이 연결 오류(DioException)
/// - [delay]만큼 늦게 응답 — Loading 상태 확인용
/// - [requests]에 보낸 요청 URL을 순서대로 기록
TmdbMovieService fakeTmdbService({
  List<Map<String, Object?>>? results,
  List<Map<String, Object?>> Function()? resultsBuilder,
  List<Map<String, Object?>>? popularResults,
  bool Function()? fail,
  Duration delay = Duration.zero,
  List<Uri>? requests,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.themoviedb.org/3'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          requests?.add(options.uri);
          await Future<void>.delayed(delay);

          if (fail?.call() ?? false) {
            return handler.reject(
              DioException.connectionError(
                requestOptions: options,
                reason: '테스트용 연결 실패',
              ),
            );
          }

          final detailMatch = RegExp(r'^/movie/(\d+)$')
              .firstMatch(options.path);
          if (detailMatch != null) {
            final detail = _movieDetailJson(int.parse(detailMatch.group(1)!));
            if (detail == null) {
              return handler.reject(
                DioException.badResponse(
                  statusCode: 404,
                  requestOptions: options,
                  response: Response(requestOptions: options, statusCode: 404),
                ),
              );
            }
            return handler.resolve(
              Response(requestOptions: options, statusCode: 200, data: detail),
            );
          }

          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: _respond(
                options,
                options.path == '/movie/popular'
                    ? popularResults ?? fakeTmdbPopularMovies
                    : resultsBuilder?.call() ?? results ?? fakeTmdbMovies,
              ),
            ),
          );
        },
      ),
    );
  return TmdbMovieService(dio);
}

/// Mock 상세를 TMDB 상세 응답 모양으로 바꿉니다. 시놉시스 문단은 줄바꿈으로 잇습니다.
Map<String, Object?>? _movieDetailJson(int id) {
  final detail = findMovieDetailById(id);
  if (detail == null) return null;
  return {
    'id': id,
    'title': detail.title,
    'overview': detail.synopsis.join('\n\n'),
    'poster_path': null,
    'release_date': '${detail.year}-01-01',
    'genres': [
      for (final name in detail.genres)
        {
          'id': fakeTmdbGenres.entries.firstWhere((e) => e.value == name).key,
          'name': name,
        },
    ],
    'runtime': detail.runtimeMinutes,
    'vote_average': detail.rating * 2,
    'vote_count': detail.reviewCount ?? 0,
  };
}

Map<String, Object?> _respond(
  RequestOptions options,
  List<Map<String, Object?>> all,
) {
  if (options.path == '/genre/movie/list') {
    return {
      'genres': [
        for (final MapEntry(:key, :value) in fakeTmdbGenres.entries)
          {'id': key, 'name': value},
      ],
    };
  }

  const pageSize = 20;
  final genreId = options.queryParameters['with_genres'] as int?;
  final page = options.queryParameters['page'] as int? ?? 1;
  final filtered = genreId == null
      ? all
      : all
            .where((movie) => (movie['genre_ids'] as List).contains(genreId))
            .toList();
  final totalPages = (filtered.length / pageSize).ceil().clamp(1, 500);

  return {
    'page': page,
    'results': filtered.skip((page - 1) * pageSize).take(pageSize).toList(),
    'total_pages': totalPages,
    'total_results': filtered.length,
  };
}
