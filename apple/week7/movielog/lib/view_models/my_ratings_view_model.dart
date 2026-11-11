import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_detail_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'submit_status.dart';

export 'submit_status.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

/// 내가 등록한 평점 화면의 상태 — 자체 서버 평점 목록에 TMDB 영화 정보를 붙입니다.
///
/// - 평점 조회가 실패하면 error, 결과가 없으면 empty입니다.
/// - TMDB 영화 조회가 실패해도 평점은 그대로 두고 영화 정보만 비웁니다.
/// - 같은 movieId는 한 번만 조회해 캐시합니다. 일시적인 실패는 캐시하지 않아 다음 로딩에서 다시 시도합니다.
/// - 화면을 벗어났거나 새 요청이 시작된 뒤 도착한 이전 응답은 무시합니다.
///
/// [memberId]는 회원가입으로 얻은 학습용 ID입니다(LearningMemberSession).
/// 인증된 '내 계정'은 아니며, 실제 회원 식별은 JWT 주차에서 토큰으로 바뀝니다.
///
/// 7주차 — 수정·삭제가 성공하면 목록을 다시 조회합니다.
/// - 쓰기 실패: [WriteFailure]를 던져 Dialog가 실패로 처리 (입력 유지, 다시 시도)
/// - 쓰기 성공 + 재조회 실패: 저장 성공으로 돌려주고 [refreshWarning]으로 조회만 다시 시도하게 안내
///
/// W7-CH 다중 삭제 — 선택 모드에서 고른 평점을 하나씩 DELETE한 뒤 목록을 한 번만 다시 조회합니다.
/// 삭제 중에는 [isBulkDeleting]으로 화면 전체 입력을 막습니다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._service,
    this._movieService,
    this.memberId, {
    this.currentMemberId,
  });

  final RatingApiService _service;
  final TmdbMovieService _movieService;

  /// 목록을 조회하는 회원
  final int memberId;

  /// 지금 앱을 쓰는 학습용 회원(LearningMemberSession) — 가입 전이면 null
  final int? currentMemberId;

  /// 본인이 작성한 평점 목록일 때만 수정·삭제 버튼을 보여줍니다.
  bool get canModify => currentMemberId != null && currentMemberId == memberId;

  /// 저장은 성공했지만 다시 조회가 실패했을 때의 안내 — 다음 조회가 성공하면 지웁니다.
  String? refreshWarning;

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
      refreshWarning = null;
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

  // ---------------------------------------------------------------------------
  // 다중 삭제 (W7-CH)
  // ---------------------------------------------------------------------------

  bool _isSelecting = false;
  bool get isSelecting => _isSelecting;

  final Set<int> _selectedIds = {};
  Set<int> get selectedIds => Set.unmodifiable(_selectedIds);

  /// 다중 삭제 요청 중 — 화면은 전체를 덮는 로딩으로 터치·뒤로가기를 막습니다.
  bool isBulkDeleting = false;

  /// 길게 누른 평점을 선택한 채로 선택 모드를 시작합니다.
  void startSelection(int ratingId) {
    if (!canModify || isBulkDeleting) return;
    _isSelecting = true;
    _selectedIds
      ..clear()
      ..add(ratingId);
    notifyListeners();
  }

  void toggleSelection(int ratingId) {
    if (!_isSelecting || isBulkDeleting) return;
    if (!_selectedIds.remove(ratingId)) _selectedIds.add(ratingId);
    notifyListeners();
  }

  void cancelSelection() {
    if (isBulkDeleting) return;
    _isSelecting = false;
    _selectedIds.clear();
    notifyListeners();
  }

  /// 선택한 평점을 순서대로 삭제하고 실패한 개수를 돌려줍니다.
  ///
  /// v6에는 여러 개를 한 번에 지우는 API가 없어 DELETE를 하나씩 보냅니다.
  /// - 모두 성공: 선택 모드를 끝냅니다.
  /// - 일부 실패: 실패한 평점만 선택된 채로 남겨 다시 시도할 수 있게 합니다.
  /// - 한 개라도 서버 상태가 바뀌었으면 목록을 한 번만 다시 조회합니다.
  Future<int> deleteSelected() async {
    if (isBulkDeleting || _selectedIds.isEmpty) return 0;
    isBulkDeleting = true;
    notifyListeners();

    final failedIds = <int>{};
    var needsRefresh = false;
    for (final ratingId in [..._selectedIds]) {
      try {
        await _service.deleteRating(memberId: memberId, ratingId: ratingId);
        needsRefresh = true;
      } on DioException catch (error) {
        failedIds.add(ratingId);
        if (shouldRefreshAfterRatingError(error)) needsRefresh = true;
      } catch (_) {
        failedIds.add(ratingId);
      }
      if (_disposed) return failedIds.length;
    }

    if (needsRefresh) await _refreshAfterWrite();
    if (_disposed) return failedIds.length;

    // 다시 조회한 목록에 남아 있는 실패 평점만 선택 상태로 둡니다.
    final remaining = {for (final entry in ratings) entry.rating.ratingId};
    _selectedIds
      ..clear()
      ..addAll(failedIds.where(remaining.contains));
    _isSelecting = _selectedIds.isNotEmpty;
    isBulkDeleting = false;
    notifyListeners();
    return failedIds.length;
  }

  /// 평점 수정 — PATCH. comment가 null이면 후기를 지우는 요청입니다.
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) {
    return _write(
      () => _service.updateRating(
        memberId: memberId,
        ratingId: ratingId,
        score: score,
        comment: comment,
      ),
    );
  }

  /// 평점 삭제 — DELETE (204, body 없음)
  Future<void> deleteRating(int ratingId) {
    return _write(
      () => _service.deleteRating(memberId: memberId, ratingId: ratingId),
    );
  }

  /// 쓰기 → 성공하면 다시 조회. 쓰기 실패와 재조회 실패를 구분합니다.
  Future<void> _write(Future<void> Function() request) async {
    try {
      await request();
    } on DioException catch (error) {
      // 403(본인 평점 아님)·404(이미 없는 평점)는 화면 목록이 서버와 어긋났다는 뜻 — 다시 맞춥니다.
      if (shouldRefreshAfterRatingError(error) && !_disposed) await load();
      throw WriteFailure(writeErrorMessage(error));
    } catch (_) {
      throw const WriteFailure('저장하지 못했습니다. 잠시 후 다시 시도해 주세요.');
    }
    // 여기부터는 저장 성공 — GET이 실패해도 저장 실패로 다시 던지지 않습니다.
    if (!_disposed) await _refreshAfterWrite();
  }

  Future<void> _refreshAfterWrite() async {
    await load(); // 실패하면 load()가 status=error로 기록합니다.
    if (_disposed) return;
    if (status == MyRatingsLoadStatus.error) {
      refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다.\n조회만 다시 시도해 주세요.';
      notifyListeners();
    }
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
