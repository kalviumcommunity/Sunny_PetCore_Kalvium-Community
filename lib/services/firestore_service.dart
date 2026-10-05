import 'package:cloud_firestore/cloud_firestore.dart';
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
}
