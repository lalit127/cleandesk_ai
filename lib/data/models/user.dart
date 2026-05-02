// lib/data/models/user.dart
// ──────────────────────────
// Data model for a user returned by GET /users.

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // "employee" | "manager"

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isManager => role == 'manager';
  bool get isEmployee => role == 'employee';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:    json['id']    as String,
      name:  json['name']  as String,
      email: json['email'] as String,
      role:  json['role']  as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':    id,
    'name':  name,
    'email': email,
    'role':  role,
  };

  @override
  String toString() => 'UserModel(id=$id, name=$name, role=$role)';
}
