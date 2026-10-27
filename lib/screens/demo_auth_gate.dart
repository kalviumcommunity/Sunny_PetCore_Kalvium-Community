import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/branch_service.dart';
import '../services/firestore_service.dart';
import 'dashboard_screen.dart';

class DemoAuthService extends AuthService {
  DemoAuthService({required FakeFirebaseFirestore firestore})
      : super.demo(firestore: firestore);

  final List<UserModel> _profiles = [
    const UserModel(
      id: 'demo-admin',
      name: 'Demo Admin',
      email: 'admin@petcore.local',
      role: 'ADMIN',
      branchId: 'demo-branch',
    ),
    const UserModel(
      id: 'demo-vet',
      name: 'Demo Veterinarian',
      email: 'vet@petcore.local',
      role: 'VETERINARIAN',
      branchId: 'demo-branch',
    ),
    const UserModel(
      id: 'demo-staff',
      name: 'Demo Clinic Staff',
      email: 'staff@petcore.local',
      role: 'CLINIC STAFF',
      branchId: 'demo-branch',
    ),
  ];

  UserModel? profileFor(String email, String password) {
    const passwords = {
      'admin@petcore.local': 'PetCoreAdmin2026!',
      'vet@petcore.local': 'PetCoreVet2026!',
      'staff@petcore.local': 'PetCoreStaff2026!',
    };
    if (passwords[email.trim().toLowerCase()] != password) return null;
    for (final profile in _profiles) {
      if (profile.email == email.trim().toLowerCase()) return profile;
    }
    return null;
  }

  @override
  Future<List<UserModel>> getUserProfiles() async => List.unmodifiable(_profiles);

  @override
  Future<void> updateUserProfile(UserModel user) async {
    final index = _profiles.indexWhere((profile) => profile.id == user.id);
    if (index >= 0) _profiles[index] = user;
  }

  @override
  Future<void> signOut() async {}
}

class DemoAuthGate extends StatefulWidget {
  const DemoAuthGate({super.key});

  @override
  State<DemoAuthGate> createState() => _DemoAuthGateState();
}

class _DemoAuthGateState extends State<DemoAuthGate> {
  late final FakeFirebaseFirestore _firestore;
  late final DemoAuthService _authService;
  late final BranchService _branchService;
  late final FirestoreService _firestoreService;
  UserModel? _profile;

  @override
  void initState() {
    super.initState();
    _firestore = FakeFirebaseFirestore();
    _authService = DemoAuthService(firestore: _firestore);
    _branchService = BranchService(firestore: _firestore);
    _firestoreService = FirestoreService(firestore: _firestore);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) {
      return DemoLoginScreen(
        onSignIn: (email, password) {
          final signedInProfile = _authService.profileFor(email, password);
          if (signedInProfile == null) return false;
          setState(() => _profile = signedInProfile);
          return true;
        },
      );
    }

    return DashboardScreen(
      authService: _authService,
      branchService: _branchService,
      firestoreService: _firestoreService,
      firebaseUser: null,
      userProfile: profile,
      onSignedOut: () => setState(() => _profile = null),
    );
  }
}

class DemoLoginScreen extends StatefulWidget {
  final bool Function(String email, String password) onSignIn;

  const DemoLoginScreen({super.key, required this.onSignIn});

  @override
  State<DemoLoginScreen> createState() => _DemoLoginScreenState();
}

class _DemoLoginScreenState extends State<DemoLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    final signedIn = widget.onSignIn(
      _emailController.text,
      _passwordController.text,
    );
    setState(() {
      _errorMessage = signedIn ? null : 'Use one of the demo accounts below.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.pets, size: 64),
                const SizedBox(height: 16),
                Text(
                  'PetCore Demo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _signIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Enter demo'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Demo accounts:\n'
                  'admin@petcore.local / PetCoreAdmin2026!\n'
                  'vet@petcore.local / PetCoreVet2026!\n'
                  'staff@petcore.local / PetCoreStaff2026!',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
