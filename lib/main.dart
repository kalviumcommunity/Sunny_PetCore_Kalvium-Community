import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'screens/setup_error_screen.dart';
import 'services/auth_service.dart';
import 'services/branch_service.dart';
import 'services/firestore_service.dart';
import 'screens/demo_auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const demoMode = true;
  if (demoMode) {
    runApp(const PetCoreApp(demoMode: true));
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
  final bool demoMode;

  const PetCoreApp({
    super.key,
    this.authService,
    this.branchService,
    this.firestoreService,
    this.initializationError,
    this.demoMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetCore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Color(0xFFE0F2F1)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: initializationError != null
          ? SetupErrorScreen(error: initializationError!)
          : demoMode
            ? const DemoAuthGate()
          : AuthGate(
              authService: authService!,
              branchService: branchService!,
              firestoreService: firestoreService!,
            ),
    );
  }
}
