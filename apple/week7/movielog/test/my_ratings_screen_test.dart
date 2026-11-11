import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';

import 'fake_ratings.dart';
import 'fake_tmdb.dart';

/// 라우터와 같은 방식으로 ViewModel을 만들어 붙입니다.
Widget _app(RatingApiService service) => MaterialApp(
  theme: AppTheme.light,
  home: ChangeNotifierProvider<MyRatingsViewModel>(
    create: (_) =>
        MyRatingsViewModel(service, fakeTmdbService(), sampleMemberId)..load(),
    child: const MyRatingsScreen(),
  ),
);

void main() {
  testWidgets('Loading → Success: 영화 제목·별점·한줄평·등록일을 보여준다', (tester) async {
    final gate = Completer<void>();
    await tester.pumpWidget(
      _app(
        fakeRatingApiService(
          ratings: [
            fakeRatingJson(ratingId: 2, movieId: 1, score: 4),
            fakeRatingJson(ratingId: 1, movieId: 7, comment: null),
          ],
          gate: gate.future,
        ),
      ),
    );

    expect(find.text('내가 등록한 평점'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(find.text('마션 레스큐'), findsOneWidget);
    expect(find.text('별점 4 / 5'), findsOneWidget);
    expect(find.text('별점 5 / 5'), findsOneWidget);
    expect(find.text('2026.09.06'), findsNWidgets(2));
    // comment가 null인 평점은 후기를 그리지 않음
    expect(find.text('최고의 영화!'), findsOneWidget);
    expect(find.text('포스터 정보 없음'), findsNothing);
  });

  testWidgets('평점 카드가 W6-02 Figma 크기를 따른다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        fakeRatingApiService(
          ratings: [
            fakeRatingJson(ratingId: 2, movieId: 680, score: 4),
            fakeRatingJson(ratingId: 1, movieId: 13, score: 3, comment: null),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 카드 350 x 156, 헤더(64) 아래 32, 왼쪽 20
    final card = find
        .ancestor(of: find.text('영화 #680'), matching: find.byType(Container))
        .last;
    expect(tester.getSize(card), const Size(350, 156));
    expect(tester.getTopLeft(card), const Offset(20, 64 + 32));

    // 포스터 82 x 124, 카드 안쪽 16
    final poster = find.byKey(const ValueKey('rating-poster-placeholder'));
    expect(tester.getSize(poster.first), const Size(82, 124));
    expect(
      tester.getTopLeft(poster.first) - tester.getTopLeft(card),
      const Offset(16, 16),
    );

    // 제목 → 별점 → 후기 위치 (Figma top 127 / 160 / 191, left 134)
    final top = tester.getTopLeft(card).dy;
    expect(tester.getTopLeft(find.text('영화 #680')), Offset(134, top + 31));
    expect(tester.getTopLeft(find.text('별점 4 / 5')).dy, top + 64);
    expect(tester.getTopLeft(find.text('최고의 영화!')).dy, top + 95);
  });

  testWidgets('Empty: 평점이 없으면 안내 문구', (tester) async {
    await tester.pumpWidget(_app(fakeRatingApiService()));
    await tester.pumpAndSettle();

    expect(find.text('아직 등록된 평점이 없습니다.'), findsOneWidget);
  });

  testWidgets('Error: 404 안내와 다시 시도', (tester) async {
    await tester.pumpWidget(_app(fakeRatingApiService(statusCode: 404)));
    await tester.pumpAndSettle();

    expect(find.text('존재하지 않는 회원입니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    // 다시 시도는 공용 버튼 고정 너비 120
    expect(
      tester.getSize(
        find.ancestor(
          of: find.text('다시 시도'),
          matching: find.byType(MovieLogButton),
        ),
      ),
      const Size(120, 44),
    );
  });

  testWidgets('다시 시도를 누르면 다시 불러온다', (tester) async {
    final requests = <String>[];
    await tester.pumpWidget(
      _app(fakeRatingApiService(fail: true, requests: requests)),
    );
    await tester.pumpAndSettle();
    expect(find.text('평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(requests, hasLength(2));
  });

  testWidgets('TMDB에서 못 찾은 영화는 영화 #movieId와 placeholder로 평점을 남긴다', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        fakeRatingApiService(
          ratings: [
            fakeRatingJson(ratingId: 2, movieId: 999999),
            fakeRatingJson(ratingId: 1, movieId: 13, score: 3, comment: null),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('영화 #999999'), findsOneWidget);
    expect(find.text('영화 #13'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('rating-poster-placeholder')),
      findsNWidgets(2),
    );
    // 후기가 있으면 후기, 후기도 없으면 포스터 정보 없음
    expect(find.text('최고의 영화!'), findsOneWidget);
    expect(find.text('포스터 정보 없음'), findsOneWidget);
    expect(find.text('별점 3 / 5'), findsOneWidget);
  });
}
