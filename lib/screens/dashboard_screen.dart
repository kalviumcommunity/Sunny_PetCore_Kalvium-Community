import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/role_permissions.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/branch_service.dart';
import '../services/firestore_service.dart';
import 'branch_management_screen.dart';
import 'owner_screen.dart';
import 'pet_screen.dart';
import 'user_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AuthService authService;
  final BranchService branchService;
  final FirestoreService firestoreService;
  final User firebaseUser;
  final UserModel userProfile;

  const DashboardScreen({
    super.key,
    required this.authService,
    required this.branchService,
    required this.firestoreService,
    required this.firebaseUser,
    required this.userProfile,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final role = UserRole.fromValue(widget.userProfile.role);
    final screens = <Widget>[_DashboardHome(profile: widget.userProfile)];
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
    ];

    if (RolePermissions.canAccessOwners(role)) {
      screens.add(OwnerScreen(firestoreService: widget.firestoreService));
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.person),
        label: 'Owners',
      ));
    }

    if (RolePermissions.canAccessPets(role)) {
      screens.add(PetScreen(firestoreService: widget.firestoreService));
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.pets),
        label: 'Pets',
      ));
    }

    if (RolePermissions.canManageUsers(role)) {
      screens.add(UserManagementScreen(
        authService: widget.authService,
        firebaseUser: widget.firebaseUser,
        currentUser: widget.userProfile,
        branchService: widget.branchService,
      ));
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.group),
        label: 'Users',
      ));
      screens.add(BranchManagementScreen(
        branchService: widget.branchService,
        currentUser: widget.userProfile,
      ));
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.store),
        label: 'Branches',
      ));
    }

    final safeIndex = _currentIndex < screens.length ? _currentIndex : 0;

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
      body: screens[safeIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: destinations,
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  final UserModel profile;

  const _DashboardHome({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${profile.name.isEmpty ? profile.email : profile.name}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('Role: ${UserRole.fromValue(profile.role).label}'),
          Text(
            'Branch: ${profile.branchId.isEmpty ? 'Unassigned' : profile.branchId}',
          ),
          const SizedBox(height: 24),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Role-based access is active'),
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