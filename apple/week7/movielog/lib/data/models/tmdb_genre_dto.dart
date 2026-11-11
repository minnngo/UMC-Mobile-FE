/// TMDB Genre API의 장르 하나입니다. 예) { "id": 28, "name": "액션" }
/// 장르 이름을 직접 쓰지 않고 API의 id/name을 그대로 사용합니다.
class TmdbGenreDto {
  const TmdbGenreDto({required this.id, required this.name});

  final int id;
  final String name;

  factory TmdbGenreDto.fromJson(Map<String, dynamic> json) {
    return TmdbGenreDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );
  }
}
