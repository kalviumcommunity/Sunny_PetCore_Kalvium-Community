import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/consultation_model.dart';
import '../models/document_model.dart';
import '../models/followup_model.dart';
import '../models/prescription_model.dart';
import '../models/treatment_model.dart';
import '../models/vaccination_model.dart';

// This service handles medical record operations with Cloud Firestore.
class MedicalFirestoreService {
  final FirebaseFirestore _db;
  final FirebaseStorage? _providedStorage;
  FirebaseStorage? _storageInstance;

  MedicalFirestoreService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _providedStorage = storage;

  FirebaseStorage get _storage =>
      _storageInstance ??= _providedStorage ?? FirebaseStorage.instance;

  // References to the medical record collections in Firestore
  CollectionReference get consultationsCollection =>
      _db.collection('consultations');

  CollectionReference get treatmentsCollection => _db.collection('treatments');

  CollectionReference get vaccinationsCollection =>
      _db.collection('vaccinations');

  CollectionReference get prescriptionsCollection =>
      _db.collection('prescriptions');

  CollectionReference get followupsCollection => _db.collection('followups');

  CollectionReference get documentsCollection => _db.collection('documents');

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

  Future<String> addFollowUp(FollowUpModel followUp) async {
    final docRef = await followupsCollection.add(followUp.toMap());
    return docRef.id;
  }

  Future<List<FollowUpModel>> getUpcomingFollowUps() async {
    final snapshot = await followupsCollection
        .where('status', isEqualTo: 'Pending')
        .get();
    final followUps = snapshot.docs.map((doc) {
      return FollowUpModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
    followUps.sort((first, second) =>
        first.followUpDate.compareTo(second.followUpDate));
    return followUps;
  }

  Future<List<FollowUpModel>> getUpcomingFollowUpsForPet(String petId) async {
    final snapshot =
        await followupsCollection.where('petId', isEqualTo: petId).get();
    final followUps = snapshot.docs
        .map((doc) => FollowUpModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ))
        .where((followUp) => followUp.status == 'Pending')
        .toList();
    followUps.sort((first, second) =>
        first.followUpDate.compareTo(second.followUpDate));
    return followUps;
  }

  Future<void> markFollowUpCompleted(String followUpId) async {
    await followupsCollection.doc(followUpId).update({'status': 'Completed'});
  }

  Future<DocumentModel> uploadDocument(
    Uint8List fileBytes,
    String fileName,
    String petId,
    String documentType, {
    void Function(double progress)? onProgress,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No signed-in staff profile');

    final userSnapshot = await _db.collection('users').doc(user.uid).get();
    final branchId = userSnapshot.data()?['branchId'] as String? ?? '';
    final safeFileName = fileName.replaceAll(RegExp(r'[/\\]'), '_');
    if (safeFileName.isEmpty) {
      throw ArgumentError('The selected file has no name');
    }

    final uploadTask = _storage
      .ref('documents/$branchId/$petId/$safeFileName')
        .putData(fileBytes);
    final progressSubscription = uploadTask.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    late final TaskSnapshot uploadSnapshot;
    try {
      uploadSnapshot = await uploadTask;
    } finally {
      await progressSubscription.cancel();
    }

    final document = DocumentModel(
      petId: petId,
      fileName: safeFileName,
      fileUrl: await uploadSnapshot.ref.getDownloadURL(),
      uploadedBy: user.uid,
      branchId: branchId,
      uploadDate: DateTime.now(),
      documentType: documentType,
    );
    final docRef = await documentsCollection.add(document.toMap());
    return DocumentModel(
      id: docRef.id,
      petId: document.petId,
      fileName: document.fileName,
      fileUrl: document.fileUrl,
      uploadedBy: document.uploadedBy,
      branchId: document.branchId,
      uploadDate: document.uploadDate,
      documentType: document.documentType,
    );
  }

  Future<List<DocumentModel>> getDocumentsForPet(
    String petId, {
    String? branchId,
  }) async {
    final query = branchId == null
        ? documentsCollection.where('petId', isEqualTo: petId)
        : documentsCollection
            .where('petId', isEqualTo: petId)
            .where('branchId', isEqualTo: branchId);
    final snapshot = await query.get();
    final documents = snapshot.docs.map((doc) {
      return DocumentModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
    documents.sort((first, second) =>
        second.uploadDate.compareTo(first.uploadDate));
    return documents;
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