import '../models/consultation_model.dart';
import '../models/prescription_model.dart';
import '../models/treatment_model.dart';
import '../models/vaccination_model.dart';
import '../services/medical_firestore_service.dart';

Future<void> seedCrossBranchTestData({
  MedicalFirestoreService? medicalService,
}) async {
  final service = medicalService ?? MedicalFirestoreService();
  final now = DateTime.now();

  await service.addTreatment(
    TreatmentModel(
      petId: 'PET-001',
      vetId: 'VET-001',
      branchId: 'BRANCH-A',
      symptoms: 'Persistent itching',
      diagnosis: 'Seasonal dermatitis',
      treatment: 'Topical treatment',
      medicine: 'Dermacalm',
      dosage: 'Apply twice daily',
      duration: '7 days',
      notes: 'Cross-branch timeline test',
      createdAt: now.subtract(const Duration(days: 3)),
    ),
  );
  await service.addConsultation(
    ConsultationModel(
      petId: 'PET-001',
      vetId: 'VET-002',
      branchId: 'BRANCH-B',
      symptoms: 'Follow-up skin irritation',
      diagnosis: 'Improving dermatitis',
      clinicalNotes: 'Symptoms have reduced.',
      treatmentGiven: 'Continue current care',
      createdAt: now.subtract(const Duration(days: 2)),
    ),
  );
  await service.addVaccination(
    VaccinationModel(
      petId: 'PET-001',
      vetId: 'VET-001',
      branchId: 'BRANCH-A',
      vaccineName: 'Rabies vaccine',
      dateGiven: now.subtract(const Duration(days: 1)),
      nextDueDate: now.add(const Duration(days: 365)),
      dosage: '1 dose',
      notes: 'Cross-branch timeline test',
      createdAt: now.subtract(const Duration(days: 1)),
    ),
  );
  await service.addPrescription(
    PrescriptionModel(
      petId: 'PET-001',
      vetId: 'VET-002',
      branchId: 'BRANCH-B',
      medicine: 'Omega supplement',
      dosage: '1 capsule',
      frequency: 'Once daily',
      duration: '30 days',
      instructions: 'Give with food.',
      createdAt: now,
    ),
  );
}