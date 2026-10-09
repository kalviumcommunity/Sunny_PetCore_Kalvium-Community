import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcore/models/owner_model.dart';
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

    // 2. Widget Test: Register Owner -> Validate -> Firestore
    testWidgets('Register Owner -> Validate -> Firestore -> pops back',
        (WidgetTester tester) async {
      // Wrap in a Navigator so pop() works correctly
      bool didPop = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => Builder(
                builder: (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OwnerRegistrationScreen(
                            firestoreService: firestoreService,
                          ),
                        ),
                      );
                      didPop = result == true;
                    },
                    child: const Text('Open Registration'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Navigate to registration screen
      await tester.tap(find.text('Open Registration'));
      await tester.pumpAndSettle();

      // 1. Test validation: tap without filling details
      await tester.tap(find.widgetWithText(FilledButton, 'Register Owner'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter name'), findsOneWidget);
      expect(find.text('Please enter phone number'), findsOneWidget);
      expect(find.text('Please enter email'), findsOneWidget);
      expect(find.text('Please enter address'), findsOneWidget);

      // 2. Fill valid details
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'), 'Sarah Jenkins');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone Number'), '9876543210');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address'), 'sarah@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Address'), '742 Evergreen Terrace');

      // 3. Submit form (use FilledButton finder to avoid ambiguity with AppBar title)
      await tester.tap(find.widgetWithText(FilledButton, 'Register Owner'));
      await tester.pumpAndSettle();

      // 4. Verify owner is saved in Firestore
      final owners = await firestoreService.getOwners();
      expect(owners.length, 1);
      expect(owners.first.name, 'Sarah Jenkins');
      expect(owners.first.phone, '9876543210');
      expect(owners.first.email, 'sarah@example.com');
      expect(owners.first.address, '742 Evergreen Terrace');

      // 5. Verify it popped back with success
      expect(didPop, isTrue);
    });

    // 3. Widget Test: Edit mode pre-fills form fields
    testWidgets('Edit mode pre-fills form fields with existing owner data',
        (WidgetTester tester) async {
      final existingOwner = OwnerModel(
        id: 'test-owner-id',
        name: 'Existing Owner',
        phone: '5555555555',
        email: 'existing@example.com',
        address: '100 Test Lane',
      );

      // Pre-populate Firestore so update works
      await fakeFirestore.collection('owners').doc('test-owner-id').set(
            existingOwner.toMap(),
          );

      await tester.pumpWidget(
        MaterialApp(
          home: OwnerRegistrationScreen(
            firestoreService: firestoreService,
            existingOwner: existingOwner,
          ),
        ),
      );

      // Verify form is pre-filled
      expect(find.text('Edit Owner'), findsOneWidget);
      expect(find.text('Editing: Existing Owner'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Verify fields contain existing data
      final nameField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Full Name'),
      );
      expect(nameField.controller?.text, 'Existing Owner');
    });
  });
}
