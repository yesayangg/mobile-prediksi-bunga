class User {
  final int id;
  final String accountId;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final String token;

  User({
    required this.id,
    String? accountId,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.token,
  }) : accountId = accountId ?? id.toString();

  bool get isOwner => role == UserRole.owner || role == UserRole.admin;
  bool get isCashier => role == UserRole.cashier || role == UserRole.kasir;

  factory User.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];

    return User(
      id: _parseInt(rawId),
      accountId: _parseText(rawId),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: UserRoleParser.fromString(json['role']?.toString()),
      avatarUrl: json['avatar_url']?.toString(),
      token: json['token']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _parseText(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  Map<String, dynamic> toJson() => {
        'id': accountId.isNotEmpty ? accountId : id,
        'name': name,
        'email': email,
        'role': role.name,
        'avatar_url': avatarUrl,
      };
}

enum UserRole {
  admin,
  kasir,
  owner,
  cashier,
  unknown,
}

class UserRoleParser {
  static UserRole fromString(String? value) {
    final role = value?.toLowerCase().trim();

    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'kasir':
        return UserRole.kasir;
      case 'owner':
        return UserRole.owner;
      case 'cashier':
        return UserRole.cashier;
      default:
        return UserRole.unknown;
    }
  }
}

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.kasir:
        return 'Kasir';
      case UserRole.owner:
        return 'Owner';
      case UserRole.cashier:
        return 'Kasir';
      case UserRole.unknown:
        return 'Tidak Diketahui';
    }
  }
}
