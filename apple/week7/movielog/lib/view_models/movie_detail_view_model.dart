import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_detail_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../models/movie_detail.dart';

enum MovieDetailLoadStatus { idle, loading, success, error }

/// 영화 상세 화면의 상태 — 목록·홈 카드에서 받은 TMDB id로 상세 정보를 불러옵니다.
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._service, {required this.movieId});

  final TmdbMovieService _service;

  /// TMDB 영화 id — 평점 Dialog에도 그대로 전달해 이후 평점 movieId로 사용합니다.
  final int? movieId;

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

    status = MovieDetailLoadStatus.loading;
    notifyListeners();

    try {
      detail = _toDetail(await _service.fetchMovieDetail(id));
      status = MovieDetailLoadStatus.success;
    } on DioException catch (error) {
      status = MovieDetailLoadStatus.error;
      message = error.response?.statusCode == 404
          ? '영화를 찾을 수 없습니다.'
          : '영화 정보를 불러오지 못했어요.';
    }

    // 응답이 오기 전에 상세 화면을 벗어났으면(dispose) 알리지 않습니다.
    if (!_disposed) notifyListeners();
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
