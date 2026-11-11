import 'package:dio/dio.dart';

import 'package:movielog/data/services/sign_up_service.dart';

/// v6 공통 오류 형식 body를 만듭니다.
Map<String, Object?> fakeCommonError(String code, String message) => {
  'isSuccess': false,
  'code': code,
  'message': message,
  'result': null,
};

/// 서버 없이 v6 회원가입 API를 흉내 내는 [SignUpService]를 만듭니다.
///
/// 중복 확인 (GET)
/// - [taken]에 든 닉네임·이메일이면 { "available": false }, 아니면 true
/// - [fail]이 true면 연결 오류(DioException)
/// - [gate]가 있으면 그 Future가 끝날 때까지 응답을 미룸 — 늦은 응답 확인용
/// - [requests]에 보낸 요청 path를 순서대로 기록
///
/// 회원가입 (POST /v6/members)
/// - 기본은 201 + 공통 형식 result { memberId: [memberId], email, nickname }
/// - [signUpStatus]가 있으면 [signUpCode]·[signUpMessage]로 공통 오류 응답
/// - [signUpResult]가 false면 result를 null로 응답 — 계약 오류 확인용
/// - [signUpGate]가 있으면 그 Future가 끝날 때까지 응답을 미룸 — 제출 중 상태 확인용
/// - [bodies]에 보낸 요청 body를 기록
SignUpService fakeSignUpService({
  Set<String> taken = const {},
  bool fail = false,
  Future<void>? gate,
  List<String>? requests,
  int memberId = 42,
  int? signUpStatus,
  String signUpCode = 'COMMON409',
  String signUpMessage = '이미 사용 중인 이메일입니다.',
  bool signUpResult = true,
  Future<void>? signUpGate,
  List<Object?>? bodies,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          requests?.add(options.path);

          if (options.method == 'POST') {
            bodies?.add(options.data);
            if (signUpGate != null) await signUpGate;
            if (signUpStatus != null) {
              return handler.reject(
                DioException.badResponse(
                  statusCode: signUpStatus,
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: signUpStatus,
                    data: fakeCommonError(signUpCode, signUpMessage),
                  ),
                ),
              );
            }
            final body = options.data as Map<String, dynamic>;
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'isSuccess': true,
                  'code': 'COMMON201',
                  'message': '회원가입에 성공했습니다.',
                  'result': signUpResult
                      ? {
                          'memberId': memberId,
                          'email': body['email'],
                          'nickname': body['nickname'],
                        }
                      : null,
                },
              ),
            );
          }

          if (gate != null) await gate;

          if (fail) {
            return handler.reject(
              DioException.connectionError(
                requestOptions: options,
                reason: '테스트용 연결 실패',
              ),
            );
          }

          final value = Uri.decodeComponent(options.path.split('/').last);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'available': !taken.contains(value)},
            ),
          );
        },
      ),
    );
  return SignUpService(dio);
}
