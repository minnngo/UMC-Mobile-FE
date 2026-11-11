import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../view_models/learning_member_session.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({
    super.key,
    this.tmdbMovieService,
    this.signUpService,
    this.ratingApiService,
    this.learningMemberSession,
  });

  /// 테스트에서 가짜 TMDB 응답을 쓰기 위해 바꿔 넣을 수 있습니다. null이면 실제 TMDB를 호출합니다.
  final TmdbMovieService? tmdbMovieService;

  /// 테스트에서 가짜 중복 확인·회원가입 응답을 쓰기 위해 바꿔 넣을 수 있습니다. null이면 자체 서버를 호출합니다.
  final SignUpService? signUpService;

  /// 테스트에서 가짜 평점 조회·쓰기 응답을 쓰기 위해 바꿔 넣을 수 있습니다. null이면 자체 서버를 호출합니다.
  final RatingApiService? ratingApiService;

  /// 테스트에서 이미 가입한 학습용 회원으로 시작하기 위해 바꿔 넣을 수 있습니다.
  final LearningMemberSession? learningMemberSession;

  @override
  Widget build(BuildContext context) {
    // 여러 화면(Route)이 함께 쓰는 객체는 MaterialApp.router 위에 등록합니다.
    // Service는 상태가 없으므로 인스턴스 하나를 모든 ViewModel이 공유합니다.
    // 회원가입과 평점 조회·쓰기는 같은 워크북 백엔드라 Dio 하나를 함께 씁니다.
    final movieLogClient = createMovieLogClient();

    return MultiProvider(
      providers: [
        // 회원가입으로 얻은 학습용 memberId — 영화 상세·마이페이지 Route가 같은 값을 읽습니다.
        ChangeNotifierProvider<LearningMemberSession>(
          create: (_) => learningMemberSession ?? LearningMemberSession(),
        ),
        Provider<TmdbMovieService>(
          create: (_) =>
              tmdbMovieService ?? TmdbMovieService(createTmdbClient()),
        ),
        Provider<SignUpService>(
          create: (_) => signUpService ?? SignUpService(movieLogClient),
        ),
        Provider<RatingApiService>(
          create: (_) => ratingApiService ?? RatingApiService(movieLogClient),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
