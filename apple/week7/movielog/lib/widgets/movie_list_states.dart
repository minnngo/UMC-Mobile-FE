import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

import 'movielog_button.dart';

/// 영화 목록을 불러오는 중 — 빈 화면 대신 진행 표시를 보여줍니다.
class MovieListLoading extends StatelessWidget {
  const MovieListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// 불러온 영화가 없거나 선택한 장르에 맞는 영화가 없을 때
class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('조건에 맞는 영화가 없습니다.'));
  }
}

/// 불러오기 실패 — 오류 내용 대신 안내 문구와 다시 시도 버튼을 보여줍니다.
///
/// 다시 시도는 가운데 놓이는 단독 버튼이라 문구·화면 크기와 관계없이
/// 항상 같은 크기가 되도록 [MovieLogButton]에 고정 너비를 줍니다.
class MovieListError extends StatelessWidget {
  const MovieListError({super.key, this.message, required this.onRetry});

  /// 사용자에게 보여줄 안내 문구 — null이면 기본 문구
  final String? message;
  final VoidCallback onRetry;

  static const double _retryButtonWidth = 120;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // 좌우 32 여백 안에서 가운데 정렬 — 긴 안내 문구가 화면 끝에 붙지 않게 합니다.
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 28, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message ?? '영화를 불러오지 못했습니다.',
              textAlign: TextAlign.center,
              style: AppTheme.dialogBody.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: 20),
            MovieLogButton(
              label: '다시 시도',
              width: _retryButtonWidth,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
