import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/view_models/my_ratings_view_model.dart';

import 'fake_ratings.dart';
import 'fake_tmdb.dart';

void main() {
  test('평점마다 TMDB 영화 정보를 붙여 success', () async {
    final requests = <String>[];
    final viewModel = MyRatingsViewModel(
      fakeRatingApiService(
        ratings: [
          fakeRatingJson(ratingId: 2, movieId: 1),
          fakeRatingJson(ratingId: 1, movieId: 7, comment: null),
        ],
        requests: requests,
      ),
      fakeTmdbService(),
      1,
    );

    await viewModel.load();

    expect(requests, ['/v6/members/1/ratings']);
    expect(viewModel.status, MyRatingsLoadStatus.success);
    expect(viewModel.message, isNull);
    expect(viewModel.ratings.map((entry) => entry.movie?.title), [
      '별빛 아래 우리',
      '마션 레스큐',
    ]);
    expect(viewModel.ratings.last.rating.comment, isNull);
  });

  test('불러오는 동안 loading', () async {
    final gate = Completer<void>();
    final viewModel = MyRatingsViewModel(
      fakeRatingApiService(gate: gate.future),
      fakeTmdbService(),
      1,
    );

    final pending = viewModel.load();
    expect(viewModel.status, MyRatingsLoadStatus.loading);

    gate.complete();
    await pending;
    expect(viewModel.status, MyRatingsLoadStatus.empty);
  });

  test('평점이 없으면 empty', () async {
    final viewModel = MyRatingsViewModel(
      fakeRatingApiService(),
      fakeTmdbService(),
      1,
    );

    await viewModel.load();

    expect(viewModel.status, MyRatingsLoadStatus.empty);
    expect(viewModel.ratings, isEmpty);
  });

  test('400·404·통신 실패는 각각의 안내 문구와 함께 error', () async {
    final cases = {
      fakeRatingApiService(statusCode: 400): 'memberId 형식을 다시 확인해 주세요.',
      fakeRatingApiService(statusCode: 404): '존재하지 않는 회원입니다.',
      fakeRatingApiService(fail: true): '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
    };

    for (final MapEntry(key: service, value: message) in cases.entries) {
      final viewModel = MyRatingsViewModel(service, fakeTmdbService(), 1);
      await viewModel.load();

      expect(viewModel.status, MyRatingsLoadStatus.error);
      expect(viewModel.message, message);
    }
  });

  test('TMDB에 없는 영화(404)도 평점은 남기고 영화 정보만 비운다', () async {
    final viewModel = MyRatingsViewModel(
      fakeRatingApiService(
        ratings: [
          fakeRatingJson(ratingId: 2, movieId: 1),
          fakeRatingJson(ratingId: 1, movieId: 999999),
        ],
      ),
      fakeTmdbService(),
      1,
    );

    await viewModel.load();

    expect(viewModel.status, MyRatingsLoadStatus.success);
    expect(viewModel.ratings, hasLength(2));
    expect(viewModel.ratings.last.movie, isNull);
    expect(viewModel.ratings.last.rating.movieId, 999999);
    expect(viewModel.message, '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.');
  });

  test('같은 movieId는 한 번만 조회하고, 다시 불러와도 캐시를 쓴다', () async {
    final tmdbRequests = <Uri>[];
    final viewModel = MyRatingsViewModel(
      fakeRatingApiService(
        ratings: [
          fakeRatingJson(ratingId: 3, movieId: 1),
          fakeRatingJson(ratingId: 2, movieId: 1),
          fakeRatingJson(ratingId: 1, movieId: 999999),
        ],
      ),
      fakeTmdbService(requests: tmdbRequests),
      1,
    );

    await viewModel.load();
    await viewModel.load();

    // 1번 한 번, 없는 영화(404)도 한 번 — 404는 null로 캐시
    expect(tmdbRequests.map((uri) => uri.path), [
      '/3/movie/1',
      '/3/movie/999999',
    ]);
    expect(viewModel.ratings, hasLength(3));
  });

  test('TMDB 통신 실패는 캐시하지 않고 다음 로딩에서 다시 조회한다', () async {
    var tmdbDown = true;
    final tmdbRequests = <Uri>[];
    final viewModel = MyRatingsViewModel(
      fakeRatingApiService(ratings: [fakeRatingJson(movieId: 1)]),
      fakeTmdbService(fail: () => tmdbDown, requests: tmdbRequests),
      1,
    );

    await viewModel.load();
    expect(viewModel.status, MyRatingsLoadStatus.success);
    expect(viewModel.ratings.single.movie, isNull);

    tmdbDown = false;
    await viewModel.load();
    expect(viewModel.ratings.single.movie?.title, '별빛 아래 우리');
    expect(viewModel.message, isNull);
    expect(tmdbRequests, hasLength(2));
  });

  test('응답 전에 화면을 벗어나면(dispose) 결과를 반영하지 않는다', () async {
    final gate = Completer<void>();
    final viewModel = MyRatingsViewModel(
      fakeRatingApiService(
        ratings: [fakeRatingJson(movieId: 1)],
        gate: gate.future,
      ),
      fakeTmdbService(),
      1,
    );

    final pending = viewModel.load();
    viewModel.dispose();
    gate.complete();
    await pending;

    expect(viewModel.status, MyRatingsLoadStatus.loading);
    expect(viewModel.ratings, isEmpty);
  });
}
