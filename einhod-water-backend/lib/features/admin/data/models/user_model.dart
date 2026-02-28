// lib/features/admin/data/models/user_model.dart
import 'shift_model.dart';

class User {
  final int id;
  final String username;
  final String? email;
  final String phoneNumber;
  final List<String> roles;
  final bool isActive;
  final String createdAt;
  final String? lastLogin;
  final Map<String, dynamic>? profile;

  User({
    required this.id,
    required this.username,
    this.email,
    required this.phoneNumber,
    required this.roles,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
    this.profile,
  });

  bool get isWorker => roles.any((r) => r == 'delivery_worker' || r == 'onsite_worker');
  
  WorkShift? get shift {
    if (profile?['shift'] != null) {
      return WorkShift.fromJson(profile!['shift']);
    }
    return null;
  }

  bool get isActiveNow => profile?['is_active_now'] == true;

  WorkerLeave? get currentLeave {
    if (profile?['current_leave'] != null) {
      return WorkerLeave.fromJson(profile!['current_leave']);
    }
    return null;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    List<String> parsedRoles = [];
    if (json['role'] is List) {
      parsedRoles = List<String>.from(json['role']);
    } else if (json['role'] is String) {
      String roleStr = json['role'] as String;
      if (roleStr.startsWith('{') && roleStr.endsWith('}')) {
        // Handle PostgreSQL array format: {role1,role2}
        parsedRoles = roleStr
            .substring(1, roleStr.length - 1)
            .split(',')
            .where((s) => s.isNotEmpty)
            .map((s) => s.replaceAll('"', '').trim())
            .toList();
      } else {
        parsedRoles = [roleStr];
      }
    }

    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      roles: parsedRoles,
      isActive: json['is_active'],
      createdAt: json['created_at'],
      lastLogin: json['last_login'],
      profile: json['profile'],
    );
  }

  String get roleDisplay {
    if (roles.isEmpty) return 'No Role';
    return roles.map((role) {
      switch (role) {
        case 'client':
          return 'Client';
        case 'delivery_worker':
          return 'Delivery Worker';
        case 'onsite_worker':
          return 'On-Site Worker';
        case 'administrator':
          return 'Administrator';
        case 'owner':
          return 'Owner';
        default:
          return role;
      }
    }).join(', ');
  }

  String get statusDisplay => isActive ? 'Active' : 'Inactive';
}
