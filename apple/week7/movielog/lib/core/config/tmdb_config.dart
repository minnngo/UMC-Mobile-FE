import 'package:flutter_dotenv/flutter_dotenv.dart';

/// TMDB 연결 설정입니다.
/// Token은 코드에 직접 쓰지 않고 `.env`의 TMDB_ACCESS_TOKEN에서 읽습니다.
abstract final class TmdbConfig {
  static String get accessToken => dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';
}
