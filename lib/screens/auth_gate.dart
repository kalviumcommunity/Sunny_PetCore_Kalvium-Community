import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  final AuthService authService;
  final FirestoreService firestoreService;

  const AuthGate({
    super.key,
    required this.authService,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return LoginScreen(authService: authService);
        }

        return DashboardScreen(
          authService: authService,
          firestoreService: firestoreService,
          firebaseUser: snapshot.data!,
        );
      },
    );
  }
}