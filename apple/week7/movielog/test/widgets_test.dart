import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/genre_filter_sheet.dart';
import 'package:movielog/widgets/movie_rating_indicator.dart';
import 'package:movielog/widgets/movielog_button.dart';

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

void main() {
  testWidgets('MovieRatingIndicator는 별점 숫자를 소수 첫째 자리까지 표시한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MovieRatingIndicator(rating: 4.3)),
    );

    expect(find.text('4.3'), findsOneWidget);
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
