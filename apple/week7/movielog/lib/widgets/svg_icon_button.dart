import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG 아이콘 하나를 담은 둥근 버튼입니다.
/// 버튼 크기 = 아이콘 크기 + padding x 2 (예: 18 x 18 아이콘 → 34 x 34 버튼)
///
/// 사용처: 헤더 검색·뒤로가기·공유, 마이페이지 내 정보
class SvgIconButton extends StatelessWidget {
  const SvgIconButton({
    super.key,
    required this.asset,
    required this.iconSize,
    required this.color,
    required this.tooltip,
    required this.onPressed,
    this.padding = 8,
  });

  final String asset;
  final Size iconSize;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: SvgPicture.asset(
        asset,
        width: iconSize.width,
        height: iconSize.height,
        // 단색 SVG는 colorFilter로 테마 색상을 입힙니다.
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
      padding: EdgeInsets.all(padding),
      constraints: BoxConstraints.tightFor(
        width: iconSize.width + padding * 2,
        height: iconSize.height + padding * 2,
      ),
      style: IconButton.styleFrom(
        shape: const StadiumBorder(),
        // 기본 48x48 터치 영역 여백을 없애 Figma 크기에 맞춤
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      tooltip: tooltip,
    );
  }
}
