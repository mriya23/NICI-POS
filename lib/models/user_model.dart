enum UserRole { admin, cashier }

class User {
  final String id;
  final String username;
  final String password;
  final String name;
  final UserRole role;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.role,
    this.email,
    this.phone,
    this.avatarUrl,
    this.isActive = true,
    DateTime? createdAt,
    this.lastLogin,
  }) : createdAt = createdAt ?? DateTime.now();

  User copyWith({
    String? id,
    String? username,
    String? password,
    String? name,
    UserRole? role,
    String? email,
    String? phone,
    String? avatarUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'name': name,
      'role': role.toString().split('.').last,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      name: map['name'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.cashier,
      ),
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      isActive: map['isActive'] == 1 || map['isActive'] == true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      lastLogin: map['lastLogin'] != null
          ? DateTime.parse(map['lastLogin'] as String)
          : null,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isCashier => role == UserRole.cashier;

  @override
  String toString() {
    return 'User(id: $id, username: $username, name: $name, role: ${role.toString().split('.').last})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
