import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 이 설치에서 앱을 처음 실행했는지 기록하는 shared_preferences 키
const firstInstallKey = 'installation_initialized';

/// iOS Keychain은 앱을 삭제해도 남을 수 있어, 재설치 후 첫 실행이면
/// 이전 설치의 Secure Storage 값(JWT 등)을 모두 지웁니다.
///
/// shared_preferences 값은 앱 삭제 시 함께 지워진다는 차이를 이용합니다.
/// 앱 시작 시 로그인 상태를 읽기 전에 실행합니다.
Future<void> clearStaleSecureStorageOnFirstInstall({
  SharedPreferencesAsync? preferences,
  FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
}) async {
  final prefs = preferences ?? SharedPreferencesAsync();
  final initialized = await prefs.getBool(firstInstallKey) ?? false;

  if (initialized) return;

  await secureStorage.deleteAll();
  await prefs.setBool(firstInstallKey, true);
}
