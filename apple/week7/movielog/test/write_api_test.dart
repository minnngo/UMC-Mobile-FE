import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';

import 'fake_ratings.dart';
import 'fake_sign_up.dart';

void main() {
  group('CommonResponse', () {
    test('result가 있으면 parseResult로 payload를 만든다', () {
      final response = CommonResponse<SignUpResult>.fromJson({
        'isSuccess': true,
        'code': 'COMMON201',
        'message': '회원가입에 성공했습니다.',
        'result': {'memberId': 7, 'email': 'a@b.com', 'nickname': '무비'},
      }, (value) => SignUpResult.fromJson(value as Map<String, dynamic>));

      expect(response.isSuccess, isTrue);
      expect(response.code, 'COMMON201');
      expect(response.result?.memberId, 7);
    });

    test('result가 null이면 parseResult를 호출하지 않는다', () {
      final response = CommonResponse<int>.fromJson(
        fakeCommonError('COMMON404', '존재하지 않는 평점입니다.'),
        (value) => throw StateError('호출되면 안 됩니다.'),
      );

      expect(response.isSuccess, isFalse);
      expect(response.result, isNull);
    });

    test('공통 형식이 아닌 오류 body는 tryParseError가 null', () {
      expect(CommonResponse.tryParseError('<html>'), isNull);
      expect(CommonResponse.tryParseError({'message': 'x'}), isNull);
      expect(CommonResponse.tryParseError(null), isNull);
    });
  });

  group('요청 Model toJson', () {
    test('회원가입 — 이메일·닉네임은 trim, 비밀번호는 그대로', () {
      const request = CreateMemberRequest(
        email: ' movie@umc.com ',
        password: ' Pass1234! ',
        nickname: ' 무비러버 ',
      );

      expect(request.toJson(), {
        'email': 'movie@umc.com',
        'password': ' Pass1234! ',
        'nickname': '무비러버',
      });
      expect(request.toString(), isNot(contains('Pass1234!')));
    });

    test('평점 등록 — comment가 비어 있으면 키 자체를 생략한다', () {
      expect(
        const CreateRatingRequest(
          movieId: 550,
          score: 4,
          comment: '  ',
        ).toJson(),
        {'movieId': 550, 'score': 4},
      );
      expect(
        const CreateRatingRequest(
          movieId: 550,
          score: 4,
          comment: ' 좋아요 ',
        ).toJson(),
        {'movieId': 550, 'score': 4, 'comment': '좋아요'},
      );
    });

    test('평점 수정 — comment가 null이어도 명시적으로 보낸다', () {
      expect(const UpdateRatingRequest(score: 3).toJson(), {
        'score': 3,
        'comment': null,
      });
    });

    test('validateServerScore — 1~5 정수만 통과', () {
      expect(validateServerScore(1), 1);
      expect(validateServerScore(5), 5);
      expect(() => validateServerScore(0), throwsArgumentError);
      expect(() => validateServerScore(3.5), throwsArgumentError);
      expect(() => validateServerScore(6), throwsArgumentError);
    });
  });

  group('SignUpService.signUp', () {
    test('POST /v6/members로 보내고 result에서 memberId를 읽는다', () async {
      final requests = <String>[];
      final bodies = <Object?>[];
      final service = fakeSignUpService(
        memberId: 77,
        requests: requests,
        bodies: bodies,
      );

      final response = await service.signUp(
        const CreateMemberRequest(
          email: 'movie@umc.com',
          password: 'Pass1234!',
          nickname: '무비러버',
        ),
      );

      expect(requests, ['/v6/members']);
      expect(bodies.single, {
        'email': 'movie@umc.com',
        'password': 'Pass1234!',
        'nickname': '무비러버',
      });
      expect(response.result?.memberId, 77);
    });

    test('409면 서버 message를 그대로 안내 문구로 쓴다', () async {
      final service = fakeSignUpService(signUpStatus: 409);
      try {
        await service.signUp(
          const CreateMemberRequest(
            email: 'a@b.com',
            password: 'p',
            nickname: 'nn',
          ),
        );
        fail('DioException이 나야 합니다.');
      } on DioException catch (error) {
        expect(writeSignUpErrorMessage(error), '이미 사용 중인 이메일입니다.');
      }
    });
  });

  group('RatingApiService 쓰기', () {
    test('등록 — POST /v6/members/{memberId}/ratings, 201이면 성공', () async {
      final server = FakeRatingServer();

      await server.service.createRating(
        memberId: 7,
        request: const CreateRatingRequest(movieId: 550, score: 4),
      );

      expect(server.calls, ['POST /v6/members/7/ratings']);
      expect(server.bodies.single, {'movieId': 550, 'score': 4});
      expect(server.ratings.single['movieId'], 550);
    });

    test('수정 — PATCH .../ratings/{ratingId}에 score·comment를 보낸다', () async {
      final server = FakeRatingServer(ratings: [fakeRatingJson(ratingId: 3)]);

      await server.service.updateRating(
        memberId: 7,
        ratingId: 3,
        score: 2,
        comment: null,
      );

      expect(server.calls, ['PATCH /v6/members/7/ratings/3']);
      expect(server.bodies.single, {'score': 2, 'comment': null});
    });

    test('삭제 — 204 body 없음을 JSON 파싱 없이 성공으로 처리한다', () async {
      final server = FakeRatingServer(ratings: [fakeRatingJson(ratingId: 3)]);

      await server.service.deleteRating(memberId: 7, ratingId: 3);

      expect(server.calls, ['DELETE /v6/members/7/ratings/3']);
      expect(server.ratings, isEmpty);
    });

    Future<DioException> writeFailure(FakeApiError error) async {
      final server = FakeRatingServer()..writeError = error;
      try {
        await server.service.deleteRating(memberId: 7, ratingId: 3);
      } on DioException catch (e) {
        return e;
      }
      throw StateError('DioException이 나야 합니다.');
    }

    test('쓰기 실패 문구는 서버 message 그대로, 403·404만 다시 조회', () async {
      final forbidden = await writeFailure((
        status: 403,
        code: 'COMMON403',
        message: '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
      ));
      final notFound = await writeFailure((
        status: 404,
        code: 'COMMON404',
        message: '존재하지 않는 평점입니다.',
      ));
      final duplicated = await writeFailure((
        status: 409,
        code: 'COMMON409',
        message: '이미 이 영화에 평점을 남기셨습니다.',
      ));

      expect(writeErrorMessage(forbidden), '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.');
      expect(writeErrorMessage(notFound), '존재하지 않는 평점입니다.');
      expect(shouldRefreshAfterRatingError(forbidden), isTrue);
      expect(shouldRefreshAfterRatingError(notFound), isTrue);
      expect(shouldRefreshAfterRatingError(duplicated), isFalse);
    });
  });
}
