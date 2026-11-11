import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_detail_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

/// "내가 등록한 평점"의 조회 대상 — 인증된 '내 계정'이 아닌 학습용 데이터입니다.
/// 로그인이 없어 memberId 1로 고정하고, 실제 회원 식별은 JWT 주차에서 바뀝니다.
const int sampleMemberId = 1;

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

/// 내가 등록한 평점 화면의 상태 — 자체 서버 평점 목록에 TMDB 영화 정보를 붙입니다.
///
/// - 평점 조회가 실패하면 error, 결과가 없으면 empty입니다.
/// - TMDB 영화 조회가 실패해도 평점은 그대로 두고 영화 정보만 비웁니다.
/// - 같은 movieId는 한 번만 조회해 캐시합니다. 일시적인 실패는 캐시하지 않아 다음 로딩에서 다시 시도합니다.
/// - 화면을 벗어났거나 새 요청이 시작된 뒤 도착한 이전 응답은 무시합니다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;

  /// movieId → TMDB 영화 (404로 없는 영화면 null을 저장)
  final Map<int, TmdbMovieDetailDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;

  /// error면 실패 안내, success면 일부 영화 정보를 못 찾았다는 안내 (없으면 null)
  String? message;

  static const _loadFailedText = '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
  static const _missingMoviesText = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';

  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (_disposed || version != _requestVersion) return;

      // 캐시에 없는 영화만 한꺼번에 조회합니다. 하나가 실패해도 나머지 평점은 지우지 않습니다.
      final uncachedIds = {
        for (final rating in rawRatings)
          if (!_movieCache.containsKey(rating.movieId)) rating.movieId,
      };
      await Future.wait(uncachedIds.map(_cacheMovie));
      if (_disposed || version != _requestVersion) return;

      final entries = [
        for (final rating in rawRatings)
          RatingWithMovie(rating: rating, movie: _movieCache[rating.movieId]),
      ];
      ratings = entries;
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (entries.any((entry) => entry.movie == null)) {
        message = _missingMoviesText;
      }
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    } catch (_) {
      // 응답 모양이 예상과 달라도 loading에 멈추지 않도록 error로 바꿉니다.
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = _loadFailedText;
    }
    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  /// TMDB에서 영화를 찾아 캐시에 넣습니다. 없는 영화(404)는 null로 캐시하고,
  /// 그 밖의 실패는 캐시하지 않아 다음 로딩에서 다시 시도합니다.
  Future<void> _cacheMovie(int movieId) async {
    try {
      _movieCache[movieId] = await _movieService.findMovieById(movieId);
    } catch (_) {
      // 영화 정보만 placeholder로 표시합니다.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
