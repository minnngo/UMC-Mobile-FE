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
Finder get _passwordField => find.byType(TextFormField).at(2);

ElevatedButton _submitButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(
      find
          .descendant(
            of: find.byType(MovieLogButton),
            matching: find.byType(ElevatedButton),
          )
          .last,
    );

/// 형식·중복 확인·약관을 모두 통과시켜 가입하기를 켭니다.
Future<void> _fillValidForm(WidgetTester tester) async {
  await tester.enterText(_nicknameField, '무비러버');
  await tester.enterText(_emailField, 'movie@umc.com');
  await tester.enterText(_passwordField, 'Password1!');
  await tester.pump();
  await tester.tap(find.text('중복 확인').first);
  await tester.tap(find.text('중복 확인').last);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('필수 약관에 동의합니다'));
  await tester.tap(find.text('필수 약관에 동의합니다'));
  await tester.pumpAndSettle();
}

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(find.text('가입하기'));
  await tester.tap(find.text('가입하기'));
}

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

  group('비밀번호 형식 (서버 규칙과 동일)', () {
    Future<void> expectPasswordError(
      WidgetTester tester,
      String password,
      String? error,
    ) async {
      await tester.enterText(_passwordField, password);
      await tester.pump();
      if (error == null) {
        expect(find.textContaining('비밀번호'), findsWidgets);
        expect(find.textContaining('포함해야 합니다'), findsNothing);
      } else {
        expect(find.text(error), findsOneWidget);
      }
    }

    testWidgets('대문자·소문자·숫자·특수문자가 모두 있어야 하고 앞뒤 공백은 안 된다', (tester) async {
      await _pumpRegister(tester, fakeSignUpService());
      const mixError = '대문자·소문자·숫자·특수문자(!@#\$%^&*)를 모두 포함해야 합니다.';

      await expectPasswordError(tester, 'password1!', mixError);
      await expectPasswordError(tester, 'Password!!', mixError);
      await expectPasswordError(tester, 'Password12', mixError);
      await expectPasswordError(tester, 'Pass1!', '비밀번호는 8자 이상이어야 합니다.');
      await expectPasswordError(
        tester,
        ' Password1!',
        '비밀번호 앞뒤에 공백을 넣을 수 없습니다.',
      );
      await expectPasswordError(tester, 'Password1!', null);
    });
  });

  group('가입하기 제출', () {
    testWidgets('제출 중에는 버튼 로딩·입력 잠금, 뒤로가기로 나갈 수 없다', (tester) async {
      final gate = Completer<void>();
      await _pumpRegister(
        tester,
        fakeSignUpService(signUpGate: gate.future, signUpStatus: 409),
      );
      await _fillValidForm(tester);

      await _tapSubmit(tester);
      await tester.pump();
      expect(_submitButton(tester).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).readOnly,
        isTrue,
      );

      // 헤더 뒤로가기와 시스템 뒤로가기 모두 무시 — 회원가입 화면 그대로
      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('환영합니다!'), findsOneWidget);

      // 409로 끝나도록 해 GoRouter 없이 화면에 남깁니다.
      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('409 최종 중복이면 서버 문구 Snackbar, 입력은 그대로 남는다', (tester) async {
      await _pumpRegister(
        tester,
        fakeSignUpService(signUpStatus: 409, signUpMessage: '이미 사용 중인 이메일입니다.'),
      );
      await _fillValidForm(tester);

      await _tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('이미 사용 중인 이메일입니다.'),
        ),
        findsOneWidget,
      );
      expect(find.text('movie@umc.com'), findsOneWidget);
      expect(find.text('무비러버'), findsOneWidget);
      // 다시 시도할 수 있도록 버튼이 다시 켜짐
      expect(_submitButton(tester).onPressed, isNotNull);
    });

    testWidgets('400 비밀번호 오류는 비밀번호 칸에 붙고, 고치면 사라진다', (tester) async {
      const message = '비밀번호는 대문자/소문자/숫자/특수문자를 포함한 8자 이상이어야 합니다.';
      await _pumpRegister(
        tester,
        fakeSignUpService(
          signUpStatus: 400,
          signUpCode: 'COMMON400',
          signUpMessage: message,
        ),
      );
      await _fillValidForm(tester);

      await _tapSubmit(tester);
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      await tester.enterText(_passwordField, 'Password2!');
      await tester.pump();
      expect(find.text(message), findsNothing);
    });
  });
}
