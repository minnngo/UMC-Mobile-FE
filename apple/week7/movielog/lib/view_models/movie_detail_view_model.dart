import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_detail_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../models/movie_detail.dart';
import 'submit_status.dart';

export 'submit_status.dart';

enum MovieDetailLoadStatus { idle, loading, success, error }

/// 영화 상세 화면의 상태 — 목록·홈 카드에서 받은 TMDB id로 상세 정보를 불러옵니다.
///
/// 7주차 — 이 화면에서는 평점 "등록"만 합니다. (조회·수정·삭제는 마이페이지)
/// 조회 상태([status])와 등록 상태([submitStatus])를 따로 둡니다.
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._service, {
    required this.movieId,
    required this.ratingService,
    this.memberId,
    this.initialMovie,
  });

  /// 목록·홈 카드에서 GoRouter extra로 받은 영화 — 있으면 상세 응답 전에 기본 정보를 먼저 보여줍니다.
  final TmdbMovieDto? initialMovie;

  final TmdbMovieService _service;
  final RatingApiService ratingService;

  /// TMDB 영화 id (`TmdbMovieDto.id`) — 평점 등록 요청의 movieId로 그대로 보냅니다.
  final int? movieId;

  /// 학습용 현재 회원(LearningMemberSession). 로그인 인증은 아닙니다. 가입 전이면 null.
  final int? memberId;

  bool get canRate => memberId != null && movieId != null;

  SubmitStatus submitStatus = SubmitStatus.idle;

  /// 등록 실패 문구 — 서버 message 그대로
  String? submitMessage;

  MovieDetail? detail;
  MovieDetailLoadStatus status = MovieDetailLoadStatus.idle;
  String? message;

  bool _disposed = false;

  Future<void> load() async {
    final id = movieId;
    if (id == null) {
      status = MovieDetailLoadStatus.error;
      message = '영화를 찾을 수 없습니다.';
      notifyListeners();
      return;
    }

    // extra로 받은 목록 정보가 있으면 로딩 대신 먼저 보여주고, 러닝타임·장르는 상세 응답으로 채웁니다.
    final initial = initialMovie;
    if (detail == null && initial != null) {
      detail = _fromListDto(initial);
      status = MovieDetailLoadStatus.success;
    } else {
      status = MovieDetailLoadStatus.loading;
    }
    notifyListeners();

    try {
      detail = _toDetail(await _service.fetchMovieDetail(id));
      status = MovieDetailLoadStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      // 목록 정보로 이미 화면을 그렸으면 그대로 둡니다. (평점 등록에 필요한 TMDB id는 이미 있음)
      if (detail != null) return notifyListeners();
      status = MovieDetailLoadStatus.error;
      message = error.response?.statusCode == 404
          ? '영화를 찾을 수 없습니다.'
          : '영화 정보를 불러오지 못했어요.';
    }

    // 응답이 오기 전에 상세 화면을 벗어났으면(dispose) 알리지 않습니다.
    if (!_disposed) notifyListeners();
  }

  /// 목록 응답(TmdbMovieDto)만으로 만든 임시 상세 — 장르 이름·러닝타임·참여 수는 아직 없습니다.
  static MovieDetail _fromListDto(TmdbMovieDto dto) {
    final releaseDate = dto.releaseDate;
    return MovieDetail(
      title: dto.title,
      posterPath: dto.posterPath,
      year: releaseDate != null && releaseDate.length >= 4
          ? int.tryParse(releaseDate.substring(0, 4))
          : null,
      genres: const [],
      rating: dto.voteAverage / 2,
      synopsis: [
        for (final paragraph in dto.overview.split('\n'))
          if (paragraph.trim().isNotEmpty) paragraph.trim(),
      ],
    );
  }

  /// TMDB 응답을 상세 화면이 쓰는 [MovieDetail]로 바꿉니다.
  /// - release_date가 없으면 연도를 표시하지 않습니다.
  /// - TMDB 평점(10점 만점)은 앱의 5점 만점으로 바꿉니다.
  /// - overview가 비어 있으면 시놉시스 문단이 없습니다. (화면에서 안내 문구 표시)
  static MovieDetail _toDetail(TmdbMovieDetailDto dto) {
    final releaseDate = dto.releaseDate;
    final genreNames = [for (final genre in dto.genres) genre.name];
    final runtime = dto.runtime;

    return MovieDetail(
      title: dto.title,
      posterPath: dto.posterPath,
      year: releaseDate != null && releaseDate.length >= 4
          ? int.tryParse(releaseDate.substring(0, 4))
          : null,
      genres: genreNames,
      rating: dto.voteAverage / 2,
      runtimeMinutes: runtime != null && runtime > 0 ? runtime : null,
      reviewCount: dto.voteCount,
      tags: genreNames,
      synopsis: [
        for (final paragraph in dto.overview.split('\n'))
          if (paragraph.trim().isNotEmpty) paragraph.trim(),
      ],
    );
  }

  /// 평점 등록 — POST /v6/members/{memberId}/ratings
  ///
  /// 실패는 던지지 않고 [submitStatus]·[submitMessage]에 기록합니다.
  /// 400(별점 범위)·409(중복 등록)는 같은 Dialog에서 값만 고쳐 다시 시도하면 되므로 다시 조회하지 않습니다.
  Future<void> createRating({required int score, String? comment}) async {
    final id = memberId;
    final tmdbId = movieId;
    if (id == null || tmdbId == null) {
      submitStatus = SubmitStatus.error;
      submitMessage = '먼저 학습용 회원가입을 완료해 주세요.';
      notifyListeners();
      return;
    }
    if (submitStatus == SubmitStatus.submitting) return;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();

    try {
      await ratingService.createRating(
        memberId: id,
        request: CreateRatingRequest(
          movieId: tmdbId,
          score: score,
          comment: comment,
        ),
      );
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = writeErrorMessage(error);
    } catch (_) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
