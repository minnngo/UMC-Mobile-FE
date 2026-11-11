import 'package:shared_preferences/shared_preferences.dart';

/// 영화 목록에서 마지막으로 선택한 TMDB 장르 id를 기기에 저장합니다.
/// 단순하고 중요하지 않은 설정값이라 shared_preferences를 사용합니다.
class GenrePreference {
  GenrePreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _selectedGenreIdKey = 'selected_genre_id';

  final SharedPreferencesAsync _preferences;

  /// 저장된 장르 id — 없으면 null("전체")
  Future<int?> read() => _preferences.getInt(_selectedGenreIdKey);

  /// null("전체")이면 저장된 값을 지웁니다.
  Future<void> save(int? genreId) async {
    if (genreId == null) {
      await clear();
    } else {
      await _preferences.setInt(_selectedGenreIdKey, genreId);
    }
  }

  Future<void> clear() async {
    await _preferences.remove(_selectedGenreIdKey);
  }
}
