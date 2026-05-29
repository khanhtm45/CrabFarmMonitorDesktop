class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.orgId,
  });

  final String id;
  final String email;
  final String displayName;
  final String role;
  final String? orgId;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _str(json, 'id', 'Id'),
      email: _str(json, 'email', 'Email'),
      displayName: _str(json, 'displayName', 'DisplayName', fallback: 'User'),
      role: _str(json, 'role', 'Role', fallback: 'user'),
      orgId: _optionalStr(json, 'orgId', 'OrgId'),
    );
  }
}

class FarmSummary {
  const FarmSummary({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;

  factory FarmSummary.fromJson(Map<String, dynamic> json) {
    return FarmSummary(
      id: _str(json, 'id', 'Id'),
      code: _str(json, 'code', 'Code', fallback: ''),
      name: _str(json, 'name', 'Name', fallback: 'Farm'),
    );
  }

  @override
  String toString() => '$name ($code)';
}

class AuthMePayload {
  const AuthMePayload({
    required this.user,
    required this.farms,
    required this.isOrgAdmin,
    this.canViewAllFarms = false,
    this.defaultFarmId,
  });

  final AuthUser user;
  final List<FarmSummary> farms;
  final bool isOrgAdmin;
  final bool canViewAllFarms;
  final String? defaultFarmId;

  factory AuthMePayload.fromJson(Map<String, dynamic> json) {
    final farmsRaw = json['farms'] ?? json['Farms'];
    final farms = <FarmSummary>[];
    if (farmsRaw is List) {
      for (final item in farmsRaw) {
        if (item is Map<String, dynamic>) {
          farms.add(FarmSummary.fromJson(item));
        } else if (item is Map) {
          farms.add(FarmSummary.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final userRaw = json['user'] ?? json['User'];
    if (userRaw is! Map) {
      throw const FormatException('auth/me: thiếu user');
    }

    return AuthMePayload(
      user: AuthUser.fromJson(Map<String, dynamic>.from(userRaw)),
      farms: farms,
      isOrgAdmin: json['isOrgAdmin'] == true || json['IsOrgAdmin'] == true,
      canViewAllFarms: json['canViewAllFarms'] == true ||
          json['CanViewAllFarms'] == true ||
          json['isOrgAdmin'] == true ||
          json['IsOrgAdmin'] == true,
      defaultFarmId: _optionalStr(json, 'defaultFarmId', 'DefaultFarmId'),
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    required this.farms,
    required this.selectedFarm,
    required this.isOrgAdmin,
  });

  final String token;
  final AuthUser user;
  final List<FarmSummary> farms;
  final FarmSummary selectedFarm;
  final bool isOrgAdmin;

  AuthSession copyWith({
    FarmSummary? selectedFarm,
    List<FarmSummary>? farms,
  }) =>
      AuthSession(
        token: token,
        user: user,
        farms: farms ?? this.farms,
        selectedFarm: selectedFarm ?? this.selectedFarm,
        isOrgAdmin: isOrgAdmin,
      );
}

String _str(
  Map<String, dynamic> json,
  String a,
  String b, {
  String fallback = '',
}) {
  final v = json[a] ?? json[b];
  if (v == null) return fallback;
  return v.toString();
}

String? _optionalStr(Map<String, dynamic> json, String a, String b) {
  final v = json[a] ?? json[b];
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}
