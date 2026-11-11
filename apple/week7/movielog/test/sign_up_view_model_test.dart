import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

import 'fake_sign_up.dart';

void main() {
  group('닉네임 중복 확인', () {
    test('사용 가능하면 available, 에러 문구 없음', () async {
      final requests = <String>[];
      final viewModel = SignUpViewModel(fakeSignUpService(requests: requests));

      viewModel.onNicknameChanged(' 무비러버 ');
      await viewModel.checkNickname(' 무비러버 ');

      expect(viewModel.nicknameCheckStatus, CheckStatus.available);
      expect(viewModel.nicknameErrorText, isNull);
      // 앞뒤 공백을 뺀 값을 인코딩해 /v6 경로로 요청
      expect(requests, ['/v6/members/nickname/${Uri.encodeComponent('무비러버')}']);
    });

    test('요청 중에는 checking이고 버튼을 다시 누를 수 없다', () async {
      final gate = Completer<void>();
      final viewModel = SignUpViewModel(fakeSignUpService(gate: gate.future));

      viewModel.onNicknameChanged('무비러버');
      final pending = viewModel.checkNickname('무비러버');

      expect(viewModel.nicknameCheckStatus, CheckStatus.checking);
      expect(viewModel.canCheckNickname, isFalse);

      gate.complete();
      await pending;
      expect(viewModel.nicknameCheckStatus, CheckStatus.available);
    });

    test('중복이면 duplicated와 에러 문구, 버튼 비활성', () async {
      final viewModel = SignUpViewModel(fakeSignUpService(taken: {'무비러버'}));

      viewModel.onNicknameChanged('무비러버');
      await viewModel.checkNickname('무비러버');

      expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
      expect(viewModel.nicknameErrorText, '이미 사용 중인 닉네임입니다.');
      expect(viewModel.canCheckNickname, isFalse);
    });

    test('통신이 실패하면 error — available: false와 구분한다', () async {
      final viewModel = SignUpViewModel(fakeSignUpService(fail: true));

      viewModel.onNicknameChanged('무비러버');
      await viewModel.checkNickname('무비러버');

      expect(viewModel.nicknameCheckStatus, CheckStatus.error);
      expect(viewModel.nicknameErrorText, '중복 확인에 실패했습니다. 다시 시도해 주세요.');
      // 실패 후에는 다시 시도할 수 있음
      expect(viewModel.canCheckNickname, isTrue);
    });

    test('입력을 바꾸면 이전 결과가 사라지고, 중복값을 다시 입력하면 API 없이 바로 에러', () async {
      final requests = <String>[];
      final viewModel = SignUpViewModel(
        fakeSignUpService(taken: {'무비러버'}, requests: requests),
      );

      viewModel.onNicknameChanged('무비러버');
      await viewModel.checkNickname('무비러버');
      expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);

      viewModel.onNicknameChanged('무비러버2');
      expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
      expect(viewModel.nicknameErrorText, isNull);

      viewModel.onNicknameChanged('무비러버');
      expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
      expect(viewModel.nicknameErrorText, '이미 사용 중인 닉네임입니다.');
      expect(requests, hasLength(1));
    });

    test('사용 가능 확인 후 입력을 바꾸면 idle로 돌아간다', () async {
      final viewModel = SignUpViewModel(fakeSignUpService());

      viewModel.onNicknameChanged('무비러버');
      await viewModel.checkNickname('무비러버');
      viewModel.onNicknameChanged('무비러버2');

      expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
    });

    test('응답을 기다리는 중 입력을 바꾸면 늦은 응답을 무시한다', () async {
      final gate = Completer<void>();
      final viewModel = SignUpViewModel(
        fakeSignUpService(taken: {'무비러버'}, gate: gate.future),
      );

      viewModel.onNicknameChanged('무비러버');
      final pending = viewModel.checkNickname('무비러버');
      viewModel.onNicknameChanged('무비러버2');

      gate.complete();
      await pending;
      expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
      expect(viewModel.nicknameErrorText, isNull);
    });

    test('빈 값이나 현재 입력과 다른 값은 요청하지 않는다', () async {
      final requests = <String>[];
      final viewModel = SignUpViewModel(fakeSignUpService(requests: requests));

      viewModel.onNicknameChanged('   ');
      await viewModel.checkNickname('   ');
      viewModel.onNicknameChanged('무비러버');
      await viewModel.checkNickname('다른값');

      expect(requests, isEmpty);
      expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
    });

    test('응답 전에 dispose되면 결과를 반영하지 않는다', () async {
      final gate = Completer<void>();
      final viewModel = SignUpViewModel(fakeSignUpService(gate: gate.future));

      viewModel.onNicknameChanged('무비러버');
      final pending = viewModel.checkNickname('무비러버');
      viewModel.dispose();

      gate.complete();
      await pending;
      expect(viewModel.nicknameCheckStatus, CheckStatus.checking);
    });
  });

  group('이메일 중복 확인', () {
    test('이메일은 /v6/members/email 경로로 확인하고 중복이면 에러 문구', () async {
      final requests = <String>[];
      final viewModel = SignUpViewModel(
        fakeSignUpService(taken: {'movie+log@umc.com'}, requests: requests),
      );

      viewModel.onEmailChanged('movie+log@umc.com');
      await viewModel.checkEmail('movie+log@umc.com');

      expect(viewModel.emailCheckStatus, CheckStatus.duplicated);
      expect(viewModel.emailErrorText, '이미 사용 중인 이메일입니다.');
      // + 와 @ 도 인코딩
      expect(requests, ['/v6/members/email/movie%2Blog%40umc.com']);
    });

    test('닉네임 결과와 이메일 결과는 서로 영향을 주지 않는다', () async {
      final viewModel = SignUpViewModel(fakeSignUpService(taken: {'무비러버'}));

      viewModel.onNicknameChanged('무비러버');
      viewModel.onEmailChanged('new@umc.com');
      await viewModel.checkNickname('무비러버');
      await viewModel.checkEmail('new@umc.com');

      expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
      expect(viewModel.emailCheckStatus, CheckStatus.available);
      expect(viewModel.emailErrorText, isNull);

      // 이메일 입력을 바꿔도 닉네임 중복 상태는 그대로
      viewModel.onEmailChanged('other@umc.com');
      expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
      expect(viewModel.emailCheckStatus, CheckStatus.idle);
    });
  });

  group('회원가입 제출', () {
    const request = CreateMemberRequest(
      email: 'movie@umc.com',
      password: 'Password1!',
      nickname: '무비러버',
    );

    test('201이면 result의 memberId를 createdMemberId에 담는다', () async {
      final viewModel = SignUpViewModel(fakeSignUpService(memberId: 77));

      await viewModel.submit(request);

      expect(viewModel.submitStatus, SubmitStatus.success);
      expect(viewModel.createdMemberId, 77);
      expect(viewModel.snackbarMessage, isNull);
    });

    test('제출 중에는 submitting이고, 다시 눌러도 요청을 한 번만 보낸다', () async {
      final gate = Completer<void>();
      final bodies = <Object?>[];
      final viewModel = SignUpViewModel(
        fakeSignUpService(signUpGate: gate.future, bodies: bodies),
      );

      final first = viewModel.submit(request);
      expect(viewModel.isSubmitting, isTrue);
      await viewModel.submit(request);
      gate.complete();
      await first;

      expect(bodies, hasLength(1));
      expect(viewModel.submitStatus, SubmitStatus.success);
    });

    test('400 비밀번호 형식 위반은 비밀번호 칸 오류, 입력을 바꾸면 사라진다', () async {
      const message = '비밀번호는 대문자/소문자/숫자/특수문자를 포함한 8자 이상이어야 합니다.';
      final viewModel = SignUpViewModel(
        fakeSignUpService(
          signUpStatus: 400,
          signUpCode: 'COMMON400',
          signUpMessage: message,
        ),
      );

      await viewModel.submit(request);

      expect(viewModel.submitStatus, SubmitStatus.error);
      expect(viewModel.passwordErrorText, message);
      expect(viewModel.snackbarMessage, isNull);
      expect(viewModel.createdMemberId, isNull);

      viewModel.onPasswordChanged();
      expect(viewModel.passwordErrorText, isNull);
    });

    test('409 최종 중복은 서버 message를 Snackbar 문구로 둔다', () async {
      final viewModel = SignUpViewModel(
        fakeSignUpService(signUpStatus: 409, signUpMessage: '이미 사용 중인 닉네임입니다.'),
      );

      await viewModel.submit(request);

      expect(viewModel.submitStatus, SubmitStatus.error);
      expect(viewModel.snackbarMessage, '이미 사용 중인 닉네임입니다.');
      expect(viewModel.passwordErrorText, isNull);
    });

    test('201인데 result가 null이면 가입 완료로 표시하지 않는다', () async {
      final viewModel = SignUpViewModel(fakeSignUpService(signUpResult: false));

      await viewModel.submit(request);

      expect(viewModel.submitStatus, SubmitStatus.error);
      expect(viewModel.createdMemberId, isNull);
      expect(viewModel.snackbarMessage, contains('가입 결과를 확인하지 못했습니다'));
    });
  });
}
