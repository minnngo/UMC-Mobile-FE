class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.rating,
    required this.posterAsset,
  });

  final int id;
  final String title;
  final String genre;
  final int year;

  /// 평균 별점 (5점 만점)
  final double rating;
  final String posterAsset;
}
