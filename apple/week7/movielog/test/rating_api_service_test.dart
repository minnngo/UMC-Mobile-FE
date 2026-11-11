import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';

import 'fake_ratings.dart';

void main() {
  group('RatingDto', () {
    test('응답 JSON을 그대로 옮긴다', () {
      final rating = RatingDto.fromJson(fakeRatingJson());

      expect(rating.ratingId, 12);
      expect(rating.movieId, 550);
      expect(rating.score, 5);
      expect(rating.comment, '최고의 영화!');
      expect(rating.createdAt, DateTime.utc(2026, 9, 6, 12, 14, 3));
    });

    test('comment가 null이면 null 그대로 둔다', () {
      final rating = RatingDto.fromJson(fakeRatingJson(comment: null));

      expect(rating.comment, isNull);
    });
  });

  group('RatingApiService', () {
    test(
      '/v6/members/{memberId}/ratings로 요청하고 배열을 RatingDto 목록으로 바꾼다',
      () async {
        final requests = <String>[];
        final service = fakeRatingApiService(
          ratings: [
            fakeRatingJson(ratingId: 2, movieId: 550),
            fakeRatingJson(ratingId: 1, movieId: 680, comment: null),
          ],
          requests: requests,
        );

        final ratings = await service.fetchMyRatings(1);

        expect(requests, ['/v6/members/1/ratings']);
        expect(ratings.map((rating) => rating.movieId), [550, 680]);
        expect(ratings.last.comment, isNull);
      },
    );

    test('평점이 없으면 빈 목록 — 실패가 아니다', () async {
      final ratings = await fakeRatingApiService().fetchMyRatings(1);

      expect(ratings, isEmpty);
    });

    test('400·404·통신 실패는 DioException으로 넘긴다', () async {
      for (final service in [
        fakeRatingApiService(statusCode: 400),
        fakeRatingApiService(statusCode: 404),
        fakeRatingApiService(fail: true),
      ]) {
        await expectLater(
          service.fetchMyRatings(1),
          throwsA(isA<DioException>()),
        );
      }
    });
  });

  group('writeMyRatingsErrorMessage', () {
    Future<String> messageFor(RatingApiService service) async {
      try {
        await service.fetchMyRatings(1);
        fail('DioException이 나야 합니다.');
      } on DioException catch (error) {
        return writeMyRatingsErrorMessage(error);
      }
    }

    test('400이면 memberId 형식 안내', () async {
      expect(
        await messageFor(fakeRatingApiService(statusCode: 400)),
        'memberId 형식을 다시 확인해 주세요.',
      );
    });

    test('404이면 존재하지 않는 회원 안내', () async {
      expect(
        await messageFor(fakeRatingApiService(statusCode: 404)),
        '존재하지 않는 회원입니다.',
      );
    });

    test('통신 실패나 그 밖의 상태 코드는 다시 시도 안내', () async {
      const retry = '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
      expect(await messageFor(fakeRatingApiService(fail: true)), retry);
      expect(await messageFor(fakeRatingApiService(statusCode: 500)), retry);
    });
  });
}
