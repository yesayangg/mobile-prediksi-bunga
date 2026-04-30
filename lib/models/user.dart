class User {
  final int id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final String token;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.token,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isCashier => role == UserRole.cashier;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.cashier,
      ),
      avatarUrl: json['avatar_url'],
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'avatar_url': avatarUrl,
      };
}

enum UserRole { owner, cashier }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.cashier:
        return 'Kasir';
    }
  }
}
