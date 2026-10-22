import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:petcore/models/consultation_model.dart';
import 'package:petcore/models/pet_model.dart';
import 'package:petcore/models/prescription_model.dart';
import 'package:petcore/models/treatment_model.dart';
import 'package:petcore/models/vaccination_model.dart';
import 'package:petcore/screens/pet_profile_screen.dart';
import 'package:petcore/services/medical_firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MedicalFirestoreService medicalService;

  const targetPetId = 'PET-TARGET';
  const otherPetId = 'PET-OTHER';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    medicalService = MedicalFirestoreService(firestore: fakeFirestore);
  });

  test('Pet profile fetches only the selected pet medical records', () async {
    await medicalService.addConsultation(
      ConsultationModel(
        petId: targetPetId,
        vetId: 'vet-1',
        branchId: 'branch-1',
        symptoms: 'Fever',
        diagnosis: 'Viral fever',
        clinicalNotes: 'Hydration and rest',
        treatmentGiven: 'Fluids',
        createdAt: DateTime(2026, 10, 20),
      ),
    );
    await medicalService.addConsultation(
      ConsultationModel(
        petId: otherPetId,
        vetId: 'vet-2',
        branchId: 'branch-2',
        symptoms: 'Cough',
        diagnosis: 'Cold',
        clinicalNotes: 'Observe for 2 days',
        treatmentGiven: 'Steam',
        createdAt: DateTime(2026, 10, 20),
      ),
    );

    await medicalService.addTreatment(
      TreatmentModel(
        petId: targetPetId,
        vetId: 'vet-1',
        branchId: 'branch-1',
        symptoms: 'Limping',
        diagnosis: 'Minor sprain',
        treatment: 'Bandage',
        medicine: 'Pain relief',
        dosage: '5 ml',
        duration: '5 days',
        notes: 'No running',
        createdAt: DateTime(2026, 10, 21),
      ),
    );
    await medicalService.addTreatment(
      TreatmentModel(
        petId: otherPetId,
        vetId: 'vet-2',
        branchId: 'branch-2',
        symptoms: 'Itching',
        diagnosis: 'Allergy',
        treatment: 'Topical cream',
        medicine: 'Antihistamine',
        dosage: '2 ml',
        duration: '7 days',
        notes: 'Avoid trigger food',
        createdAt: DateTime(2026, 10, 21),
      ),
    );

    await medicalService.addVaccination(
      VaccinationModel(
        petId: targetPetId,
        vetId: 'vet-1',
        branchId: 'branch-1',
        vaccineName: 'Rabies',
        dateGiven: DateTime(2026, 10, 1),
        nextDueDate: DateTime(2027, 10, 1),
        dosage: '1 dose',
        notes: 'Annual dose',
        createdAt: DateTime(2026, 10, 1),
      ),
    );
    await medicalService.addVaccination(
      VaccinationModel(
        petId: otherPetId,
        vetId: 'vet-2',
        branchId: 'branch-2',
        vaccineName: 'DHPP',
        dateGiven: DateTime(2026, 9, 1),
        nextDueDate: DateTime(2027, 9, 1),
        dosage: '1 dose',
        notes: 'Booster after 12 months',
        createdAt: DateTime(2026, 9, 1),
      ),
    );

    await medicalService.addPrescription(
      PrescriptionModel(
        petId: targetPetId,
        vetId: 'vet-1',
        branchId: 'branch-1',
        medicine: 'Amoxicillin',
        dosage: '250 mg',
        frequency: 'Twice daily',
        duration: '5 days',
        instructions: 'After meals',
        createdAt: DateTime(2026, 10, 22),
      ),
    );
    await medicalService.addPrescription(
      PrescriptionModel(
        petId: otherPetId,
        vetId: 'vet-2',
        branchId: 'branch-2',
        medicine: 'Cetirizine',
        dosage: '5 mg',
        frequency: 'Once daily',
        duration: '3 days',
        instructions: 'At night',
        createdAt: DateTime(2026, 10, 22),
      ),
    );

    final consultations = await medicalService.getConsultationsForPet(targetPetId);
    final treatments = await medicalService.getTreatmentsForPet(targetPetId);
    final vaccinations = await medicalService.getVaccinationsForPet(targetPetId);
    final prescriptions = await medicalService.getPrescriptionsForPet(targetPetId);

    expect(consultations.length, 1);
    expect(consultations.single.petId, targetPetId);
    expect(consultations.single.diagnosis, 'Viral fever');

    expect(treatments.length, 1);
    expect(treatments.single.petId, targetPetId);
    expect(treatments.single.treatment, 'Bandage');

    expect(vaccinations.length, 1);
    expect(vaccinations.single.petId, targetPetId);
    expect(vaccinations.single.vaccineName, 'Rabies');

    expect(prescriptions.length, 1);
    expect(prescriptions.single.petId, targetPetId);
    expect(prescriptions.single.medicine, 'Amoxicillin');
  });

  testWidgets('Pet profile displays prescription history details', (tester) async {
    final createdAt = DateTime(2026, 10, 22);
    await medicalService.addPrescription(
      PrescriptionModel(
        petId: targetPetId,
        vetId: 'vet-1',
        branchId: 'branch-1',
        medicine: 'Amoxicillin',
        dosage: '250 mg',
        frequency: 'Twice daily',
        duration: '5 days',
        instructions: 'After meals',
        createdAt: createdAt,
      ),
    );

    final pet = PetModel(
      petId: targetPetId,
      name: 'Luna',
      species: 'Cat',
      breed: 'Siamese',
      gender: 'Female',
      dobAge: '4 years',
      weight: 4.2,
      color: 'Cream',
      ownerId: 'OWNER-100',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PetProfileScreen(
          pet: pet,
          medicalService: medicalService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Prescription History'),
      300,
    );
    await tester.pumpAndSettle();

    expect(find.text('Prescription History'), findsOneWidget);
    expect(find.text('Medicine: Amoxicillin'), findsOneWidget);
    expect(find.text('Dosage: 250 mg'), findsOneWidget);
    expect(find.text('Frequency: Twice daily'), findsOneWidget);
    expect(find.text('Duration: 5 days'), findsOneWidget);
    expect(find.text('Instructions: After meals'), findsOneWidget);
    expect(find.text('Date: ${DateFormat.yMMMd().format(createdAt)}'), findsOneWidget);
    expect(find.text('Veterinarian: vet-1'), findsOneWidget);
  });

  testWidgets('Pet profile shows empty prescription history state', (tester) async {
    final pet = PetModel(
      petId: targetPetId,
      name: 'Luna',
      species: 'Cat',
      breed: 'Siamese',
      gender: 'Female',
      dobAge: '4 years',
      weight: 4.2,
      color: 'Cream',
      ownerId: 'OWNER-100',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PetProfileScreen(
          pet: pet,
          medicalService: medicalService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Prescription History'),
      300,
    );
    await tester.pumpAndSettle();

    expect(find.text('Prescription History'), findsOneWidget);
    expect(find.text('No prescription history available.'), findsOneWidget);
  });
}
