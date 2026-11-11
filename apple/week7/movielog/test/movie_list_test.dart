import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:movielog/data/local/genre_preference.dart';
import 'package:movielog/data/local/secure_storage_cleanup.dart';
import 'package:movielog/data/services/fake_movie_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

import 'fake_tmdb.dart';

/// 라우터와 같은 방식으로 화면마다 ViewModel을 만들어 붙입니다.
Widget _app(TmdbMovieService service, {Key? key}) => MaterialApp(
  theme: AppTheme.light,
  home: ChangeNotifierProvider<MovieListViewModel>(
    key: key,
    create: (_) => MovieListViewModel(service)..loadInitial(),
    child: const MovieListScreen(),
  ),
);

/// Discover 요청의 with_genres 값 (없으면 null)
List<String?> _discoverGenres(List<Uri> requests) => [
  for (final uri in requests)
    if (uri.path.endsWith('/discover/movie'))
      uri.queryParameters['with_genres'],
];

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('FakeMovieService', () {
    const service = FakeMovieService();

    test('mode에 따라 영화 목록·빈 목록·예외를 돌려준다', () async {
      expect(await service.fetchMovies(), isNotEmpty);
      expect(await service.fetchMovies(mode: MovieLoadMode.empty), isEmpty);
      expect(
        service.fetchMovies(mode: MovieLoadMode.failure),
        throwsA(isA<MovieLoadException>()),
      );
    });
  });

  group('영화 목록 상태', () {
    testWidgets('불러오는 동안 로딩을 보여주고, 완료되면 영화와 장르 칩을 보여준다', (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(fakeTmdbService(delay: const Duration(milliseconds: 100))),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('별빛 아래 우리'), findsOneWidget);
      // 장르 칩은 Genre API 결과 — 맨 앞은 전체
      expect(find.text('전체'), findsOneWidget);
      expect(find.text('드라마'), findsOneWidget);
    });

    testWidgets('포스터가 없는 영화는 placeholder를 보여준다', (tester) async {
      await tester.pumpWidget(_app(fakeTmdbService()));
      await tester.pumpAndSettle();

      expect(
        find.byIcon(Icons.image_not_supported_outlined),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('빈 목록이면 안내 문구를 보여준다', (tester) async {
      await tester.pumpWidget(_app(fakeTmdbService(results: const [])));
      await tester.pumpAndSettle();

      expect(find.text('조건에 맞는 영화가 없습니다.'), findsOneWidget);
    });

    testWidgets('실패하면 안내 문구와 다시 시도 버튼을 보여주고, 누르면 다시 불러온다', (tester) async {
      var failing = true;
      await tester.pumpWidget(
        _app(
          fakeTmdbService(
            fail: () => failing,
            delay: const Duration(milliseconds: 100),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('영화를 불러오지 못했어요. 다시 시도해 주세요.'), findsOneWidget);

      failing = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('별빛 아래 우리'), findsOneWidget);
    });

    testWidgets('불러오는 중에 화면이 사라져도 오류가 나지 않는다', (tester) async {
      await tester.pumpWidget(
        _app(fakeTmdbService(delay: const Duration(milliseconds: 100))),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });

  group('장르 필터', () {
    testWidgets('장르를 고르면 with_genres로 다시 요청하고, 전체는 with_genres 없이 요청한다', (
      tester,
    ) async {
      final requests = <Uri>[];
      await tester.pumpWidget(_app(fakeTmdbService(requests: requests)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SF'));
      await tester.pumpAndSettle();
      expect(find.text('우주의 끝에서'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsNothing);

      await tester.tap(find.text('전체'));
      await tester.pumpAndSettle();
      expect(find.text('별빛 아래 우리'), findsOneWidget);

      expect(_discoverGenres(requests), [null, '878', null]);
    });

    testWidgets('선택된 장르를 다시 누르면 선택이 풀려 전체를 요청한다', (tester) async {
      final requests = <Uri>[];
      await tester.pumpWidget(_app(fakeTmdbService(requests: requests)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SF'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SF'));
      await tester.pumpAndSettle();

      expect(_discoverGenres(requests), [null, '878', null]);
      expect(find.text('별빛 아래 우리'), findsOneWidget);
    });

    testWidgets('Discover 요청 중에는 장르를 바꿀 수 없다', (tester) async {
      final requests = <Uri>[];
      await tester.pumpWidget(
        _app(
          fakeTmdbService(
            requests: requests,
            delay: const Duration(milliseconds: 100),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('SF'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 로딩 중 다른 장르를 눌러도 요청하지 않음
      await tester.tap(find.text('드라마'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(_discoverGenres(requests), [null, '878']);
      expect(find.text('우주의 끝에서'), findsOneWidget);
    });
  });

  group('Pull to Refresh', () {
    Future<void> pullToRefresh(WidgetTester tester) async {
      await tester.fling(find.byType(GridView), const Offset(0, 400), 1000);
      // 새로고침이 시작될 만큼만 진행
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('선택한 장르 그대로 page 1부터 다시 요청하고, 그동안 기존 목록을 유지한다', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final requests = <Uri>[];
      var results = fakeTmdbMovies;
      await tester.pumpWidget(
        _app(
          fakeTmdbService(
            requests: requests,
            delay: const Duration(seconds: 2),
            resultsBuilder: () => results,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('SF'));
      await tester.pumpAndSettle();
      expect(find.text('우주의 끝에서'), findsOneWidget);

      // 서버의 SF 목록이 바뀐 상태에서 새로고침
      results = [
        ...fakeTmdbMovies,
        {
          'id': 100,
          'title': '새로 나온 SF',
          'genre_ids': [878],
        },
      ];
      requests.clear();
      await pullToRefresh(tester);

      // 새로고침 중: 로딩 화면 대신 기존 목록 유지, 장르 칩은 누를 수 없음
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);
      expect(find.text('우주의 끝에서'), findsOneWidget);
      await tester.tap(find.text('드라마'), warnIfMissed: false);

      await tester.pumpAndSettle();
      expect(_discoverGenres(requests), ['878']);
      expect(requests.single.queryParameters['page'], '1');
      expect(find.text('새로 나온 SF'), findsOneWidget);
    });

    testWidgets('새로고침이 실패하면 기존 목록을 유지한 채 재시도 Dialog를 띄운다', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var failing = false;
      await tester.pumpWidget(_app(fakeTmdbService(fail: () => failing)));
      await tester.pumpAndSettle();

      failing = true;
      await pullToRefresh(tester);
      await tester.pumpAndSettle();

      expect(find.text('영화를 불러오지 못했어요'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsOneWidget);

      // 네트워크를 다시 켜고 재시도 → Dialog가 닫히고 목록을 다시 불러옴
      failing = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('별빛 아래 우리'), findsOneWidget);
    });

    test('목록 전체를 불러오는 중에는 새로고침하지 않는다', () async {
      final requests = <Uri>[];
      final viewModel = MovieListViewModel(fakeTmdbService(requests: requests));

      final loading = viewModel.loadInitial();
      await viewModel.refresh();
      await loading;

      // loadInitial의 Discover 요청만 있음
      expect(_discoverGenres(requests), [null]);
    });
  });

  group('요청 실패 재시도 Dialog', () {
    /// 전체 목록을 불러온 뒤 네트워크가 끊긴 상태(goOffline)에서 SF를 선택합니다.
    Future<void> selectSfWhileOffline(
      WidgetTester tester,
      TmdbMovieService service,
      VoidCallback goOffline,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(service));
      await tester.pumpAndSettle();
      expect(find.text('별빛 아래 우리'), findsOneWidget);

      goOffline();
      await tester.tap(find.text('SF'));
      await tester.pumpAndSettle();
    }

    testWidgets('장르 요청이 실패하면 기존 목록을 유지한 채 Dialog를 띄운다', (tester) async {
      var failing = false;
      await selectSfWhileOffline(
        tester,
        fakeTmdbService(fail: () => failing),
        () => failing = true,
      );

      expect(find.text('영화를 불러오지 못했어요'), findsOneWidget);
      expect(find.text('네트워크 상태를 확인하고\n다시 시도해 주세요.'), findsOneWidget);
      // 최근 성공한 전체 목록이 그대로 남아 있음
      expect(find.text('별빛 아래 우리'), findsOneWidget);

      // W5-01: 326 x 282, 버튼 126 x 52
      final dialogBody = find
          .descendant(of: find.byType(Dialog), matching: find.byType(Material))
          .first;
      expect(tester.getSize(dialogBody), const Size(326, 282));
      final retryButton = find.ancestor(
        of: find.text('다시 시도'),
        matching: find.byType(FilledButton),
      );
      expect(tester.getSize(retryButton), const Size(126, 52));
    });

    testWidgets('다시 시도를 누르면 같은 장르로 page 1부터 다시 요청한다', (tester) async {
      var failing = false;
      final requests = <Uri>[];
      await selectSfWhileOffline(
        tester,
        fakeTmdbService(requests: requests, fail: () => failing),
        () => failing = true,
      );

      // 네트워크를 다시 켜고 재시도
      failing = false;
      requests.clear();
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(_discoverGenres(requests), ['878']);
      expect(requests.first.queryParameters['page'], '1');
      expect(find.text('우주의 끝에서'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsNothing);
    });

    testWidgets('취소하면 목록과 장르 선택을 실패 전으로 유지하고 다시 요청하지 않는다', (tester) async {
      var failing = false;
      final requests = <Uri>[];
      await selectSfWhileOffline(
        tester,
        fakeTmdbService(requests: requests, fail: () => failing),
        () => failing = true,
      );
      requests.clear();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(requests, isEmpty);
      expect(find.text('별빛 아래 우리'), findsOneWidget);
      // 칩도 목록과 같은 "전체"로 되돌아감
      final allChip = tester.getSemantics(
        find
            .ancestor(of: find.text('전체'), matching: find.byType(Semantics))
            .first,
      );
      expect(allChip.flagsCollection.isSelected, Tristate.isTrue);
      // 실패한 장르는 저장하지 않음
      expect(await GenrePreference().read(), isNull);
    });

    testWidgets('보여줄 목록이 없을 때 실패하면 Dialog 대신 오류 화면을 보여준다', (tester) async {
      await tester.pumpWidget(_app(fakeTmdbService(fail: () => true)));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(find.text('영화를 불러오지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    });
  });

  group('최대 30개', () {
    List<Map<String, Object?>> manyMovies(int count) => [
      for (var id = 1; id <= count; id++)
        {'id': id, 'title': '영화 $id', 'genre_ids': <int>[]},
    ];

    test('30개가 차면 다음 페이지를 요청하지 않는다', () async {
      final requests = <Uri>[];
      final viewModel = MovieListViewModel(
        fakeTmdbService(results: manyMovies(45), requests: requests),
      );

      final result = await viewModel.fetchUpToThirtyMovies();

      expect(result.map((movie) => movie.id), [
        for (var i = 1; i <= 30; i++) i,
      ]);
      expect(
        [for (final uri in requests) uri.queryParameters['page']],
        ['1', '2'],
      );
    });

    test('페이지 사이에 중복된 영화는 하나만 남긴다', () async {
      // 1페이지 1~20, 2페이지 15~34 (15~20 중복)
      final overlapped = [...manyMovies(20), ...manyMovies(34).skip(14)];
      final viewModel = MovieListViewModel(
        fakeTmdbService(results: overlapped),
      );

      final result = await viewModel.fetchUpToThirtyMovies();

      expect(result.map((movie) => movie.id).toSet().length, result.length);
      expect(result.length, 30);
    });

    test('결과가 30개보다 적으면 있는 만큼만 돌려준다', () async {
      final viewModel = MovieListViewModel(
        fakeTmdbService(results: manyMovies(12)),
      );

      expect(await viewModel.fetchUpToThirtyMovies(), hasLength(12));
    });
  });

  group('마지막 선택 장르', () {
    testWidgets('선택한 장르 id를 저장하고, 다시 들어오면 그 장르로 요청한다', (tester) async {
      final requests = <Uri>[];
      await tester.pumpWidget(
        _app(fakeTmdbService(requests: requests), key: UniqueKey()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('SF'));
      await tester.pumpAndSettle();

      expect(await GenrePreference().read(), 878);

      // 새 화면으로 다시 들어오기
      requests.clear();
      await tester.pumpWidget(
        _app(fakeTmdbService(requests: requests), key: UniqueKey()),
      );
      await tester.pumpAndSettle();
      expect(_discoverGenres(requests), ['878']);
      expect(find.text('우주의 끝에서'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsNothing);
    });

    test('저장된 값이 없거나 전체를 고르면 null을 돌려준다', () async {
      final preference = GenrePreference();
      expect(await preference.read(), isNull);

      await preference.save(18);
      expect(await preference.read(), 18);
      await preference.save(null);
      expect(await preference.read(), isNull);
    });
  });

  group('재설치 후 Secure Storage 정리', () {
    test('처음 실행할 때만 이전 설치의 값을 지운다', () async {
      FlutterSecureStorage.setMockInitialValues({'access_token': 'old'});
      const secureStorage = FlutterSecureStorage();

      await clearStaleSecureStorageOnFirstInstall();
      expect(await secureStorage.read(key: 'access_token'), isNull);
      expect(await SharedPreferencesAsync().getBool(firstInstallKey), isTrue);

      // 두 번째 실행부터는 로그인 후 저장한 값을 유지
      await secureStorage.write(key: 'access_token', value: 'new');
      await clearStaleSecureStorageOnFirstInstall();
      expect(await secureStorage.read(key: 'access_token'), 'new');
    });
  });
}
