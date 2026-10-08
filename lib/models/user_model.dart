class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String branchId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.branchId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'branchId': branchId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'CLINIC STAFF',
      branchId: map['branchId'] as String? ?? '',
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? branchId,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      branchId: branchId ?? this.branchId,
    );
  }
}