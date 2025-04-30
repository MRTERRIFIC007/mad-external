import 'package:hive/hive.dart';

enum UserRole {
  admin,
  operator,
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? profileImage;
  final String password;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.password,
    this.profileImage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'profileImage': profileImage,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      password: map['password'] ?? '',
      profileImage: map['profileImage'],
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? password,
    String? profileImage,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      password: password ?? this.password,
      profileImage: profileImage ?? this.profileImage,
    );
  }
} 