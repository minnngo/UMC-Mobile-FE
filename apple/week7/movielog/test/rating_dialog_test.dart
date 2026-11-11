import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/submit_status.dart';
import 'package:movielog/widgets/rating_dialog.dart';

/// 평점 Dialog 안의 별 5개
Finder _stars() =>
    find.descendant(of: find.byType(Dialog), matching: find.byType(SvgPicture));

ButtonStyleButton _button(WidgetTester tester, String label) =>
    tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );

/// 화면 호출부와 같이 barrierDismissible: false로 Dialog를 열고 결과를 [onResult]로 받습니다.
Future<void> _open(
  WidgetTester tester,
  RatingDialog dialog,
  void Function(bool? result) onResult,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                onResult(
                  await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => dialog,
                  ),
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
}

/// [index]번째 별(0부터)의 왼쪽 끝을 누릅니다 — 반 점 모드였다면 x.5가 되는 위치
Future<void> _tapStarLeft(WidgetTester tester, int index) async {
  await tester.tapAt(
    tester.getRect(_stars().at(index)).centerLeft + const Offset(6, 0),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('별 5개는 W3-05 간격(48)을 유지하고, 반 칸을 눌러도 정수 점수가 된다', (tester) async {
    int? sentScore;
    await _open(
      tester,
      RatingDialog(onSubmit: (score, comment) async => sentScore = score),
      (_) {},
    );

    expect(_stars(), findsNWidgets(5));
    final centers = [
      for (var i = 0; i < 5; i++) tester.getCenter(_stars().at(i)).dx,
    ];
    for (var i = 1; i < 5; i++) {
      expect(centers[i] - centers[i - 1], closeTo(48, 0.01));
    }

    // 네 번째 별 왼쪽 → 반 점 모드면 3.5, 정수 모드라 4
    await _tapStarLeft(tester, 3);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(sentScore, 4);
  });

  testWidgets('W7-01 — 제목·코멘트 라벨·힌트, 별점을 고르기 전에는 코멘트를 써도 확인이 꺼져 있다', (
    tester,
  ) async {
    await _open(
      tester,
      RatingDialog(onSubmit: (score, comment) async {}),
      (_) {},
    );

    expect(find.text('평점을 남겨주세요'), findsOneWidget);
    expect(find.text('코멘트 (선택, 최대 500자)'), findsOneWidget);
    expect(find.text('이 영화의 인상적인 장면은...'), findsOneWidget);
    // 서버 score는 1~5 필수라 0점으로 되돌리는 링크는 두지 않습니다.
    expect(find.text('다시 선택하기'), findsNothing);
    // 취소·확인 버튼 높이 48
    final confirmBox = find
        .ancestor(of: find.text('확인'), matching: find.byType(SizedBox))
        .first;
    expect(tester.getSize(confirmBox).height, 48);

    await tester.enterText(find.byType(TextField), '좋았어요');
    await tester.pump();
    expect(_button(tester, '확인').onPressed, isNull);

    await _tapStarLeft(tester, 2);
    expect(_button(tester, '확인').onPressed, isNotNull);
  });

  testWidgets('확인 — 앞뒤 공백을 뺀 코멘트를 전달하고 true로 닫힌다, 빈 코멘트는 null', (tester) async {
    final sent = <(int, String?)>[];
    bool? result;
    await _open(
      tester,
      RatingDialog(
        onSubmit: (score, comment) async => sent.add((score, comment)),
      ),
      (value) => result = value,
    );

    await _tapStarLeft(tester, 4);
    await tester.enterText(find.byType(TextField), '  최고예요  ');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(sent.single, (5, '최고예요'));
    expect(result, isTrue);

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await _tapStarLeft(tester, 0);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(sent.last, (1, null));
  });

  testWidgets('취소 — onSubmit을 부르지 않고 false로 닫힌다', (tester) async {
    var calls = 0;
    bool? result;
    await _open(
      tester,
      RatingDialog(onSubmit: (score, comment) async => calls++),
      (value) => result = value,
    );

    await _tapStarLeft(tester, 2);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(result, isFalse);
  });

  testWidgets('저장 중에는 로딩·입력 잠금이고 뒤로가기로 닫히지 않는다', (tester) async {
    final gate = Completer<void>();
    bool? result;
    await _open(
      tester,
      RatingDialog(onSubmit: (score, comment) => gate.future),
      (value) => result = value,
    );

    await _tapStarLeft(tester, 2);
    await tester.tap(find.text('확인'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_button(tester, '취소').onPressed, isNull);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

    // 로딩 표시가 계속 돌므로 pumpAndSettle 대신 시간을 정해 그립니다.
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(RatingDialog), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(RatingDialog), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('저장 실패 — 닫히지 않고 서버 문구를 보여주며 입력이 그대로 남아 다시 시도할 수 있다', (
    tester,
  ) async {
    var failing = true;
    bool? result;
    await _open(
      tester,
      RatingDialog(
        onSubmit: (score, comment) async {
          if (failing) throw const WriteFailure('이미 이 영화에 평점을 남기셨습니다.');
        },
      ),
      (value) => result = value,
    );

    await _tapStarLeft(tester, 2);
    await tester.enterText(find.byType(TextField), '다시 볼래요');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

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
    expect(find.text('다시 볼래요'), findsOneWidget);
    expect(_button(tester, '확인').onPressed, isNotNull);

    failing = false;
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('수정 — 기존 별점·코멘트가 채워진 채로 열린다', (tester) async {
    (int, String?)? sent;
    await _open(
      tester,
      RatingDialog(
        title: '평점을 수정할까요?',
        initialScore: 3,
        initialComment: '다시 봐도 좋다',
        onSubmit: (score, comment) async => sent = (score, comment),
      ),
      (_) {},
    );

    expect(find.text('평점을 수정할까요?'), findsOneWidget);
    expect(find.text('다시 봐도 좋다'), findsOneWidget);
    // 별점이 이미 있으므로 바로 확인할 수 있습니다.
    expect(_button(tester, '확인').onPressed, isNotNull);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(sent, (3, '다시 봐도 좋다'));
  });
}
