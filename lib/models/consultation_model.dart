// This model represents a Consultation record in the PetCore system.
class ConsultationModel {
  final String? id;
  final String petId;
  final String vetId;
  final String branchId;
  final String symptoms;
  final String diagnosis;
  final String clinicalNotes;
  final String treatmentGiven;
  final String? prescriptionId;
  final DateTime? followUpDate;
  final DateTime createdAt;

  ConsultationModel({
    this.id,
    required this.petId,
    required this.vetId,
    required this.branchId,
    required this.symptoms,
    required this.diagnosis,
    required this.clinicalNotes,
    required this.treatmentGiven,
    this.prescriptionId,
    this.followUpDate,
    required this.createdAt,
  });

  // Converts this Consultation object into a Map to save into Firestore
  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'vetId': vetId,
      'branchId': branchId,
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'clinicalNotes': clinicalNotes,
      'treatmentGiven': treatmentGiven,
      'prescriptionId': prescriptionId,
      'followUpDate': followUpDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Creates a Consultation object from a Map retrieved from Firestore
  factory ConsultationModel.fromMap(Map<String, dynamic> map, String id) {
    return ConsultationModel(
      id: id,
      petId: map['petId'] ?? '',
      vetId: map['vetId'] ?? '',
      branchId: map['branchId'] ?? '',
      symptoms: map['symptoms'] ?? '',
      diagnosis: map['diagnosis'] ?? '',
      clinicalNotes: map['clinicalNotes'] ?? '',
      treatmentGiven: map['treatmentGiven'] ?? '',
      prescriptionId: map['prescriptionId'],
      followUpDate: map['followUpDate'] != null
          ? DateTime.tryParse(map['followUpDate'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}