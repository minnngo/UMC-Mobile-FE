import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/profile_stat.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/svg_icon_button.dart';
import '../widgets/tag_chip.dart';

/// 마이 탭 — 1주차 W1-01 내 프로필 화면을 가져왔습니다.
///
/// 화면은 의미 단위로 나뉩니다.
/// - [AppHeader] 내 프로필, 내 정보 버튼
/// - [_ProfileHeader] 프로필 사진, 닉네임, 소개, 프로필 수정 버튼
/// - [_ProfileStats] 본 영화·평점·즐겨찾기 통계
/// - [_FavoriteGenres] 선호하는 장르
/// - [_MyRatingsEntry] 내가 등록한 평점 화면으로 이동 (6주차)
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // 헤더 — 390 x 64, 제목 Manrope 500 / 22 / 28 #6750A4
      appBar: AppHeader(
        title: '내 프로필',
        titleStyle: textTheme.titleLarge?.copyWith(color: colors.primary),
        trailing: SvgIconButton(
          asset: 'assets/icons/person.svg',
          iconSize: const Size(24, 24),
          color: colors.primary,
          tooltip: '내 정보',
          onPressed: () {}, // 아직 동작을 연결하지 않습니다.
        ),
      ),
      // 메인 컨텐츠 — padding 24 / 16, 섹션 사이 gap 32
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(),
            SizedBox(height: 32),
            _ProfileStats(),
            // W6-ENTRY — 통계 아래 26, 선호하는 장르 위 28
            SizedBox(height: 26),
            _MyRatingsEntry(),
            SizedBox(height: 28),
            _FavoriteGenres(),
          ],
        ),
      ),
    );
  }
}

/// Section - Profile Header Area — 358 x 294, gap 16
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // border — 128 x 128, 테두리 2px, 이미지 124 x 124
        Container(
          width: 128,
          height: 128,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: AppColors.avatarBorder, width: 2),
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/profile/profile_movielog.jpg',
              width: 124,
              height: 124,
              fit: BoxFit.cover,
              // 프로필 이미지가 없으면 기본 Icon을 보여줍니다.
              errorBuilder: (context, error, stackTrace) => Container(
                width: 124,
                height: 124,
                color: colors.primaryContainer,
                alignment: Alignment.center,
                child: Icon(Icons.person, size: 64, color: colors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 무비러버 + 설명 컨테이너 — 318 너비, gap 8
        SizedBox(
          width: 318,
          child: Column(
            children: [
              Text(
                '무비러버',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋은 영화를 보고 기록하는 것을 좋아합니다.',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 버튼 마진 — padding-top 8
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: _EditProfileButton(),
        ),
      ],
    );
  }
}

/// 프로필 수정 버튼 — 127 x 42, radius 8, 테두리 1px #6750A4
/// 1주차 테마의 TextButton 스타일을 이 버튼에만 적용합니다.
class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextButton(
      onPressed: () {}, // 프로필 수정 화면은 아직 연결하지 않습니다.
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.primary),
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        textStyle: Theme.of(context).textTheme.titleMedium,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('프로필 수정'),
    );
  }
}

/// Section - Statistics Bento Grid — 358 x 86, gap 8
class _ProfileStats extends StatelessWidget {
  const _ProfileStats();

  static const List<ProfileStat> stats = [
    ProfileStat(label: '본 영화', value: '342'),
    ProfileStat(label: '평점', value: '4.2'),
    ProfileStat(label: '즐겨찾기', value: '58'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        for (final stat in stats)
          Expanded(
            child: _StatItem(label: stat.label, value: stat.value),
          ),
      ],
    );
  }
}

/// 통계 항목 하나 — 114 x 86, padding 16, radius 12, 테두리 1px
class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        border: Border.all(color: colors.primaryContainer),
        borderRadius: BorderRadius.circular(AppTheme.statRadius),
      ),
      child: Column(
        children: [
          Text(value, textAlign: TextAlign.center, style: AppTheme.statValue),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// 선호하는 장르 섹션 — 358 x 72, gap 16
class _FavoriteGenres extends StatelessWidget {
  const _FavoriteGenres();

  static const List<String> genres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('선호하는 장르', style: textTheme.titleMedium),
        const SizedBox(height: 16),
        // 태그 컨테이너 — gap 8
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final genre in genres)
              // 태그 칩 하나 — 66 x 32, padding 8 / 16, 배경 #E9DDFF, 글자 #4F378A
              TagChip(
                label: genre,
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                textStyle: textTheme.bodySmall,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 내가 등록한 평점 진입 카드 — 358 x 64, 배경 #FFFFFF, 테두리 1.5px #D6C9E8 (W6-ENTRY)
/// 누르면 하단 탭 없이 /my/ratings 화면을 위에 띄웁니다.
class _MyRatingsEntry extends StatelessWidget {
  const _MyRatingsEntry();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: AppColors.entryCardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.statRadius),
        side: const BorderSide(color: AppColors.entryCardBorder, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/my/ratings'),
        child: SizedBox(
          height: 64,
          child: Padding(
            // 글자 왼쪽 19, 꺾쇠 오른쪽 18 (카드 바깥 기준)
            padding: const EdgeInsets.only(left: 19, right: 18),
            child: Row(
              children: [
                const Expanded(
                  child: Text('내가 등록한 평점', style: AppTheme.entryCardTitle),
                ),
                CustomPaint(
                  size: const Size(8, 14),
                  painter: _ChevronPainter(color: colors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 오른쪽 꺾쇠 — 8 x 14, 선 2.5px, 끝은 둥글게
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color});

  final Color color;

  static const _strokeWidth = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    // 선 두께가 8 x 14 밖으로 나가지 않도록 절반만큼 안쪽에 그립니다.
    const inset = _strokeWidth / 2;
    final path = Path()
      ..moveTo(inset, inset)
      ..lineTo(size.width - inset, size.height / 2)
      ..lineTo(inset, size.height - inset);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) => oldDelegate.color != color;
}
