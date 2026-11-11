import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/sign_up_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../models/movie_detail.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/register_screen.dart';
import '../screens/start_screen.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';

/// 앱에서 사용하는 Route를 한곳에서 관리하는 클래스
class AppRouter {
  AppRouter._();

  /// root Navigator — 하단 탭(ShellRoute) 바깥에 전체 화면으로 띄울 Route가 사용합니다.
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: '/start',
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
          create: (context) => SignUpViewModel(context.read<SignUpService>()),
          child: const RegisterScreen(),
        ),
      ),
      // 영화 상세 — 하단 탭 없이 전체 화면으로 표시 (예: /movies/969681)
      // 경로의 movieId는 TMDB id이고, ViewModel이 TMDB 상세를 불러옵니다.
      // 상세 정보를 extra로 함께 받으면(홈 추천 신작 Mock) 그대로 보여줍니다.
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          final movieId = int.tryParse(state.pathParameters['movieId'] ?? '');
          final detail = state.extra;
          if (detail is MovieDetail) {
            return MovieDetailScreen(movieId: movieId, detail: detail);
          }
          return ChangeNotifierProvider<MovieDetailViewModel>(
            create: (context) => MovieDetailViewModel(
              context.read<TmdbMovieService>(),
              movieId: movieId,
            )..load(),
            child: MovieDetailScreen(movieId: movieId),
          );
        },
      ),
      // 하단 탭(홈/영화/마이)을 공유하는 화면들
      ShellRoute(
        builder: (context, state, child) {
          return MainScreen(
            currentIndex: indexFromLocation(state.uri.path),
            child: child,
          );
        },
        routes: [
          // 화면마다 ViewModel을 따로 만들고, 화면을 벗어나면 dispose합니다.
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                ChangeNotifierProvider<MovieHomeViewModel>(
                  create: (context) =>
                      MovieHomeViewModel(context.read<TmdbMovieService>())
                        ..loadPopular(),
                  child: const HomeScreen(),
                ),
          ),
          GoRoute(
            path: '/movies',
            builder: (context, state) =>
                ChangeNotifierProvider<MovieListViewModel>(
                  create: (context) =>
                      MovieListViewModel(context.read<TmdbMovieService>())
                        ..loadInitial(),
                  child: const MovieListScreen(),
                ),
          ),
          GoRoute(
            path: '/my',
            builder: (context, state) => const MyPageScreen(),
            routes: [
              // 내가 등록한 평점 (최종 경로 /my/ratings)
              // root Navigator 위에 push해 하단 NavigationBar를 가립니다.
              // 7주차 — 6주차 고정 ID 1 대신 회원가입으로 얻은 학습용 memberId를 씁니다.
              GoRoute(
                path: 'ratings',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final id = context.read<LearningMemberSession>().memberId;
                  if (id == null) return const MyRatingsSignUpRequired();
                  return ChangeNotifierProvider<MyRatingsViewModel>(
                    create: (context) => MyRatingsViewModel(
                      context.read<RatingApiService>(),
                      context.read<TmdbMovieService>(),
                      id,
                    )..load(),
                    child: const MyRatingsScreen(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );

  static int indexFromLocation(String path) {
    if (path.startsWith('/movies')) return 1;
    if (path.startsWith('/my')) return 2;

    return 0;
  }
}
