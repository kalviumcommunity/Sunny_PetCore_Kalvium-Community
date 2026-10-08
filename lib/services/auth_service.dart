import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    return getOrCreateUserProfile(firebaseUser);
  }

  Future<UserModel> getOrCreateUserProfile(User firebaseUser) async {
    final reference = _db.collection('users').doc(firebaseUser.uid);
    final snapshot = await reference.get();

    if (snapshot.exists && snapshot.data() != null) {
      return UserModel.fromMap(snapshot.data()!, snapshot.id);
    }

    final user = UserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      role: 'CLINIC STAFF',
      branchId: '',
    );
    await reference.set(user.toMap());
    return user;
  }

  Future<UserModel?> getUserProfile(String userId) async {
    final snapshot = await _db.collection('users').doc(userId).get();
    final data = snapshot.data();
    return snapshot.exists && data != null
        ? UserModel.fromMap(data, snapshot.id)
        : null;
  }

  Future<List<UserModel>> getUserProfiles() async {
    final snapshot = await _db.collection('users').orderBy('email').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());

    if (_auth.currentUser?.uid == user.id &&
        _auth.currentUser?.displayName != user.name) {
      await _auth.currentUser?.updateDisplayName(user.name);
    }
  }

  Future<void> signOut() => _auth.signOut();
}