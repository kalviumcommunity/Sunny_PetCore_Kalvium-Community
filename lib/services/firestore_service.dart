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

  // ──────────────────────────────────────────────
  //  OWNER CRUD Operations
  // ──────────────────────────────────────────────

  // Add a new owner record into the 'owners' collection
  Future<String> addOwner(OwnerModel owner) async {
    final ownerWithTimestamp = owner.copyWith(createdAt: DateTime.now());
    final docRef = await ownersCollection.add(ownerWithTimestamp.toMap());
    return docRef.id;
  }

  // Read all owner records from the 'owners' collection
  Future<List<OwnerModel>> getOwners() async {
    final snapshot = await ownersCollection.get();
    return snapshot.docs.map((doc) {
      return OwnerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  // Read only active owners (filters out disabled/soft-deleted owners)
  Future<List<OwnerModel>> getActiveOwners() async {
    final snapshot =
        await ownersCollection.where('isActive', isEqualTo: true).get();
    return snapshot.docs.map((doc) {
      return OwnerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  // Get a single owner by document ID
  Future<OwnerModel?> getOwnerById(String ownerId) async {
    final doc = await ownersCollection.doc(ownerId).get();
    if (!doc.exists || doc.data() == null) return null;
    return OwnerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Update an existing owner record
  Future<void> updateOwner(OwnerModel owner) async {
    if (owner.id == null) throw ArgumentError('Owner ID cannot be null');
    await ownersCollection.doc(owner.id).update(owner.toMap());
  }

  // Hard delete an owner record from Firestore
  Future<void> deleteOwner(String ownerId) async {
    await ownersCollection.doc(ownerId).delete();
  }

  // Soft-delete (disable) an owner by setting isActive to false
  Future<void> disableOwner(String ownerId) async {
    await ownersCollection.doc(ownerId).update({'isActive': false});
  }

  // Re-enable a disabled owner
  Future<void> enableOwner(String ownerId) async {
    await ownersCollection.doc(ownerId).update({'isActive': true});
  }

  // ──────────────────────────────────────────────
  //  DUPLICATE / VALIDATION CHECKS
  // ──────────────────────────────────────────────

  // Check if an owner with the given email already exists (exclude a specific ID for edits)
  Future<bool> isEmailDuplicate(String email, {String? excludeId}) async {
    final snapshot = await ownersCollection
        .where('email', isEqualTo: email.trim().toLowerCase())
        .get();
    if (snapshot.docs.isEmpty) return false;
    if (excludeId != null) {
      return snapshot.docs.any((doc) => doc.id != excludeId);
    }
    return true;
  }

  // Check if an owner with the given phone already exists (exclude a specific ID for edits)
  Future<bool> isPhoneDuplicate(String phone, {String? excludeId}) async {
    final snapshot =
        await ownersCollection.where('phone', isEqualTo: phone.trim()).get();
    if (snapshot.docs.isEmpty) return false;
    if (excludeId != null) {
      return snapshot.docs.any((doc) => doc.id != excludeId);
    }
    return true;
  }

  // ──────────────────────────────────────────────
  //  PET CRUD Operations
  // ──────────────────────────────────────────────

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

  // Get all pets belonging to a specific owner
  Future<List<PetModel>> getPetsByOwner(String ownerId) async {
    final snapshot =
        await petsCollection.where('ownerId', isEqualTo: ownerId).get();
    return snapshot.docs.map((doc) {
      return PetModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }
}
