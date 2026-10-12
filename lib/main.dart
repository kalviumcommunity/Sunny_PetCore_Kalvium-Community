import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_gate.dart';
import 'screens/setup_error_screen.dart';
import 'services/auth_service.dart';
import 'services/branch_service.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    runApp(
      PetCoreApp(
        authService: AuthService(),
        branchService: BranchService(),
        firestoreService: FirestoreService(),
      ),
    );
  } catch (error) {
    runApp(PetCoreApp(initializationError: error.toString()));
  }
}

class PetCoreApp extends StatelessWidget {
  final AuthService? authService;
  final BranchService? branchService;
  final FirestoreService? firestoreService;
  final String? initializationError;

  const PetCoreApp({
    super.key,
    this.authService,
    this.branchService,
    this.firestoreService,
    this.initializationError,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetCore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: initializationError != null
          ? SetupErrorScreen(error: initializationError!)
          : AuthGate(
              authService: authService!,
              branchService: branchService!,
              firestoreService: firestoreService!,
            ),
    );
  }
}
