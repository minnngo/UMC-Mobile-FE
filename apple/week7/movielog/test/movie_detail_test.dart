import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/movie_detail_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/widgets/rating_dialog.dart';

import 'fake_tmdb.dart';

/// 라우터와 같은 방식으로 상세 ViewModel을 만들어 붙입니다.
Widget _app(TmdbMovieService service, int? movieId) => MaterialApp(
  theme: AppTheme.light,
  home: ChangeNotifierProvider<MovieDetailViewModel>(
    create: (_) => MovieDetailViewModel(service, movieId: movieId)..load(),
    child: MovieDetailScreen(movieId: movieId),
  ),
);

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

    testWidgets('평점 Dialog에 같은 TMDB id를 전달한다', (tester) async {
      _useTallView(tester);
      await tester.pumpWidget(_app(fakeTmdbService(), 1));
      await tester.pumpAndSettle();

      await tester.tap(find.text('평점 남기기'));
      await tester.pumpAndSettle();
      expect(tester.widget<RatingDialog>(find.byType(RatingDialog)).movieId, 1);
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
}
