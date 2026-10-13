// This model represents a Treatment record in the PetCore system.
class TreatmentModel {
  final String? id;
  final String petId;
  final String vetId;
  final String branchId;
  final String symptoms;
  final String diagnosis;
  final String treatment;
  final String medicine;
  final String dosage;
  final String duration;
  final DateTime? followUpDate;
  final String notes;
  final DateTime createdAt;

  TreatmentModel({
    this.id,
    required this.petId,
    required this.vetId,
    required this.branchId,
    required this.symptoms,
    required this.diagnosis,
    required this.treatment,
    required this.medicine,
    required this.dosage,
    required this.duration,
    this.followUpDate,
    required this.notes,
    required this.createdAt,
  });

  // Converts this Treatment object into a Map to save into Firestore
  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'vetId': vetId,
      'branchId': branchId,
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'medicine': medicine,
      'dosage': dosage,
      'duration': duration,
      'followUpDate': followUpDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Creates a Treatment object from a Map retrieved from Firestore
  factory TreatmentModel.fromMap(Map<String, dynamic> map, String id) {
    return TreatmentModel(
      id: id,
      petId: map['petId'] ?? '',
      vetId: map['vetId'] ?? '',
      branchId: map['branchId'] ?? '',
      symptoms: map['symptoms'] ?? '',
      diagnosis: map['diagnosis'] ?? '',
      treatment: map['treatment'] ?? '',
      medicine: map['medicine'] ?? '',
      dosage: map['dosage'] ?? '',
      duration: map['duration'] ?? '',
      followUpDate: map['followUpDate'] != null
          ? DateTime.tryParse(map['followUpDate'])
          : null,
      notes: map['notes'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}