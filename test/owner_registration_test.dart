import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcore/models/owner_model.dart';
import 'package:petcore/screens/owner_profile_screen.dart';
import 'package:petcore/screens/owner_registration_screen.dart';
import 'package:petcore/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService firestoreService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(firestore: fakeFirestore);
  });

  group('Owner Registration Tests', () {
    // 1. Test creating multiple owners in Firestore
    test('Can create and store multiple owners in Firestore', () async {
      final owner1 = OwnerModel(
        name: 'Alice Johnson',
        phone: '9876543210',
        email: 'alice@example.com',
        address: '123 Main St',
      );

      final owner2 = OwnerModel(
        name: 'Bob Smith',
        phone: '9123456789',
        email: 'bob@example.com',
        address: '456 Oak Ave',
      );

      final owner3 = OwnerModel(
        name: 'Charlie Brown',
        phone: '9988776655',
        email: 'charlie@example.com',
        address: '789 Pine Rd',
      );

      // Save multiple owners
      final id1 = await firestoreService.addOwner(owner1);
      final id2 = await firestoreService.addOwner(owner2);
      final id3 = await firestoreService.addOwner(owner3);

      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id3, isNotEmpty);
      expect(id1 != id2, isTrue);
      expect(id2 != id3, isTrue);

      // Fetch all owners
      final owners = await firestoreService.getOwners();
      expect(owners.length, 3);

      final names = owners.map((o) => o.name).toList();
      expect(names, containsAll(['Alice Johnson', 'Bob Smith', 'Charlie Brown']));
    });

    // 2. Widget Test: Register Owner -> Validate -> Firestore -> Owner Profile
    testWidgets('Register Owner -> Validate -> Firestore -> Owner Profile flow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerRegistrationScreen(firestoreService: firestoreService),
        ),
      );

      // 1. Test validation: tap without filling details
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register Owner'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter name'), findsOneWidget);
      expect(find.text('Please enter phone number'), findsOneWidget);
      expect(find.text('Please enter email'), findsOneWidget);
      expect(find.text('Please enter address'), findsOneWidget);

      // 2. Fill valid details
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'), 'Sarah Jenkins');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone'), '9876543210');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'sarah@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Address'), '742 Evergreen Terrace');

      // 3. Submit form
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register Owner'));
      await tester.pumpAndSettle();

      // 4. Verify owner is saved in Firestore
      final owners = await firestoreService.getOwners();
      expect(owners.length, 1);
      expect(owners.first.name, 'Sarah Jenkins');

      // 5. Verify navigation to OwnerProfileScreen
      expect(find.byType(OwnerProfileScreen), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('sarah@example.com'), findsOneWidget);
      expect(find.text('742 Evergreen Terrace'), findsOneWidget);
    });
  });
}
