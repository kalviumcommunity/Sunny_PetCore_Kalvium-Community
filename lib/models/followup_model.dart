class FollowUpModel {
  final String? id;
  final String petId;
  final String vetId;
  final String branchId;
  final String relatedRecordId;
  final String relatedRecordType;
  final DateTime followUpDate;
  final String status;
  final String notes;
  final DateTime createdAt;

  FollowUpModel({
    this.id,
    required this.petId,
    required this.vetId,
    required this.branchId,
    required this.relatedRecordId,
    required this.relatedRecordType,
    required this.followUpDate,
    this.status = 'Pending',
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'vetId': vetId,
      'branchId': branchId,
      'relatedRecordId': relatedRecordId,
      'relatedRecordType': relatedRecordType,
      'followUpDate': followUpDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FollowUpModel.fromMap(Map<String, dynamic> map, String id) {
    return FollowUpModel(
      id: id,
      petId: map['petId'] as String? ?? '',
      vetId: map['vetId'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      relatedRecordId: map['relatedRecordId'] as String? ?? '',
      relatedRecordType: map['relatedRecordType'] as String? ?? '',
      followUpDate: DateTime.tryParse(map['followUpDate'] as String? ?? '') ??
          DateTime.now(),
      status: map['status'] as String? ?? 'Pending',
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}