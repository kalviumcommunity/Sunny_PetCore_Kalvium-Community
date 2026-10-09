import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consultation_model.dart';
import '../models/prescription_model.dart';
import '../models/treatment_model.dart';
import '../models/vaccination_model.dart';

// This service handles medical record operations with Cloud Firestore.
class MedicalFirestoreService {
  final FirebaseFirestore _db;

  MedicalFirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // References to the medical record collections in Firestore
  CollectionReference get consultationsCollection =>
      _db.collection('consultations');

  CollectionReference get treatmentsCollection => _db.collection('treatments');

  CollectionReference get vaccinationsCollection =>
      _db.collection('vaccinations');

  CollectionReference get prescriptionsCollection =>
      _db.collection('prescriptions');

  // Add a new consultation record
  Future<String> addConsultation(ConsultationModel consultation) async {
    final docRef = await consultationsCollection.add(consultation.toMap());
    return docRef.id;
  }

  // Read consultation records for a pet
  Future<List<ConsultationModel>> getConsultationsForPet(String petId) async {
    final snapshot = await consultationsCollection
        .where('petId', isEqualTo: petId)
        .get();
    return snapshot.docs.map((doc) {
      return ConsultationModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  // Add a new treatment record
  Future<String> addTreatment(TreatmentModel treatment) async {
    final docRef = await treatmentsCollection.add(treatment.toMap());
    return docRef.id;
  }

  // Read treatment records for a pet
  Future<List<TreatmentModel>> getTreatmentsForPet(String petId) async {
    final snapshot =
        await treatmentsCollection.where('petId', isEqualTo: petId).get();
    return snapshot.docs.map((doc) {
      return TreatmentModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  // Add a new vaccination record
  Future<String> addVaccination(VaccinationModel vaccination) async {
    final docRef = await vaccinationsCollection.add(vaccination.toMap());
    return docRef.id;
  }

  // Read vaccination records for a pet
  Future<List<VaccinationModel>> getVaccinationsForPet(String petId) async {
    final snapshot = await vaccinationsCollection
        .where('petId', isEqualTo: petId)
        .get();
    return snapshot.docs.map((doc) {
      return VaccinationModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  // Add a new prescription record
  Future<String> addPrescription(PrescriptionModel prescription) async {
    final docRef = await prescriptionsCollection.add(prescription.toMap());
    return docRef.id;
  }

  // Read prescription records for a pet
  Future<List<PrescriptionModel>> getPrescriptionsForPet(String petId) async {
    final snapshot = await prescriptionsCollection
        .where('petId', isEqualTo: petId)
        .get();
    return snapshot.docs.map((doc) {
      return PrescriptionModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  // Read all medical records for a pet as a single timeline
  Future<List<Map<String, dynamic>>> getMedicalHistoryForPet(
    String petId,
  ) async {
    final results = await Future.wait([
      getConsultationsForPet(petId),
      getTreatmentsForPet(petId),
      getVaccinationsForPet(petId),
      getPrescriptionsForPet(petId),
    ]);

    final history = <Map<String, dynamic>>[
      ...(results[0] as List<ConsultationModel>).map((record) => {
            ...record.toMap(),
            'id': record.id,
            'type': 'consultation',
          }),
      ...(results[1] as List<TreatmentModel>).map((record) => {
            ...record.toMap(),
            'id': record.id,
            'type': 'treatment',
          }),
      ...(results[2] as List<VaccinationModel>).map((record) => {
            ...record.toMap(),
            'id': record.id,
            'type': 'vaccination',
          }),
      ...(results[3] as List<PrescriptionModel>).map((record) => {
            ...record.toMap(),
            'id': record.id,
            'type': 'prescription',
          }),
    ];

    history.sort((first, second) {
      final firstCreatedAt = DateTime.tryParse(first['createdAt'] as String) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final secondCreatedAt =
          DateTime.tryParse(second['createdAt'] as String) ??
              DateTime.fromMillisecondsSinceEpoch(0);
      return secondCreatedAt.compareTo(firstCreatedAt);
    });

    return history;
  }
}