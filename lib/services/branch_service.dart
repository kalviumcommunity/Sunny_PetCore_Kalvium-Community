import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/branch_model.dart';

class BranchService {
  final FirebaseFirestore _db;

  BranchService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get branchesCollection =>
      _db.collection('branches');

  Future<List<BranchModel>> getBranches() async {
    final snapshot = await branchesCollection.orderBy('name').get();
    return snapshot.docs
        .map((doc) => BranchModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<String> addBranch(BranchModel branch) async {
    final reference = await branchesCollection.add(branch.toMap());
    return reference.id;
  }

  Future<void> updateBranch(BranchModel branch) async {
    await branchesCollection.doc(branch.id).set(branch.toMap());
  }
}