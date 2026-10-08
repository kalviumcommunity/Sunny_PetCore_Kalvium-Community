import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'owner_screen.dart';
import 'pet_screen.dart';
import 'user_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AuthService authService;
  final FirestoreService firestoreService;
  final User firebaseUser;

  const DashboardScreen({
    super.key,
    required this.authService,
    required this.firestoreService,
    required this.firebaseUser,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      _DashboardHome(user: widget.firebaseUser),
      OwnerScreen(firestoreService: widget.firestoreService),
      PetScreen(firestoreService: widget.firestoreService),
      UserManagementScreen(
        authService: widget.authService,
        firebaseUser: widget.firebaseUser,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetCore Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.authService.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Owners'),
          NavigationDestination(icon: Icon(Icons.pets), label: 'Pets'),
          NavigationDestination(icon: Icon(Icons.group), label: 'Users'),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  final User user;

  const _DashboardHome({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome${user.email == null ? '' : ', ${user.email}'}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Your authenticated PetCore workspace is ready.'),
          const SizedBox(height: 24),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Phase 1 complete'),
              subtitle: Text(
                'Authentication, profiles, and protected navigation are active.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}