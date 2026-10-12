import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcore/models/branch_model.dart';
import 'package:petcore/models/owner_model.dart';
import 'package:petcore/models/pet_model.dart';
import 'package:petcore/models/role_permissions.dart';
import 'package:petcore/models/user_model.dart';
import 'package:petcore/services/branch_service.dart';
import 'package:petcore/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late BranchService branchService;
  late FirestoreService firestoreService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    branchService = BranchService(firestore: fakeFirestore);
    firestoreService = FirestoreService(firestore: fakeFirestore);
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
}
