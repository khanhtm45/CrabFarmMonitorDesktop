import '../config/app_env.dart';
import '../models/auth_models.dart';
import 'cloud_api_client.dart';

class CloudAuthResult {
  const CloudAuthResult._({
    required this.success,
    this.token,
    this.user,
    this.errorMessage,
  });

  factory CloudAuthResult.success({
    required String token,
    required AuthUser user,
  }) =>
      CloudAuthResult._(success: true, token: token, user: user);

  factory CloudAuthResult.failure(String message) =>
      CloudAuthResult._(success: false, errorMessage: message);

  final bool success;
  final String? token;
  final AuthUser? user;
  final String? errorMessage;
}

class CloudAuthService {
  CloudAuthService({CloudApiClient? client})
      : _api = client ?? CloudApiClient();

  final CloudApiClient _api;

  Future<CloudAuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final emailTrim = email.trim();
    if (!emailTrim.contains('@')) {
      return CloudAuthResult.failure(
        'Cloud yêu cầu email (vd. admin@iras.local).',
      );
    }

    try {
      final reachable = await _api.healthCheck();
      if (!reachable) {
        return CloudAuthResult.failure(
          'Không kết nối Cloud tại ${AppEnv.cloudApiUrl}. Kiểm tra .env và VPS.',
        );
      }

      final login = await _api.login(email: emailTrim, password: password);
      return CloudAuthResult.success(token: login.token, user: login.user);
    } on CloudApiException catch (e) {
      return CloudAuthResult.failure(e.message);
    } catch (e) {
      return CloudAuthResult.failure('Lỗi mạng: $e');
    }
  }

  Future<AuthMePayload> fetchMe(String token) async {
    return _api.authMe(token);
  }

  bool canSwitchFarms(AuthMePayload me) =>
      me.canViewAllFarms || me.farms.length > 1;

  FarmSummary? resolveDefaultFarm(List<FarmSummary> farms, AuthMePayload me) {
    if (farms.isEmpty) return null;
    final candidates = [
      AppEnv.defaultFarmId,
      me.defaultFarmId,
    ];
    for (final id in candidates) {
      if (id == null) continue;
      for (final f in farms) {
        if (f.id.toLowerCase() == id.toLowerCase()) return f;
      }
    }
    return farms.first;
  }
}
