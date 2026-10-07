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
}
