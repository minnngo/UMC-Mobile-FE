import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 워크북 자체 백엔드 전용 Dio Client를 만듭니다.
///
/// TMDB와 baseUrl·헤더가 달라 `createTmdbClient()`와 절대 합치지 않습니다.
/// 경로에 버전(/v6)을 붙이는 것은 각 Service가 담당합니다.
/// TMDB Token은 이 Client에 절대 넣지 않습니다.
Dio createMovieLogClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://workbook.devnoco.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // 로그는 개발 중 확인용이라 debug 모드에서만 남깁니다.
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        // 회원가입 body에 비밀번호가 있으므로 요청 body는 로그에 남기지 않습니다.
        requestBody: false,
        responseBody: true,
        logPrint: (object) => debugPrint('$object'),
      ),
    );
  }

  return dio;
}
