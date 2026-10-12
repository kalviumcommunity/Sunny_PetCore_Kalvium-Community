class BranchModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final bool isActive;

  const BranchModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'isActive': isActive,
    };
  }

  factory BranchModel.fromMap(Map<String, dynamic> map, String id) {
    return BranchModel(
      id: id,
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  BranchModel copyWith({
    String? name,
    String? address,
    String? phone,
    bool? isActive,
  }) {
    return BranchModel(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }
}