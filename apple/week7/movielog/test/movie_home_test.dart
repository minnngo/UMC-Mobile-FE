import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/home_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/widgets/movie_card.dart';

import 'fake_tmdb.dart';

/// 인기 영화 섹션(배너 아래)까지 한 화면에 보이도록 넓은 화면을 씁니다.
void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// 라우터와 같은 방식으로 홈 ViewModel을 만들어 붙입니다.
Widget _app(TmdbMovieService service) => MaterialApp(
  theme: AppTheme.light,
  home: ChangeNotifierProvider<MovieHomeViewModel>(
    create: (_) => MovieHomeViewModel(service)..loadPopular(),
    child: const HomeScreen(),
  ),
);

List<Map<String, Object?>> _manyMovies(int count) => [
  for (var id = 1; id <= count; id++)
    {'id': id, 'title': '인기 $id', 'vote_average': 8.0},
];

void main() {
  testWidgets('불러오는 동안 로딩을 보여주고, 완료되면 인기 영화를 보여준다', (tester) async {
    _useTallView(tester);
    await tester.pumpWidget(
      _app(fakeTmdbService(delay: const Duration(milliseconds: 100))),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('마션 레스큐'), findsOneWidget);
    // TMDB 평점(10점 만점)을 그대로 표시
    expect(find.text('9.6'), findsOneWidget);
    // 포스터가 없는 영화는 placeholder
    expect(
      find.byIcon(Icons.image_not_supported_outlined),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('Popular 결과에서 앞의 5개만 보여준다', (tester) async {
    _useTallView(tester);
    await tester.pumpWidget(
      _app(fakeTmdbService(popularResults: _manyMovies(20))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MovieCard), findsNWidgets(5));
    expect(find.text('인기 5'), findsOneWidget);
    expect(find.text('인기 6'), findsNothing);
  });

  testWidgets('결과가 5개보다 적어도 있는 만큼 보여준다', (tester) async {
    _useTallView(tester);
    await tester.pumpWidget(
      _app(fakeTmdbService(popularResults: _manyMovies(2))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MovieCard), findsNWidgets(2));
  });

  testWidgets('결과가 없으면 안내 문구를 보여준다', (tester) async {
    _useTallView(tester);
    await tester.pumpWidget(_app(fakeTmdbService(popularResults: const [])));
    await tester.pumpAndSettle();

    expect(find.text('인기 영화가 없어요.'), findsOneWidget);
  });

  testWidgets('실패하면 안내 문구와 다시 시도를 보여주고, 누르면 다시 불러온다', (tester) async {
    _useTallView(tester);
    var failing = true;
    await tester.pumpWidget(_app(fakeTmdbService(fail: () => failing)));
    await tester.pumpAndSettle();
    expect(find.text('인기 영화를 불러오지 못했어요.'), findsOneWidget);

    failing = false;
    await tester.ensureVisible(find.text('다시 시도'));
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('마션 레스큐'), findsOneWidget);
  });

  testWidgets('불러오는 중에 홈을 벗어나도 오류가 나지 않는다', (tester) async {
    _useTallView(tester);
    await tester.pumpWidget(
      _app(fakeTmdbService(delay: const Duration(milliseconds: 100))),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });
}
