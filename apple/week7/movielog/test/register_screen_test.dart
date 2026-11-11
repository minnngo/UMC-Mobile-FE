import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/screens/register_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';

import 'fake_sign_up.dart';

/// 라우터와 같은 방식으로 회원가입 ViewModel을 만들어 붙입니다.
Future<void> _pumpRegister(WidgetTester tester, SignUpService service) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: ChangeNotifierProvider<SignUpViewModel>(
        create: (_) => SignUpViewModel(service),
        child: const RegisterScreen(),
      ),
    ),
  );
}

Finder get _nicknameField => find.byType(TextFormField).at(0);
Finder get _emailField => find.byType(TextFormField).at(1);

/// 0: 닉네임 옆, 1: 이메일 옆 중복 확인 버튼
ElevatedButton _checkButton(WidgetTester tester, int index) =>
    tester.widget<ElevatedButton>(
      find
          .descendant(
            of: find.byType(MovieLogButton),
            matching: find.byType(ElevatedButton),
          )
          .at(index),
    );

void main() {
  testWidgets('중복 확인 버튼은 입력창 옆에서 글자 길이만큼만 차지한다', (tester) async {
    await _pumpRegister(tester, fakeSignUpService());

    final button = find.byType(MovieLogButton).first;
    final buttonWidth = tester.getSize(button).width;
    expect(buttonWidth, lessThan(150));
    // 입력창(Expanded)이 남은 너비를 모두 사용 — 화면 390 - 좌우 16 x 2 - 간격 10
    expect(tester.getSize(_nicknameField).width, 390 - 32 - 10 - buttonWidth);
    // 입력창·버튼 높이 44 (W6-01)
    expect(tester.getSize(_nicknameField).height, 44);
    expect(tester.getSize(button).height, 44);
  });

  testWidgets('형식이 맞지 않으면 중복 확인 버튼이 비활성이다', (tester) async {
    await _pumpRegister(tester, fakeSignUpService());
    expect(_checkButton(tester, 0).onPressed, isNull);

    await tester.enterText(_nicknameField, '밍');
    await tester.pump();
    expect(_checkButton(tester, 0).onPressed, isNull);

    await tester.enterText(_nicknameField, '밍고');
    await tester.pump();
    expect(_checkButton(tester, 0).onPressed, isNotNull);
  });

  testWidgets('확인 중에는 버튼에 로딩을 보여주고, 사용 가능하면 안내 문구를 보여준다', (tester) async {
    final gate = Completer<void>();
    await _pumpRegister(tester, fakeSignUpService(gate: gate.future));

    await tester.enterText(_nicknameField, '밍고');
    await tester.pump();
    await tester.tap(find.text('중복 확인').first);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_checkButton(tester, 0).onPressed, isNull);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('사용 가능한 닉네임입니다.'), findsOneWidget);
  });

  testWidgets('중복이면 에러로 바뀌고, 입력을 바꾸면 사라지고, 같은 값을 다시 입력하면 바로 에러', (
    tester,
  ) async {
    final requests = <String>[];
    await _pumpRegister(
      tester,
      fakeSignUpService(taken: {'무비러버'}, requests: requests),
    );

    await tester.enterText(_nicknameField, '무비러버');
    await tester.pump();
    await tester.tap(find.text('중복 확인').first);
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    expect(_checkButton(tester, 0).onPressed, isNull);

    await tester.enterText(_nicknameField, '무비러버2');
    await tester.pump();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);
    expect(_checkButton(tester, 0).onPressed, isNotNull);

    await tester.enterText(_nicknameField, '무비러버');
    await tester.pump();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    // 서버에 다시 묻지 않고 버튼도 바로 비활성
    expect(_checkButton(tester, 0).onPressed, isNull);
    expect(requests, hasLength(1));
  });

  testWidgets('이메일도 중복값을 지웠다가 같은 값을 입력하면 요청 없이 바로 에러·버튼 비활성', (tester) async {
    final requests = <String>[];
    await _pumpRegister(
      tester,
      fakeSignUpService(taken: {'movie@umc.com'}, requests: requests),
    );

    await tester.enterText(_emailField, 'movie@umc.com');
    await tester.pump();
    await tester.tap(find.text('중복 확인').last);
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
    expect(_checkButton(tester, 1).onPressed, isNull);

    // 한 글자 지우는 동안에는 에러가 사라지고 다시 확인할 수 있음
    await tester.enterText(_emailField, 'movie@umc.co');
    await tester.pump();
    expect(find.text('이미 사용 중인 이메일입니다.'), findsNothing);
    expect(_checkButton(tester, 1).onPressed, isNotNull);

    await tester.enterText(_emailField, 'movie@umc.com');
    await tester.pump();
    expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
    expect(_checkButton(tester, 1).onPressed, isNull);
    expect(requests, hasLength(1));
  });

  testWidgets('통신이 실패하면 다시 시도 안내를 보여주고 버튼을 다시 누를 수 있다', (tester) async {
    await _pumpRegister(tester, fakeSignUpService(fail: true));

    await tester.enterText(_emailField, 'mingo@example.com');
    await tester.pump();
    await tester.tap(find.text('중복 확인').last);
    await tester.pumpAndSettle();

    expect(find.text('중복 확인에 실패했습니다. 다시 시도해 주세요.'), findsOneWidget);
    expect(_checkButton(tester, 1).onPressed, isNotNull);
  });

  testWidgets('닉네임 중복 결과는 이메일 칸에 영향을 주지 않는다', (tester) async {
    await _pumpRegister(tester, fakeSignUpService(taken: {'무비러버'}));

    await tester.enterText(_nicknameField, '무비러버');
    await tester.enterText(_emailField, 'mingo@example.com');
    await tester.pump();
    await tester.tap(find.text('중복 확인').first);
    await tester.tap(find.text('중복 확인').last);
    await tester.pumpAndSettle();

    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    expect(find.text('사용 가능한 이메일입니다.'), findsOneWidget);
  });
}
