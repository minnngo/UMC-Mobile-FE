import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// TMDB `poster_path`로 포스터를 보여줍니다.
///
/// poster_path는 파일 경로(/abc.jpg)만 오므로 이미지 base URL과 크기를 붙여 주소를 만듭니다.
/// 경로가 없거나 이미지를 불러오지 못하면 placeholder를 보여줍니다.
class TmdbPosterImage extends StatelessWidget {
  const TmdbPosterImage({
    super.key,
    required this.posterPath,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  final String? posterPath;
  final double width;
  final double height;
  final BoxFit fit;

  static const _baseUrl = 'https://image.tmdb.org/t/p';
  static const _size = 'w500';

  /// 예) /abc.jpg → https://image.tmdb.org/t/p/w500/abc.jpg
  String? get _imageUrl {
    if (posterPath == null || posterPath!.isEmpty) return null;
    return '$_baseUrl/$_size$posterPath';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl;

    if (imageUrl == null) return _placeholder();

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.containerHighest,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.placeholder,
      ),
    );
  }
}
