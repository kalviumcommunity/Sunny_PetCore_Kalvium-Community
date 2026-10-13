// This model represents an Owner in the PetCore system.
// It holds the 4 required details: Name, Phone, Email, and Address.
// Also supports soft-delete via `isActive` flag and tracks creation time.
class OwnerModel {
  final String? id;      // Document ID assigned by Firestore
  final String name;     // Owner's full name
  final String phone;    // Owner's phone number
  final String email;    // Owner's email address
  final String address;  // Owner's home address
  final bool isActive;   // Whether the owner is active (false = soft-deleted)
  final DateTime? createdAt; // When the owner was registered

  OwnerModel({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.isActive = true,
    this.createdAt,
  });

  // Converts this Owner object into a Map (key-value pairs) to save into Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Creates an Owner object from a Map retrieved from Firestore
  factory OwnerModel.fromMap(Map<String, dynamic> map, String id) {
    return OwnerModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
    );
  }

  // Creates a copy of this Owner with optional updated fields
  OwnerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return OwnerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
