import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/movie_detail_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/widgets/rating_dialog.dart';

import 'fake_ratings.dart';
import 'fake_tmdb.dart';

/// 라우터와 같은 방식으로 상세 ViewModel을 만들어 붙입니다.
/// [memberId]는 학습용 세션 값 — null이면 회원가입 전입니다.
Widget _app(
  TmdbMovieService service,
  int? movieId, {
  RatingApiService? ratingService,
  int? memberId,
}) => MaterialApp(
  theme: AppTheme.light,
  home: ChangeNotifierProvider<MovieDetailViewModel>(
    create: (_) => MovieDetailViewModel(
      service,
      movieId: movieId,
      ratingService: ratingService ?? fakeRatingApiService(),
      memberId: memberId,
    )..load(),
    child: MovieDetailScreen(movieId: movieId),
  ),
);

/// 평점 Dialog에서 [stars]점을 골라 [comment]와 함께 확인을 누릅니다.
Future<void> _rate(WidgetTester tester, int stars, {String? comment}) async {
  await tester.tap(find.text('평점 남기기'));
  await tester.pumpAndSettle();
  await tester.tap(
    find
        .descendant(of: find.byType(Dialog), matching: find.byType(SvgPicture))
        .at(stars - 1),
  );
  await tester.pump(); // 별점이 반영돼 확인 버튼이 켜진 프레임을 그립니다.
  if (comment != null) {
    await tester.enterText(find.byType(TextField), comment);
  }
  await tester.tap(find.text('확인'));
  await tester.pumpAndSettle();
}

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('TMDB 영화 상세', () {
    testWidgets('불러오는 동안 로딩을 보여주고, 완료되면 TMDB 상세를 보여준다', (tester) async {
      _useTallView(tester);
      final requests = <Uri>[];
      await tester.pumpWidget(
        _app(
          fakeTmdbService(
            requests: requests,
            delay: const Duration(milliseconds: 100),
          ),
          1,
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(requests.single.path, endsWith('/movie/1'));
      expect(find.text('별빛 아래 우리'), findsOneWidget);
      expect(find.text('2024 • 로맨스/드라마 • 124분'), findsOneWidget);
      // TMDB 평점 9.0(10점 만점) → 4.5(5점 만점), vote_count → 참여 수
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('(1,245)'), findsOneWidget);
      // 포스터가 없으면 placeholder
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });

    testWidgets('줄거리가 없으면 안내 문구를 보여준다', (tester) async {
      _useTallView(tester);
      // id 2(우주의 끝에서)는 Mock 시놉시스가 없어 overview가 빈 문자열
      await tester.pumpWidget(_app(fakeTmdbService(), 2));
      await tester.pumpAndSettle();

      expect(find.text('우주의 끝에서'), findsOneWidget);
      expect(find.text('줄거리 정보가 없어요.'), findsOneWidget);
    });

    testWidgets('없는 영화면 찾을 수 없다고 안내한다', (tester) async {
      await tester.pumpWidget(_app(fakeTmdbService(), 999));
      await tester.pumpAndSettle();

      expect(find.text('영화를 찾을 수 없습니다.'), findsOneWidget);
    });

    testWidgets('실패하면 다시 시도할 수 있다', (tester) async {
      _useTallView(tester);
      var failing = true;
      await tester.pumpWidget(_app(fakeTmdbService(fail: () => failing), 1));
      await tester.pumpAndSettle();
      expect(find.text('영화 정보를 불러오지 못했어요.'), findsOneWidget);

      failing = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('별빛 아래 우리'), findsOneWidget);
    });
  });

  group('평점 등록 (POST /v6/members/{memberId}/ratings)', () {
    testWidgets('학습용 회원가입 전에는 평점 남기기가 꺼져 있고 회원가입을 안내한다', (tester) async {
      _useTallView(tester);
      await tester.pumpWidget(_app(fakeTmdbService(), 1));
      await tester.pumpAndSettle();

      expect(find.text('평점을 남기려면 학습용 회원가입이 필요합니다.'), findsOneWidget);
      await tester.tap(find.text('평점 남기기'));
      await tester.pumpAndSettle();
      expect(find.byType(RatingDialog), findsNothing);
    });

    testWidgets('가입한 memberId와 TMDB id로 등록하고, 성공하면 Dialog를 닫고 Snackbar', (
      tester,
    ) async {
      _useTallView(tester);
      final server = FakeRatingServer();
      await tester.pumpWidget(
        _app(fakeTmdbService(), 1, ratingService: server.service, memberId: 42),
      );
      await tester.pumpAndSettle();
      expect(find.text('평점을 남기려면 학습용 회원가입이 필요합니다.'), findsNothing);

      await _rate(tester, 5);

      expect(server.calls, ['POST /v6/members/42/ratings']);
      // 코멘트를 비우면 comment 키를 보내지 않습니다.
      expect(server.bodies.single, {'movieId': 1, 'score': 5});
      expect(find.byType(RatingDialog), findsNothing);
      expect(find.textContaining('평점을 등록했습니다.'), findsOneWidget);
    });

    testWidgets('409 중복 등록이면 Dialog에 서버 문구를 보여주고 입력을 유지한다', (tester) async {
      _useTallView(tester);
      final server = FakeRatingServer()
        ..writeError = (
          status: 409,
          code: 'COMMON409',
          message: '이미 이 영화에 평점을 남기셨습니다.',
        );
      await tester.pumpWidget(
        _app(fakeTmdbService(), 1, ratingService: server.service, memberId: 42),
      );
      await tester.pumpAndSettle();

      await _rate(tester, 3, comment: '두 번째 감상');

      expect(find.byType(RatingDialog), findsOneWidget);
      // 실패 문구는 Dialog 안과 Snackbar에 함께 보입니다.
      expect(
        find.descendant(
          of: find.byType(RatingDialog),
          matching: find.text('이미 이 영화에 평점을 남기셨습니다.'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('이미 이 영화에 평점을 남기셨습니다.'),
        ),
        findsOneWidget,
      );
      expect(find.text('두 번째 감상'), findsOneWidget);
      expect(find.textContaining('평점을 등록했습니다.'), findsNothing);
      // 409는 목록을 다시 조회할 필요가 없는 오류 — GET 없음
      expect(server.calls, ['POST /v6/members/42/ratings']);
    });
  });

  testWidgets('영화 목록 카드를 누르면 TMDB id로 상세를 요청한다', (tester) async {
    _useTallView(tester);
    final requests = <Uri>[];
    AppRouter.router.go('/movies');
    await tester.pumpWidget(
      MovieLogApp(tmdbMovieService: fakeTmdbService(requests: requests)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('우주의 끝에서'));
    await tester.pumpAndSettle();

    expect(
      AppRouter.router.routerDelegate.currentConfiguration.last.matchedLocation,
      '/movies/2',
    );
    expect(requests.last.path, endsWith('/movie/2'));
    expect(find.text('Cinema Archive'), findsOneWidget);
  });

  testWidgets('목록에서 넘긴 TmdbMovieDto(extra)로 로딩 없이 먼저 보여주고, 상세 응답으로 채운다', (
    tester,
  ) async {
    _useTallView(tester);
    final requests = <Uri>[];
    AppRouter.router.go('/movies');
    await tester.pumpWidget(
      MovieLogApp(
        tmdbMovieService: fakeTmdbService(
          requests: requests,
          delay: const Duration(milliseconds: 100),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('별빛 아래 우리'));
    await tester.pump(); // 화면 전환 시작
    await tester.pump(const Duration(milliseconds: 50)); // 상세 응답 전
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('별빛 아래 우리'), findsWidgets);

    await tester.pumpAndSettle();
    expect(requests.last.path, endsWith('/movie/1'));
    // 상세 응답의 러닝타임·장르로 채워짐
    expect(find.text('2024 • 로맨스/드라마 • 124분'), findsOneWidget);
  });
}
