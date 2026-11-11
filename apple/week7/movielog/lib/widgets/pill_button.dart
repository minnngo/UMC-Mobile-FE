import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 아이콘 + 글자가 들어간 둥근(pill) 버튼 — 높이 48, radius 9999
///
/// - 채움형: 배경 [color], 아이콘·글자 [foregroundColor]
/// - 테두리형([outlined]): border 1px [color], 아이콘·글자 [foregroundColor]
///
/// 사용처: 홈 배너 상세보기, 영화 상세 즐겨찾기·평점 남기기
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.iconSize,
    required this.color,
    required this.foregroundColor,
    required this.onPressed,
    this.outlined = false,
    this.gap = 4,
    this.textStyle,
    this.shadows = const [],
    this.selected,
  });

  final String label;

  /// 아이콘 파일 경로 — .svg 또는 .png
  final String iconAsset;
  final Size iconSize;
  final Color color;
  final Color foregroundColor;
  final VoidCallback onPressed;
  final bool outlined;

  /// 아이콘과 글자 사이 간격
  final double gap;

  /// null이면 Manrope 500 / 16 / 24 (titleMedium)
  final TextStyle? textStyle;
  final List<BoxShadow> shadows;

  /// 켜고 끄는 버튼이면 현재 상태 (예: 즐겨찾기) — 접근성에 전달
  final bool? selected;

  /// SVG·PNG 모두 [foregroundColor]로 색을 입힙니다.
  Widget _icon() {
    if (iconAsset.endsWith('.svg')) {
      return SvgPicture.asset(
        iconAsset,
        width: iconSize.width,
        height: iconSize.height,
        colorFilter: ColorFilter.mode(foregroundColor, BlendMode.srcIn),
      );
    }
    return Image.asset(
      iconAsset,
      width: iconSize.width,
      height: iconSize.height,
      fit: BoxFit.contain,
      color: foregroundColor,
      colorBlendMode: BlendMode.srcIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = (textStyle ?? Theme.of(context).textTheme.titleMedium)
        ?.copyWith(color: foregroundColor);

    return Semantics(
      toggled: selected,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          shadows: shadows,
        ),
        child: Material(
          color: outlined ? Colors.transparent : color,
          shape: StadiumBorder(
            side: outlined ? BorderSide(color: color) : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _icon(),
                  SizedBox(width: gap),
                  Text(label, textAlign: TextAlign.center, style: style),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
