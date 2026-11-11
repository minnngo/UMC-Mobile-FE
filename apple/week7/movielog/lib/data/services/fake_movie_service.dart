import '../../models/movie.dart';
import '../mock/movie_mock_data.dart';

/// Mock 응답 시나리오 — 화면에서 성공·빈 목록·실패 상태를 각각 확인하기 위해 사용합니다.
enum MovieLoadMode { success, empty, failure }

class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;
}

/// 3주차 Mock Data를 1초 뒤에 돌려주는 가짜 서비스입니다.
/// 5주차부터 앱은 실제 API를 호출하고,
/// 이 서비스는 서버 없이 화면 상태(로딩·빈 목록·실패)를 확인하는 테스트에서 사용합니다.
class FakeMovieService {
  const FakeMovieService();

  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));

    return switch (mode) {
      MovieLoadMode.success => movies,
      MovieLoadMode.empty => const <Movie>[],
      MovieLoadMode.failure => throw const MovieLoadException(
        '영화를 불러오지 못했습니다.',
      ),
    };
  }
}
