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

  Future<void> signOut() => _auth.signOut();
}