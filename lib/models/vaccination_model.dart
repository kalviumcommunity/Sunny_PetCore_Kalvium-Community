// This model represents a Vaccination record in the PetCore system.
class VaccinationModel {
  final String? id;
  final String petId;
  final String vetId;
  final String branchId;
  final String vaccineName;
  final DateTime dateGiven;
  final DateTime nextDueDate;
  final String dosage;
  final String notes;
  final DateTime createdAt;

  VaccinationModel({
    this.id,
    required this.petId,
    required this.vetId,
    required this.branchId,
    required this.vaccineName,
    required this.dateGiven,
    required this.nextDueDate,
    required this.dosage,
    required this.notes,
    required this.createdAt,
  });

  // Converts this Vaccination object into a Map to save into Firestore
  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'vetId': vetId,
      'branchId': branchId,
      'vaccineName': vaccineName,
      'dateGiven': dateGiven.toIso8601String(),
      'nextDueDate': nextDueDate.toIso8601String(),
      'dosage': dosage,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Creates a Vaccination object from a Map retrieved from Firestore
  factory VaccinationModel.fromMap(Map<String, dynamic> map, String id) {
    return VaccinationModel(
      id: id,
      petId: map['petId'] ?? '',
      vetId: map['vetId'] ?? '',
      branchId: map['branchId'] ?? '',
      vaccineName: map['vaccineName'] ?? '',
      dateGiven: map['dateGiven'] != null
          ? DateTime.tryParse(map['dateGiven']) ?? DateTime.now()
          : DateTime.now(),
      nextDueDate: map['nextDueDate'] != null
          ? DateTime.tryParse(map['nextDueDate']) ?? DateTime.now()
          : DateTime.now(),
      dosage: map['dosage'] ?? '',
      notes: map['notes'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}