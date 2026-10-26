import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/clinical_record_model.dart';
import '../models/owner_model.dart';
import '../models/pet_model.dart';

// This service handles all read and write operations with Cloud Firestore database.
class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // 1. Reference to the 'owners' collection in Firestore
  CollectionReference get ownersCollection => _db.collection('owners');

  // 2. Reference to the 'pets' collection in Firestore
  CollectionReference get petsCollection => _db.collection('pets');

  CollectionReference get clinicalRecordsCollection =>
      _db.collection('clinical_records');

  // Add a new owner record into the 'owners' collection
  Future<String> addOwner(OwnerModel owner) async {
    final docRef = await ownersCollection.add(owner.toMap());
    return docRef.id;
  }

  // Read all owner records from the 'owners' collection
  Future<List<OwnerModel>> getOwners() async {
    final snapshot = await ownersCollection.get();
    return snapshot.docs.map((doc) {
      return OwnerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  // Add a new pet record into the 'pets' collection
  Future<String> addPet(PetModel pet) async {
    final docRef = await petsCollection.add(pet.toMap());
    return docRef.id;
  }

  // Read all pet records from the 'pets' collection
  Future<List<PetModel>> getPets() async {
    final snapshot = await petsCollection.get();
    return snapshot.docs.map((doc) {
      return PetModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  Future<List<PetModel>> searchPets(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return [];

    final pets = await getPets();
    return pets.where((pet) {
      return pet.petId.toLowerCase().contains(normalizedQuery) ||
          pet.name.toLowerCase().contains(normalizedQuery) ||
          pet.species.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  Future<String> addClinicalRecord(ClinicalRecord record) async {
    final docRef = await clinicalRecordsCollection.add(record.toMap());
    return docRef.id;
  }

  Future<List<ClinicalRecord>> getClinicalRecords({String? branchId}) async {
    final query = branchId == null
        ? clinicalRecordsCollection
        : clinicalRecordsCollection.where('branchId', isEqualTo: branchId);
    final snapshot = await query.get();
    final records = snapshot.docs.map((doc) {
      return ClinicalRecord.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
    records.sort((first, second) => second.date.compareTo(first.date));
    return records;
  }
}
