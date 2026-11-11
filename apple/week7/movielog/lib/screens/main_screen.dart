import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  final int currentIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: currentIndex,
        onSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/movies');
              break;
            case 2:
              context.go('/my');
              break;
          }
        },
      ),
    );
  }
}

/// 탭 하나에 필요한 아이콘·라벨 정보
class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.iconSize,
  });

  final String label;
  final String icon;
  final String selectedIcon;

  /// Figma 아이콘 크기 (홈 16x18, 영화 20x16, 마이 16x16)
  final Size iconSize;
}

const _destinations = [
  _NavDestination(
    label: '홈',
    icon: 'assets/icons/nav_home.svg',
    selectedIcon: 'assets/icons/nav_home_filled.svg',
    iconSize: Size(16, 18),
  ),
  _NavDestination(
    label: '영화',
    icon: 'assets/icons/nav_movie.svg',
    selectedIcon: 'assets/icons/nav_movie_filled.svg',
    iconSize: Size(20, 16),
  ),
  _NavDestination(
    label: '마이',
    icon: 'assets/icons/nav_person.svg',
    selectedIcon: 'assets/icons/nav_person_filled.svg',
    iconSize: Size(16, 16),
  ),
];

/// 하단 네비게이션 — Material 3 NavigationBar, 390 x 80, 배경 #FFFFFF, border 1px #E6E0E9
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.surfaceContainerHighest),
      ),
      // 내부 컨테이너 — box-shadow 0 -4 20 -10 #0000001A
      // Flutter는 CSS와 달리 그림자를 박스 안쪽에도 그리지만, 위에 그려지는 NavigationBar 배경(흰색)이
      // 안쪽을 덮어서 바깥 그림자만 보입니다.
      child: DecoratedBox(
        decoration: const BoxDecoration(boxShadow: AppShadows.navigationBar),
        // Material 3 NavigationBar — 높이 80, 하단 시스템 영역(SafeArea)은 NavigationBar가 처리
        // 탭 모양은 Figma pill(아이콘 + 라벨을 함께 감쌈)이라 destinations에 직접 만든 _NavItem을 넣습니다.
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onSelected,
          height: 80,
          backgroundColor: colors.surfaceContainerLowest,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          destinations: [
            for (var i = 0; i < _destinations.length; i++)
              Center(
                child: _NavItem(
                  destination: _destinations[i],
                  selected: i == currentIndex,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 탭 하나 — radius 9999, padding 4 / 20 / 4 / 20
/// 선택: 배경 #E8DEF9, 아이콘·글자 #686177 / 미선택: 배경 없음, #494551
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = selected
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;

    // Figma 라벨 높이: 선택 10.8 (홈 탭), 미선택 16 (마이 탭)
    final labelHeight = selected ? 10.8 : 16.0;
    final labelStyle = selected
        ? AppTheme.navLabelSelected.copyWith(color: color)
        : textTheme.bodySmall?.copyWith(color: color);

    // 탭 역할·선택 상태는 NavigationBar가 붙여 주고, 여기서는 이름과 탭 동작만 전달합니다.
    return Semantics(
      label: destination.label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.secondaryContainer : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 아이콘 마진 — padding-bottom 4
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: SvgPicture.asset(
                    selected ? destination.selectedIcon : destination.icon,
                    width: destination.iconSize.width,
                    height: destination.iconSize.height,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                ),
                // Flutter는 글자 높이를 정수로 올림하므로 Figma 높이로 고정
                SizedBox(
                  height: labelHeight,
                  child: Text(
                    destination.label,
                    style: labelStyle,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
