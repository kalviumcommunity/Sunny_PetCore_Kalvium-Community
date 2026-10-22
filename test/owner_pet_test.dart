import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcore/models/branch_model.dart';
import 'package:petcore/models/clinical_record_model.dart';
import 'package:petcore/models/owner_model.dart';
import 'package:petcore/models/pet_model.dart';
import 'package:petcore/models/role_permissions.dart';
import 'package:petcore/models/user_model.dart';
import 'package:petcore/services/branch_service.dart';
import 'package:petcore/services/dashboard_data_service.dart';
import 'package:petcore/services/firestore_service.dart';
import 'package:petcore/widgets/petcore_ui.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late BranchService branchService;
  late FirestoreService firestoreService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    branchService = BranchService(firestore: fakeFirestore);
    firestoreService = FirestoreService(firestore: fakeFirestore);
  });

  testWidgets('Shared PetCore empty state renders a clear empty-state message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PetCoreEmptyState(
            title: 'No owners registered yet.',
            subtitle: 'Create the first owner profile to begin record tracking.',
            icon: Icons.person_outline,
          ),
        ),
      ),
    );

    expect(find.text('No owners registered yet.'), findsOneWidget);
    expect(find.text('Create the first owner profile to begin record tracking.'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  test('Flutter can write and read a basic owner record in Firestore', () async {
    // 1. Create owner data model
    final owner = OwnerModel(
      name: 'John Doe',
      phone: '9876543210',
      email: 'john@example.com',
      address: '123 Park Street, City',
    );

    // 2. Write owner to Firestore collection
    final ownerId = await firestoreService.addOwner(owner);
    expect(ownerId, isNotEmpty);

    // 3. Read owner from Firestore collection
    final owners = await firestoreService.getOwners();
    expect(owners.length, 1);
    expect(owners.first.name, 'John Doe');
    expect(owners.first.phone, '9876543210');
    expect(owners.first.email, 'john@example.com');
    expect(owners.first.address, '123 Park Street, City');
  });

  test('Flutter can write and read a basic pet record in Firestore', () async {
    // 1. Create pet data model
    final pet = PetModel(
      petId: 'PET-001',
      name: 'Bruno',
      species: 'Dog',
      breed: 'Labrador',
      gender: 'Male',
      dobAge: '2 years',
      weight: 24.5,
      color: 'Brown',
      ownerId: 'OWNER-123',
    );

    // 2. Write pet to Firestore collection
    final petId = await firestoreService.addPet(pet);
    expect(petId, isNotEmpty);

    // 3. Read pet from Firestore collection
    final pets = await firestoreService.getPets();
    expect(pets.length, 1);
    expect(pets.first.petId, 'PET-001');
    expect(pets.first.name, 'Bruno');
    expect(pets.first.species, 'Dog');
    expect(pets.first.breed, 'Labrador');
    expect(pets.first.gender, 'Male');
    expect(pets.first.dobAge, '2 years');
    expect(pets.first.weight, 24.5);
    expect(pets.first.color, 'Brown');
    expect(pets.first.ownerId, 'OWNER-123');
  });

  test('User profile preserves role and branch data', () {
    const user = UserModel(
      id: 'user-001',
      name: 'Dr. Maya Singh',
      email: 'maya@example.com',
      role: 'VETERINARIAN',
      branchId: 'branch-001',
    );

    final restored = UserModel.fromMap(user.toMap(), user.id);

    expect(restored.id, 'user-001');
    expect(restored.name, 'Dr. Maya Singh');
    expect(restored.email, 'maya@example.com');
    expect(restored.role, 'VETERINARIAN');
    expect(restored.branchId, 'branch-001');
  });

  test('Role permissions protect user management and operational screens', () {
    expect(RolePermissions.canManageUsers(UserRole.admin), isTrue);
    expect(RolePermissions.canAccessOwners(UserRole.admin), isTrue);
    expect(RolePermissions.canAccessPets(UserRole.admin), isTrue);

    expect(RolePermissions.canManageUsers(UserRole.veterinarian), isFalse);
    expect(RolePermissions.canAccessOwners(UserRole.veterinarian), isFalse);
    expect(RolePermissions.canAccessPets(UserRole.veterinarian), isTrue);

    expect(RolePermissions.canManageUsers(UserRole.clinicStaff), isFalse);
    expect(RolePermissions.canAccessOwners(UserRole.clinicStaff), isTrue);
    expect(RolePermissions.canAccessPets(UserRole.clinicStaff), isTrue);

    expect(RolePermissions.canAccessPets(UserRole.unknown), isFalse);
  });

  test('Branch service can create, read, and update a branch', () async {
    final branch = const BranchModel(
      id: '',
      name: 'Central Clinic',
      address: '1 Main Street',
      phone: '555-0100',
      isActive: true,
    );

    final branchId = await branchService.addBranch(branch);
    expect(branchId, isNotEmpty);

    var branches = await branchService.getBranches();
    expect(branches.single.name, 'Central Clinic');
    expect(branches.single.isActive, isTrue);

    await branchService.updateBranch(
      branches.single.copyWith(isActive: false),
    );
    branches = await branchService.getBranches();
    expect(branches.single.isActive, isFalse);
  });

  test('Dashboard follow-up data separates today from future follow-ups', () async {
    final pet = PetModel(
      petId: 'PET-200',
      name: 'Milo',
      species: 'Dog',
      breed: 'Beagle',
      gender: 'Male',
      dobAge: '3 years',
      weight: 12.8,
      color: 'Black and white',
      ownerId: 'OWNER-200',
    );
    await firestoreService.addPet(pet);

    final todayFollowUp = ClinicalRecord(
      type: 'CONSULTATION',
      petId: pet.petId,
      petName: pet.name,
      date: DateTime(2026, 10, 13),
      title: 'Check wound review',
      notes: 'Review bandage.',
      followUpDate: DateTime(2026, 10, 13),
      veterinarian: 'Dr. Singh',
      branchId: 'branch-001',
    );
    final futureFollowUp = ClinicalRecord(
      type: 'CONSULTATION',
      petId: pet.petId,
      petName: pet.name,
      date: DateTime(2026, 10, 12),
      title: 'Follow-up after surgery',
      notes: 'Check healing.',
      followUpDate: DateTime(2026, 10, 16),
      veterinarian: 'Dr. Singh',
      branchId: 'branch-001',
    );

    await firestoreService.addClinicalRecord(todayFollowUp);
    await firestoreService.addClinicalRecord(futureFollowUp);

    final dashboardData = await DashboardDataService(
      firestoreService: firestoreService,
    ).load(now: DateTime(2026, 10, 13));

    expect(dashboardData.todaysFollowUps.length, 1);
    expect(dashboardData.todaysFollowUps.single.title, 'Check wound review');
    expect(dashboardData.upcomingFollowUps.length, 1);
    expect(dashboardData.upcomingFollowUps.single.title,
        'Follow-up after surgery');
    expect(
      dashboardData.upcomingFollowUps.single.followUpDate,
      DateTime(2026, 10, 16),
    );
  });

  test('Clinical records can be stored and pets can be searched', () async {
    final pet = PetModel(
      petId: 'PET-100',
      name: 'Luna',
      species: 'Cat',
      breed: 'Siamese',
      gender: 'Female',
      dobAge: '4 years',
      weight: 4.2,
      color: 'Cream',
      ownerId: 'OWNER-100',
    );
    await firestoreService.addPet(pet);

    final record = ClinicalRecord(
      type: 'CONSULTATION',
      petId: pet.petId,
      petName: pet.name,
      date: DateTime(2026, 10, 12),
      title: 'Annual check-up',
      notes: 'Healthy and active.',
      veterinarian: 'Dr. Singh',
      branchId: 'branch-001',
    );
    final recordId = await firestoreService.addClinicalRecord(record);

    expect(recordId, isNotEmpty);
    expect((await firestoreService.searchPets('luna')).single.petId, 'PET-100');
    expect((await firestoreService.searchPets('PET-100')).single.name, 'Luna');
    expect((await firestoreService.getClinicalRecords()).single.title,
        'Annual check-up');
  });

  test('Pet search supports owner phone and returns multiple pets', () async {
    final ownerId = await firestoreService.addOwner(
      OwnerModel(
        name: 'Riya Patel',
        phone: '+91 98765-43210',
        email: 'riya@example.com',
        address: 'Bandra, Mumbai',
      ),
    );

    await firestoreService.addPet(
      PetModel(
        petId: 'PET-301',
        name: 'Buddy',
        species: 'Dog',
        breed: 'Indie',
        gender: 'Male',
        dobAge: '3 years',
        weight: 16.3,
        color: 'Brown',
        ownerId: ownerId,
      ),
    );
    await firestoreService.addPet(
      PetModel(
        petId: 'PET-302',
        name: 'Mimi',
        species: 'Cat',
        breed: 'Persian',
        gender: 'Female',
        dobAge: '2 years',
        weight: 3.9,
        color: 'White',
        ownerId: ownerId,
      ),
    );

    final results = await firestoreService.searchPets('9876543210');
    expect(results.length, 2);
    expect(results.map((pet) => pet.petId).toSet(), {'PET-301', 'PET-302'});
  });
}
