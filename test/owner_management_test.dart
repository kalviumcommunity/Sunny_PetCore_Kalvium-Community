import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcore/models/owner_model.dart';
import 'package:petcore/models/pet_model.dart';
import 'package:petcore/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService firestoreService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(firestore: fakeFirestore);
  });

  // ──────────────────────────────────────────────
  //  OWNER CRUD TESTS
  // ──────────────────────────────────────────────

  group('Owner CRUD', () {
    test('Create and read owner', () async {
      final owner = OwnerModel(
        name: 'John Doe',
        phone: '9876543210',
        email: 'john@example.com',
        address: '123 Park Street, City',
      );

      final ownerId = await firestoreService.addOwner(owner);
      expect(ownerId, isNotEmpty);

      final owners = await firestoreService.getOwners();
      expect(owners.length, 1);
      expect(owners.first.name, 'John Doe');
      expect(owners.first.phone, '9876543210');
      expect(owners.first.email, 'john@example.com');
      expect(owners.first.address, '123 Park Street, City');
      expect(owners.first.isActive, true);
    });

    test('Update owner details', () async {
      final owner = OwnerModel(
        name: 'Jane Doe',
        phone: '1234567890',
        email: 'jane@example.com',
        address: '456 Elm Street',
      );

      final ownerId = await firestoreService.addOwner(owner);
      final savedOwner = owner.copyWith(id: ownerId);

      // Update owner
      final updatedOwner = savedOwner.copyWith(
        name: 'Jane Smith',
        phone: '0987654321',
        address: '789 Oak Avenue',
      );
      await firestoreService.updateOwner(updatedOwner);

      // Verify update
      final fetched = await firestoreService.getOwnerById(ownerId);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Jane Smith');
      expect(fetched.phone, '0987654321');
      expect(fetched.email, 'jane@example.com'); // unchanged
      expect(fetched.address, '789 Oak Avenue');
    });

    test('Delete owner', () async {
      final owner = OwnerModel(
        name: 'Delete Me',
        phone: '1111111111',
        email: 'delete@example.com',
        address: 'Nowhere',
      );

      final ownerId = await firestoreService.addOwner(owner);

      // Verify created
      var owners = await firestoreService.getOwners();
      expect(owners.length, 1);

      // Delete
      await firestoreService.deleteOwner(ownerId);

      // Verify deleted
      owners = await firestoreService.getOwners();
      expect(owners.length, 0);
    });

    test('Disable and re-enable owner', () async {
      final owner = OwnerModel(
        name: 'Toggle Owner',
        phone: '2222222222',
        email: 'toggle@example.com',
        address: 'Toggle Street',
      );

      final ownerId = await firestoreService.addOwner(owner);

      // Initially active
      var fetched = await firestoreService.getOwnerById(ownerId);
      expect(fetched!.isActive, true);

      // Disable
      await firestoreService.disableOwner(ownerId);
      fetched = await firestoreService.getOwnerById(ownerId);
      expect(fetched!.isActive, false);

      // Should not appear in active-only list
      final activeOwners = await firestoreService.getActiveOwners();
      expect(activeOwners.length, 0);

      // Re-enable
      await firestoreService.enableOwner(ownerId);
      fetched = await firestoreService.getOwnerById(ownerId);
      expect(fetched!.isActive, true);

      // Should appear in active-only list again
      final activeOwnersAgain = await firestoreService.getActiveOwners();
      expect(activeOwnersAgain.length, 1);
    });

    test('Get owner by ID returns null for non-existent ID', () async {
      final fetched = await firestoreService.getOwnerById('non-existent-id');
      expect(fetched, isNull);
    });
  });

  // ──────────────────────────────────────────────
  //  DUPLICATE / VALIDATION TESTS
  // ──────────────────────────────────────────────

  group('Duplicate detection', () {
    test('Detect duplicate email', () async {
      final owner = OwnerModel(
        name: 'First Owner',
        phone: '1111111111',
        email: 'duplicate@example.com',
        address: 'Address 1',
      );
      await firestoreService.addOwner(owner);

      final isDuplicate =
          await firestoreService.isEmailDuplicate('duplicate@example.com');
      expect(isDuplicate, true);

      final isNotDuplicate =
          await firestoreService.isEmailDuplicate('unique@example.com');
      expect(isNotDuplicate, false);
    });

    test('Detect duplicate phone', () async {
      final owner = OwnerModel(
        name: 'Phone Owner',
        phone: '3333333333',
        email: 'phone@example.com',
        address: 'Address 2',
      );
      await firestoreService.addOwner(owner);

      final isDuplicate =
          await firestoreService.isPhoneDuplicate('3333333333');
      expect(isDuplicate, true);

      final isNotDuplicate =
          await firestoreService.isPhoneDuplicate('4444444444');
      expect(isNotDuplicate, false);
    });

    test('Exclude own ID when checking duplicates during edit', () async {
      final owner = OwnerModel(
        name: 'Edit Owner',
        phone: '5555555555',
        email: 'edit@example.com',
        address: 'Edit Street',
      );
      final ownerId = await firestoreService.addOwner(owner);

      // Same email is NOT a duplicate when excluding own ID (edit scenario)
      final isDuplicate = await firestoreService.isEmailDuplicate(
        'edit@example.com',
        excludeId: ownerId,
      );
      expect(isDuplicate, false);

      // Same phone is NOT a duplicate when excluding own ID (edit scenario)
      final isPhoneDup = await firestoreService.isPhoneDuplicate(
        '5555555555',
        excludeId: ownerId,
      );
      expect(isPhoneDup, false);
    });
  });

  // ──────────────────────────────────────────────
  //  OWNER → PETS RELATIONSHIP TESTS
  // ──────────────────────────────────────────────

  group('Owner → Pets relationship', () {
    test('Get pets belonging to a specific owner', () async {
      // Create two owners
      final owner1 = OwnerModel(
        name: 'Owner One',
        phone: '1111111111',
        email: 'owner1@example.com',
        address: 'Address 1',
      );
      final owner2 = OwnerModel(
        name: 'Owner Two',
        phone: '2222222222',
        email: 'owner2@example.com',
        address: 'Address 2',
      );
      final owner1Id = await firestoreService.addOwner(owner1);
      final owner2Id = await firestoreService.addOwner(owner2);

      // Add pets for owner 1
      await firestoreService.addPet(PetModel(
        petId: 'PET-001',
        name: 'Bruno',
        species: 'Dog',
        breed: 'Labrador',
        gender: 'Male',
        dobAge: '2 years',
        weight: 24.5,
        color: 'Brown',
        ownerId: owner1Id,
      ));
      await firestoreService.addPet(PetModel(
        petId: 'PET-002',
        name: 'Whiskers',
        species: 'Cat',
        breed: 'Persian',
        gender: 'Female',
        dobAge: '3 years',
        weight: 4.5,
        color: 'White',
        ownerId: owner1Id,
      ));

      // Add pet for owner 2
      await firestoreService.addPet(PetModel(
        petId: 'PET-003',
        name: 'Max',
        species: 'Dog',
        breed: 'Golden Retriever',
        gender: 'Male',
        dobAge: '1 year',
        weight: 20.0,
        color: 'Golden',
        ownerId: owner2Id,
      ));

      // Verify owner 1 has 2 pets
      final owner1Pets = await firestoreService.getPetsByOwner(owner1Id);
      expect(owner1Pets.length, 2);
      expect(owner1Pets.map((p) => p.name).toList()..sort(),
          ['Bruno', 'Whiskers']);

      // Verify owner 2 has 1 pet
      final owner2Pets = await firestoreService.getPetsByOwner(owner2Id);
      expect(owner2Pets.length, 1);
      expect(owner2Pets.first.name, 'Max');

      // Verify a non-existent owner has 0 pets
      final noPets = await firestoreService.getPetsByOwner('fake-owner-id');
      expect(noPets.length, 0);
    });

    test('All pets for an owner share the same ownerId', () async {
      final ownerId = await firestoreService.addOwner(OwnerModel(
        name: 'Consistent Owner',
        phone: '7777777777',
        email: 'consistent@example.com',
        address: 'Consistency Ave',
      ));

      await firestoreService.addPet(PetModel(
        petId: 'PET-A',
        name: 'Alpha',
        species: 'Dog',
        breed: 'Beagle',
        gender: 'Male',
        dobAge: '4 years',
        weight: 12.0,
        color: 'Tricolor',
        ownerId: ownerId,
      ));
      await firestoreService.addPet(PetModel(
        petId: 'PET-B',
        name: 'Beta',
        species: 'Cat',
        breed: 'Siamese',
        gender: 'Female',
        dobAge: '2 years',
        weight: 3.5,
        color: 'Cream',
        ownerId: ownerId,
      ));

      final pets = await firestoreService.getPetsByOwner(ownerId);
      for (final pet in pets) {
        expect(pet.ownerId, ownerId);
      }
    });
  });

  // ──────────────────────────────────────────────
  //  MODEL TESTS
  // ──────────────────────────────────────────────

  group('OwnerModel', () {
    test('toMap and fromMap preserve all fields including isActive', () {
      final owner = OwnerModel(
        id: 'test-id',
        name: 'Model Test',
        phone: '9999999999',
        email: 'model@test.com',
        address: 'Model Street',
        isActive: false,
        createdAt: DateTime(2025, 1, 15),
      );

      final map = owner.toMap();
      final restored = OwnerModel.fromMap(map, 'test-id');

      expect(restored.id, 'test-id');
      expect(restored.name, 'Model Test');
      expect(restored.phone, '9999999999');
      expect(restored.email, 'model@test.com');
      expect(restored.address, 'Model Street');
      expect(restored.isActive, false);
      expect(restored.createdAt?.year, 2025);
      expect(restored.createdAt?.month, 1);
      expect(restored.createdAt?.day, 15);
    });

    test('copyWith creates correct copy with updated fields', () {
      final original = OwnerModel(
        id: 'orig-id',
        name: 'Original',
        phone: '0000000000',
        email: 'original@test.com',
        address: 'Original St',
      );

      final copied = original.copyWith(
        name: 'Copied',
        isActive: false,
      );

      expect(copied.id, 'orig-id'); // unchanged
      expect(copied.name, 'Copied'); // changed
      expect(copied.phone, '0000000000'); // unchanged
      expect(copied.email, 'original@test.com'); // unchanged
      expect(copied.isActive, false); // changed
    });

    test('fromMap defaults isActive to true when missing', () {
      final owner = OwnerModel.fromMap({
        'name': 'Legacy Owner',
        'phone': '8888888888',
        'email': 'legacy@test.com',
        'address': 'Legacy Lane',
      }, 'legacy-id');

      expect(owner.isActive, true);
    });
  });

  // ──────────────────────────────────────────────
  //  PET CRUD (existing tests maintained)
  // ──────────────────────────────────────────────

  test('Flutter can write and read a basic pet record in Firestore', () async {
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

    final petId = await firestoreService.addPet(pet);
    expect(petId, isNotEmpty);

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
}
