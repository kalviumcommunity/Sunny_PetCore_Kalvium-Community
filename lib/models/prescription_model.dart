// This model represents a Prescription record in the PetCore system.
class PrescriptionModel {
  final String? id;
  final String petId;
  final String vetId;
  final String branchId;
  final String medicine;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;
  final DateTime createdAt;

  PrescriptionModel({
    this.id,
    required this.petId,
    required this.vetId,
    required this.branchId,
    required this.medicine,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instructions,
    required this.createdAt,
  });

  // Converts this Prescription object into a Map to save into Firestore
  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'vetId': vetId,
      'branchId': branchId,
      'medicine': medicine,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Creates a Prescription object from a Map retrieved from Firestore
  factory PrescriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return PrescriptionModel(
      id: id,
      petId: map['petId'] ?? '',
      vetId: map['vetId'] ?? '',
      branchId: map['branchId'] ?? '',
      medicine: map['medicine'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      duration: map['duration'] ?? '',
      instructions: map['instructions'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}