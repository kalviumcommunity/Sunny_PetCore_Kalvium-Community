import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcore/services/medical_firestore_service.dart';
import 'package:petcore/utils/seed_test_data.dart';

void main() {
  test('cross-branch test data appears in one chronologically sorted timeline',
      () async {
    final service = MedicalFirestoreService(
      firestore: FakeFirebaseFirestore(),
    );

    await seedCrossBranchTestData(medicalService: service);
    final history = await service.getMedicalHistoryForPet('PET-001');

    expect(history, hasLength(4));
    expect(
      history.map((record) => record['type']).toList(),
      ['prescription', 'vaccination', 'consultation', 'treatment'],
    );
    expect(
      history.map((record) => record['branchId']).toList(),
      ['BRANCH-B', 'BRANCH-A', 'BRANCH-B', 'BRANCH-A'],
    );
    expect(history[2]['vetId'], 'VET-002');
    expect(history[3]['vetId'], 'VET-001');
  });
}