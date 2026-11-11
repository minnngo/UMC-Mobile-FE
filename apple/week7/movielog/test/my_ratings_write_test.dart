import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/rating_dialog.dart';

import 'fake_ratings.dart';
import 'fake_tmdb.dart';

const _memberId = 42;

MyRatingsViewModel _viewModel(FakeRatingServer server, {int? current}) =>
    MyRatingsViewModel(
      server.service,
      fakeTmdbService(),
      _memberId,
      currentMemberId: current,
    );

FakeRatingServer _serverWithTwo() => FakeRatingServer(
  ratings: [
    fakeRatingJson(ratingId: 2, movieId: 1, score: 4, comment: '다시 봐도 좋다'),
    fakeRatingJson(ratingId: 1, movieId: 2, score: 3, comment: null),
  ],
);

void main() {
  group('MyRatingsViewModel 수정·삭제', () {
    test('본인 목록일 때만 canModify', () {
      final server = FakeRatingServer();
      expect(_viewModel(server, current: _memberId).canModify, isTrue);
      expect(_viewModel(server, current: 1).canModify, isFalse);
      expect(_viewModel(server).canModify, isFalse);
    });

    test('수정 성공 → PATCH 뒤 GET으로 목록을 다시 맞춘다', () async {
      final server = _serverWithTwo();
      final viewModel = _viewModel(server, current: _memberId);
      await viewModel.load();
      server.calls.clear();

      await viewModel.updateRating(ratingId: 2, score: 5, comment: null);

      expect(server.calls, [
        'PATCH /v6/members/42/ratings/2',
        'GET /v6/members/42/ratings',
      ]);
      expect(viewModel.ratings.first.rating.score, 5);
      expect(viewModel.ratings.first.rating.comment, isNull);
    });

    test('마지막 평점을 삭제하면 다시 조회한 결과가 empty', () async {
      final server = FakeRatingServer(ratings: [fakeRatingJson(ratingId: 3)]);
      final viewModel = _viewModel(server, current: _memberId);
      await viewModel.load();

      await viewModel.deleteRating(3);

      expect(server.calls.last, 'GET /v6/members/42/ratings');
      expect(viewModel.status, MyRatingsLoadStatus.empty);
    });

    test('400은 서버 문구로 WriteFailure를 던지고 다시 조회하지 않는다', () async {
      final server = _serverWithTwo();
      final viewModel = _viewModel(server, current: _memberId);
      await viewModel.load();
      server
        ..calls.clear()
        ..writeError = (
          status: 400,
          code: 'COMMON400',
          message: '별점은 5점 이하여야 합니다.',
        );

      await expectLater(
        viewModel.updateRating(ratingId: 2, score: 5),
        throwsA(
          isA<WriteFailure>().having(
            (e) => e.message,
            'message',
            '별점은 5점 이하여야 합니다.',
          ),
        ),
      );
      expect(server.calls, ['PATCH /v6/members/42/ratings/2']);
    });

    test('403·404는 WriteFailure를 던지고 목록을 다시 조회해 서버와 맞춘다', () async {
      final server = _serverWithTwo();
      final viewModel = _viewModel(server, current: _memberId);
      await viewModel.load();
      server
        ..calls.clear()
        ..writeError = (
          status: 404,
          code: 'COMMON404',
          message: '존재하지 않는 평점입니다.',
        );

      await expectLater(
        viewModel.deleteRating(2),
        throwsA(isA<WriteFailure>()),
      );
      expect(server.calls, [
        'DELETE /v6/members/42/ratings/2',
        'GET /v6/members/42/ratings',
      ]);
    });

    test('저장 성공 후 GET만 실패하면 던지지 않고 refreshWarning, 다시 조회가 성공하면 지운다', () async {
      final server = _serverWithTwo();
      final viewModel = _viewModel(server, current: _memberId);
      await viewModel.load();
      server.failGet = true;

      // 저장 성공이므로 예외 없이 끝나야 합니다.
      await viewModel.updateRating(ratingId: 2, score: 2, comment: '다시 봐도 좋다');

      expect(server.ratings.first['score'], 2);
      expect(viewModel.status, MyRatingsLoadStatus.error);
      expect(viewModel.refreshWarning, contains('저장은 완료됐지만'));

      server.failGet = false;
      await viewModel.load();
      expect(viewModel.status, MyRatingsLoadStatus.success);
      expect(viewModel.refreshWarning, isNull);
    });
  });

  group('내가 등록한 평점 화면 수정·삭제', () {
    Future<void> pump(
      WidgetTester tester,
      FakeRatingServer server, {
      int? current = _memberId,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ChangeNotifierProvider<MyRatingsViewModel>(
            create: (_) => _viewModel(server, current: current)..load(),
            child: const MyRatingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('본인 목록이 아니면 수정·삭제 버튼을 그리지 않는다', (tester) async {
      await pump(tester, _serverWithTwo(), current: 1);
      expect(find.text('수정'), findsNothing);
      expect(find.text('삭제'), findsNothing);
    });

    testWidgets('본인 목록이면 카드마다 수정·삭제 버튼을 그린다 — W7-REQ 위치·크기', (tester) async {
      await pump(tester, _serverWithTwo());
      expect(find.text('수정'), findsNWidgets(2));
      expect(find.text('삭제'), findsNWidgets(2));

      Finder box(String label) => find
          .ancestor(of: find.text(label).first, matching: find.byType(SizedBox))
          .first;
      // 첫 카드: 수정 63 x 35 (left 290, top 121), 삭제 (left 290, top 164)
      expect(tester.getSize(box('수정')), const Size(63, 35));
      expect(tester.getTopLeft(box('수정')), const Offset(290, 121));
      expect(tester.getSize(box('삭제')), const Size(63, 35));
      expect(tester.getTopLeft(box('삭제')), const Offset(290, 164));
      // 글자 24 x 18 영역 가운데 — 글자 중심이 버튼 중심
      expect(
        tester.getCenter(find.text('수정').first),
        tester.getCenter(box('수정')),
      );
      // 카드 크기(W6-02 350 x 156)는 그대로
      final card = find
          .ancestor(of: find.text('별빛 아래 우리'), matching: find.byType(Container))
          .last;
      expect(tester.getSize(card), const Size(350, 156));
    });

    testWidgets('수정을 누르면 기존 별점·코멘트가 채워진 Dialog, 저장하면 다시 조회해 반영', (
      tester,
    ) async {
      final server = _serverWithTwo();
      await pump(tester, server);

      await tester.tap(find.text('수정').first);
      await tester.pumpAndSettle();
      expect(find.text('평점을 수정할까요?'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(RatingDialog),
          matching: find.text('다시 봐도 좋다'),
        ),
        findsOneWidget,
      );

      // 별 2개로 바꾸고 코멘트 수정
      await tester.tap(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(SvgPicture),
            )
            .at(1),
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(RatingDialog),
          matching: find.byType(TextField),
        ),
        '두 번 보니 별로',
      );
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(server.calls.skip(1), [
        'PATCH /v6/members/42/ratings/2',
        'GET /v6/members/42/ratings',
      ]);
      expect(server.bodies.single, {'score': 2, 'comment': '두 번 보니 별로'});
      expect(find.byType(RatingDialog), findsNothing);
      expect(find.text('별점 2 / 5'), findsOneWidget);
      expect(find.text('두 번 보니 별로'), findsOneWidget);
      expect(find.text('평점을 수정했습니다.'), findsOneWidget);
    });

    testWidgets('삭제 확인 Dialog — 취소하면 요청 없음, 삭제하면 목록 갱신 후 빈 목록', (tester) async {
      final server = FakeRatingServer(
        ratings: [fakeRatingJson(ratingId: 3, movieId: 1)],
      );
      await pump(tester, server);
      server.calls.clear();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(find.text('평점을 삭제할까요?'), findsOneWidget);
      expect(find.text('삭제한 평점은 복구할 수 없습니다.'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(server.calls, isEmpty);
      expect(find.text('별빛 아래 우리'), findsOneWidget);

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(Dialog), matching: find.text('삭제')),
      );
      await tester.pumpAndSettle();

      expect(server.calls, [
        'DELETE /v6/members/42/ratings/3',
        'GET /v6/members/42/ratings',
      ]);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('아직 등록된 평점이 없습니다.'), findsOneWidget);
      expect(find.text('평점을 삭제했습니다.'), findsOneWidget);
    });

    testWidgets('삭제가 실패하면 확인 Dialog에 서버 문구를 보여주고 다시 시도할 수 있다', (tester) async {
      final server = FakeRatingServer(
        ratings: [fakeRatingJson(ratingId: 3, movieId: 1)],
      );
      await pump(tester, server);
      server.writeError = (
        status: 403,
        code: 'COMMON403',
        message: '본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.',
      );

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(Dialog), matching: find.text('삭제')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.'), findsOneWidget);
    });

    testWidgets('저장 성공 후 GET만 실패하면 안내와 함께 조회만 다시 시도한다', (tester) async {
      final server = _serverWithTwo();
      await pump(tester, server);
      server.failGet = true;

      await tester.tap(find.text('삭제').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(Dialog), matching: find.text('삭제')),
      );
      await tester.pumpAndSettle();

      // 삭제는 성공 — Dialog는 닫히고 목록 자리에 재조회 안내
      expect(find.byType(Dialog), findsNothing);
      expect(
        find.text('저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.'),
        findsOneWidget,
      );

      server
        ..failGet = false
        ..calls.clear();
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      // 다시 시도는 GET만 보냅니다.
      expect(server.calls, ['GET /v6/members/42/ratings']);
      expect(find.text('수정'), findsOneWidget);
    });
  });

  group('다중 삭제 (W7-CH)', () {
    FakeRatingServer serverWithThree() => FakeRatingServer(
      ratings: [
        fakeRatingJson(ratingId: 3, movieId: 1, score: 5, comment: '좋은 영화였어요'),
        fakeRatingJson(ratingId: 2, movieId: 2, score: 4, comment: '다시 봐도 좋아요'),
        fakeRatingJson(ratingId: 1, movieId: 3, score: 3, comment: null),
      ],
    );

    test('선택한 평점을 하나씩 DELETE하고 목록은 한 번만 다시 조회한다', () async {
      final server = serverWithThree();
      final viewModel = _viewModel(server, current: _memberId);
      await viewModel.load();
      server.calls.clear();

      viewModel
        ..startSelection(3)
        ..toggleSelection(2);
      expect(viewModel.selectedIds, {3, 2});

      final failed = await viewModel.deleteSelected();

      expect(failed, 0);
      expect(server.calls, [
        'DELETE /v6/members/42/ratings/3',
        'DELETE /v6/members/42/ratings/2',
        'GET /v6/members/42/ratings',
      ]);
      expect(viewModel.ratings.map((e) => e.rating.ratingId), [1]);
      expect(viewModel.isSelecting, isFalse);
      expect(viewModel.isBulkDeleting, isFalse);
    });

    test('본인 목록이 아니면 선택 모드를 시작하지 않는다', () async {
      final viewModel = _viewModel(serverWithThree(), current: 1);
      await viewModel.load();
      viewModel.startSelection(3);
      expect(viewModel.isSelecting, isFalse);
    });

    testWidgets('길게 누르면 선택 모드 → 확인 Dialog → 삭제 중 화면 전체 로딩 → 목록 갱신', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final server = serverWithThree();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ChangeNotifierProvider<MyRatingsViewModel>(
            create: (_) => _viewModel(server, current: _memberId)..load(),
            child: const MyRatingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('별빛 아래 우리'));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택됨'), findsOneWidget);
      expect(find.text('선택한 1개 삭제'), findsOneWidget);
      expect(find.text('수정'), findsNothing);

      await tester.tap(find.textContaining('우주의 끝에서'));
      await tester.pumpAndSettle();
      expect(find.text('2개 선택됨'), findsOneWidget);

      // 뒤로가기는 화면을 닫지 않고 선택만 취소
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('2개 선택됨'), findsNothing);
      expect(find.text('수정'), findsNWidgets(3));

      await tester.longPress(find.text('별빛 아래 우리'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('우주의 끝에서'));
      await tester.pumpAndSettle();

      // 확인 Dialog — 취소하면 요청 없음
      server.calls.clear();
      await tester.tap(find.text('선택한 2개 삭제'));
      await tester.pumpAndSettle();
      expect(find.text('선택한 2개 평점을 삭제할까요?'), findsOneWidget);
      await tester.tap(find.text('취소').last);
      await tester.pumpAndSettle();
      expect(server.calls, isEmpty);

      // 삭제 → 진행 중에는 화면 전체 로딩, 뒤로가기도 막힘
      final gate = Completer<void>();
      server.writeGate = gate.future;
      await tester.tap(find.text('선택한 2개 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(Dialog), matching: find.text('삭제')),
      );
      // Dialog가 닫히는 프레임 → 삭제 시작을 알리는 프레임
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.bySemanticsLabel('삭제 중'), findsOneWidget);
      expect(find.byType(ModalBarrier), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.bySemanticsLabel('삭제 중'), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('삭제 중'), findsNothing);
      expect(find.text('2개 평점을 삭제했습니다.'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsNothing);
      expect(find.text('선택한 2개 삭제'), findsNothing);
      expect(server.calls.where((c) => c.startsWith('GET')), hasLength(1));
    });

    test('일부만 실패하면 실패한 평점만 선택된 채로 남는다', () async {
      final server = serverWithThree()..failingRatingIds.add(2);
      final viewModel = _viewModel(server, current: _memberId);
      await viewModel.load();
      viewModel
        ..startSelection(3)
        ..toggleSelection(2);

      final failed = await viewModel.deleteSelected();

      expect(failed, 1);
      expect(viewModel.ratings.map((e) => e.rating.ratingId), [2, 1]);
      expect(viewModel.isSelecting, isTrue);
      expect(viewModel.selectedIds, {2});
      expect(viewModel.isBulkDeleting, isFalse);
    });
  });
}
