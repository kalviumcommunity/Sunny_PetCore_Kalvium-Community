import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/branch_service.dart';
import '../services/firestore_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  final AuthService authService;
  final BranchService branchService;
  final FirestoreService firestoreService;

  const AuthGate({
    super.key,
    required this.authService,
    required this.branchService,
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

        if (snapshot.hasError) {
          return _AuthErrorScreen(onRetry: () => _refreshAuthState(context));
        }

        if (snapshot.data == null) {
          return LoginScreen(authService: authService);
        }

        final firebaseUser = snapshot.data!;
        return FutureBuilder<UserModel>(
          future: authService.getOrCreateUserProfile(firebaseUser),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.hasError || profileSnapshot.data == null) {
              return _ProfileErrorScreen(
                onRetry: () => _refreshAuthState(context),
              );
            }

            return DashboardScreen(
              authService: authService,
              branchService: branchService,
              firestoreService: firestoreService,
              firebaseUser: firebaseUser,
              userProfile: profileSnapshot.data!,
            );
          },
        );
      },
    );
  }

  void _refreshAuthState(BuildContext context) {
    // Rebuilding the gate lets the auth stream retry after a transient error.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AuthGate(
          authService: authService,
          branchService: branchService,
          firestoreService: firestoreService,
        ),
      ),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _AuthErrorScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 16),
              const Text(
                'We could not check your sign-in session.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _ProfileErrorScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_outlined, size: 48),
              const SizedBox(height: 16),
              const Text(
                'We could not load your user profile.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}