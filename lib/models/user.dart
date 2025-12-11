// lib/models/user.dart
class AppUser {
  final int id;
  final String name;
  final String email;
  final String? token;   // <- sekarang boleh null
  final String role;
  final String? avatar;  // optional

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.token,          // <- nullable
    required this.role,
    this.avatar,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      token: json['token'],          // <- kalau tidak ada, akan null
      role: json['role'] ?? 'user',
      avatar: json['avatar'],
    );
  }

  AppUser copyWith({String? name, String? email, String? avatar}) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      token: token,                  // token tetap yang lama
      role: role,
      avatar: avatar ?? this.avatar,
    );
  }
}
