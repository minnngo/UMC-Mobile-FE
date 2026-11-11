import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/genre_filter_sheet.dart';
import 'package:movielog/widgets/movie_rating_indicator.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/widgets/rating_dialog.dart';

/// 버튼을 누르면 [onPressed]를 실행하는 테스트용 화면
Widget _launcher(Future<void> Function(BuildContext context) onPressed) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => onPressed(context),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
}

/// 평점 Dialog 안의 별 (선택 전에는 5개)
Finder _dialogStars() =>
    find.descendant(of: find.byType(Dialog), matching: find.byType(SvgPicture));

void main() {
  testWidgets('MovieRatingIndicator는 별점 숫자를 소수 첫째 자리까지 표시한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MovieRatingIndicator(rating: 4.3)),
    );

    expect(find.text('4.3'), findsOneWidget);
  });

  testWidgets('RatingDialog는 선택한 별점을 반환한다', (tester) async {
    double? result;
    await tester.pumpWidget(
      _launcher((context) async {
        result = await showDialog<double>(
          context: context,
          builder: (context) => const RatingDialog(),
        );
      }),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('영화는 어떠셨나요?'), findsOneWidget);

    // 다섯 번째 별의 오른쪽 끝을 눌러 5점 선택 (가운데를 누르면 반 칸인 4.5)
    final lastStar = tester.getRect(_dialogStars().last);
    await tester.tapAt(lastStar.centerRight - const Offset(2, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(result, 5.0);
  });

  testWidgets('GenreFilterSheet는 체크한 장르를 반환한다', (tester) async {
    Set<String>? result;
    await tester.pumpWidget(
      _launcher((context) async {
        result = await GenreFilterSheet.show(context, selected: {'드라마'});
      }),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('액션'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(result, {'드라마', '액션'});
  });

  group('평점 Dialog (W3-05 / W3-06)', () {
    Finder dialogBox() => find
        .descendant(of: find.byType(Dialog), matching: find.byType(Material))
        .first;

    testWidgets('Figma 크기를 따르고, 선택값에 따라 확인 버튼이 켜지고 꺼진다', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      double? result = -1;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    result = await showDialog<double>(
                      context: context,
                      builder: (context) => const RatingDialog(),
                    );
                  },
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      // W3-05: 342 x 212, 화면 가운데 (top 316, left 24)
      expect(tester.getSize(dialogBox()), const Size(342, 212));
      expect(tester.getTopLeft(dialogBox()), const Offset(24, 316));

      // 제목 박스 위 24, 별 5개 — 별 높이 34.37, 중심 간격 48, 가운데 별 left 176.93
      expect(find.text('다시 선택하기'), findsNothing);
      final stars = _dialogStars();
      expect(stars, findsNWidgets(5));
      final centers = [
        for (var i = 0; i < 5; i++) tester.getCenter(stars.at(i)).dx,
      ];
      for (var i = 1; i < 5; i++) {
        expect(centers[i] - centers[i - 1], closeTo(48, 0.01));
      }
      expect(centers[2], closeTo(176.93 + 36.14 / 2, 0.01));
      expect(tester.getTopLeft(stars.at(2)).dy, closeTo(393, 0.05));

      // 확인 버튼 294 x 48, top 456
      final confirm = find.ancestor(
        of: find.text('확인'),
        matching: find.byType(ElevatedButton),
      );
      expect(tester.getSize(confirm), const Size(294, 48));
      expect(tester.getTopLeft(confirm).dy, closeTo(456, 0.01));

      // 별을 고르기 전에는 확인 버튼 비활성
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);

      // 네 번째 별 왼쪽을 누르면 3.5점 → W3-06: 342 x 260, 다시 선택하기 표시
      // 별 왼쪽 부분을 눌러 반 칸(3.5) 선택
      await tester.tapAt(
        tester.getRect(stars.at(3)).centerLeft + const Offset(6, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('다시 선택하기'), findsOneWidget);
      expect(tester.getSize(dialogBox()), const Size(342, 260));
      expect(tester.getTopLeft(dialogBox()).dy, 292);
      // 다시 선택하기 박스(81 x 19) top 432
      final resetBox = find.ancestor(
        of: find.text('다시 선택하기'),
        matching: find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.height == 19,
        ),
      );
      expect(tester.getTopLeft(resetBox).dy, closeTo(432, 0.05));

      // 다시 선택하기 → 0점, 링크 숨김, 다시 212
      await tester.tap(find.text('다시 선택하기'));
      await tester.pumpAndSettle();
      expect(find.text('다시 선택하기'), findsNothing);
      expect(tester.getSize(dialogBox()), const Size(342, 212));

      // 0점이면 확인 버튼 비활성
      ElevatedButton confirmButton() => tester.widget<ElevatedButton>(confirm);
      expect(confirmButton().onPressed, isNull);

      // 다시 별을 고르면 확인 버튼 활성 → 선택값 반환
      // 별 왼쪽 부분을 눌러 반 칸(3.5) 선택
      await tester.tapAt(
        tester.getRect(stars.at(3)).centerLeft + const Offset(6, 0),
      );
      await tester.pumpAndSettle();
      expect(confirmButton().onPressed, isNotNull);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(result, 3.5);
    });
  });

  group('MovieLogButton', () {
    Widget button(MovieLogButton child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );

    ElevatedButton inner(WidgetTester tester) =>
        tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    testWidgets('기본 상태에서는 글자를 보여주고 누르면 onPressed를 실행한다', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        button(MovieLogButton(label: '중복 확인', onPressed: () => pressed++)),
      );

      await tester.tap(find.text('중복 확인'));
      expect(pressed, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('통신 중이면 로딩 표시만 그리고 누를 수 없다', (tester) async {
      await tester.pumpWidget(
        button(
          MovieLogButton(label: '중복 확인', onPressed: () {}, isLoading: true),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('중복 확인'), findsNothing);
      expect(inner(tester).onPressed, isNull);
    });

    testWidgets('onPressed가 null이면 비활성 상태다', (tester) async {
      await tester.pumpWidget(
        button(const MovieLogButton(label: '가입하기', onPressed: null)),
      );

      expect(inner(tester).onPressed, isNull);
    });

    testWidgets('width로 가변·최대·고정 너비를 정한다', (tester) async {
      Future<double> widthOf(double? width) async {
        await tester.pumpWidget(
          button(MovieLogButton(label: '확인', onPressed: () {}, width: width)),
        );
        return tester.getSize(find.byType(MovieLogButton)).width;
      }

      final fitted = await widthOf(null);
      expect(fitted, lessThan(200));
      expect(await widthOf(double.infinity), 800);
      expect(await widthOf(120), 120);
      expect(tester.getSize(find.byType(MovieLogButton)).height, 44);
    });

    testWidgets('width가 null이면 Row 안 입력창 옆에서 글자 길이만큼만 차지한다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Row(
              children: [
                const Expanded(child: TextField()),
                const SizedBox(width: 8),
                MovieLogButton(label: '중복 확인', onPressed: () {}),
              ],
            ),
          ),
        ),
      );

      final buttonWidth = tester.getSize(find.byType(MovieLogButton)).width;
      expect(buttonWidth, lessThan(200));
      expect(
        tester.getSize(find.byType(TextField)).width,
        800 - 8 - buttonWidth,
      );
    });
  });
}
