import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'screens/owner_screen.dart';
import 'screens/pet_screen.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirestoreService firestoreService;

  try {
    await Firebase.initializeApp();
    firestoreService = FirestoreService(firestore: FirebaseFirestore.instance);
  } catch (e) {
    // If Firebase is not configured locally, fallback to in-memory fake firestore
    firestoreService = FirestoreService(firestore: FakeFirebaseFirestore());
  }

  runApp(PetCoreApp(firestoreService: firestoreService));
}

class PetCoreApp extends StatefulWidget {
  final FirestoreService firestoreService;

  const PetCoreApp({super.key, required this.firestoreService});

  @override
  State<PetCoreApp> createState() => _PetCoreAppState();
}

class _PetCoreAppState extends State<PetCoreApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      OwnerScreen(firestoreService: widget.firestoreService),
      PetScreen(firestoreService: widget.firestoreService),
    ];

    return MaterialApp(
      title: 'PetCore — Owner & Pet Foundation',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Owners',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: 'Pets',
            ),
          ],
        ),
      ),
    );
  }
}
