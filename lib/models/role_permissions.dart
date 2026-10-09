enum UserRole {
  admin,
  veterinarian,
  clinicStaff,
  unknown;

  static UserRole fromValue(String value) {
    switch (value.trim().toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'VETERINARIAN':
        return UserRole.veterinarian;
      case 'CLINIC STAFF':
        return UserRole.clinicStaff;
      default:
        return UserRole.unknown;
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.veterinarian:
        return 'VETERINARIAN';
      case UserRole.clinicStaff:
        return 'CLINIC STAFF';
      case UserRole.unknown:
        return 'UNASSIGNED';
    }
  }
}

class RolePermissions {
  static bool canAccessOwners(UserRole role) {
    return role == UserRole.admin || role == UserRole.clinicStaff;
  }

  static bool canAccessPets(UserRole role) {
    return role != UserRole.unknown;
  }

  static bool canManageUsers(UserRole role) {
    return role == UserRole.admin;
  }
}