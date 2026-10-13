import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/clinical_record_model.dart';
import '../models/dashboard_data.dart';
import '../models/pet_model.dart';
import '../models/role_permissions.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/branch_service.dart';
import '../services/dashboard_data_service.dart';
import '../services/firestore_service.dart';
import 'branch_management_screen.dart';
import 'clinical_record_dialog.dart';
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
  final List<PetModel> _recentPets = [];

  void _rememberPet(PetModel pet) {
    setState(() {
      _recentPets.removeWhere((item) => item.id == pet.id);
      _recentPets.insert(0, pet);
      if (_recentPets.length > 5) _recentPets.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = UserRole.fromValue(widget.userProfile.role);
    final screens = <Widget>[];
    final destinations = <NavigationDestination>[];

    screens.add(
      _DashboardHome(
        profile: widget.userProfile,
        firestoreService: widget.firestoreService,
        recentPets: _recentPets,
        onPetViewed: _rememberPet,
        onRegisterPet: () {},
      ),
    );
    destinations.add(
      const NavigationDestination(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
    );

    if (RolePermissions.canAccessOwners(role)) {
      screens.add(OwnerScreen(firestoreService: widget.firestoreService));
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.person),
        label: 'Owners',
      ));
    }

    int? petScreenIndex;
    if (RolePermissions.canAccessPets(role)) {
      petScreenIndex = screens.length;
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

    if (petScreenIndex != null) {
      screens[0] = _DashboardHome(
        profile: widget.userProfile,
        firestoreService: widget.firestoreService,
        recentPets: _recentPets,
        onPetViewed: _rememberPet,
        onRegisterPet: () => setState(() => _currentIndex = petScreenIndex!),
      );
    }


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

class _DashboardHome extends StatefulWidget {
  final UserModel profile;
  final FirestoreService firestoreService;
  final List<PetModel> recentPets;
  final ValueChanged<PetModel> onPetViewed;
  final VoidCallback onRegisterPet;

  const _DashboardHome({
    required this.profile,
    required this.firestoreService,
    required this.recentPets,
    required this.onPetViewed,
    required this.onRegisterPet,
  });

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  late Future<DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _reloadRecords();
  }

  void _reloadRecords() {
    _dashboardFuture = DashboardDataService(
      firestoreService: widget.firestoreService,
    ).load();
  }

  Future<void> _refreshRecords() async {
    setState(_reloadRecords);
    await _dashboardFuture;
  }

  @override
  Widget build(BuildContext context) {
    final role = UserRole.fromValue(widget.profile.role);
    final canCreateClinical =
        role == UserRole.admin || role == UserRole.veterinarian;
    final canRegisterPet =
        role == UserRole.admin || role == UserRole.clinicStaff;

    return FutureBuilder<DashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: FilledButton.icon(
              onPressed: () => setState(_reloadRecords),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry dashboard data'),
            ),
          );
        }

        final dashboardData = snapshot.data!;

        return RefreshIndicator(
          onRefresh: _refreshRecords,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Welcome, ${widget.profile.name.isEmpty ? widget.profile.email : widget.profile.name}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('Role: ${role.label}'),
              Text(
                'Branch: ${widget.profile.branchId.isEmpty ? 'Unassigned' : widget.profile.branchId}',
              ),
              const SizedBox(height: 16),
              _QuickActions(
                firestoreService: widget.firestoreService,
                profile: widget.profile,
                canCreateClinical: canCreateClinical,
                canRegisterPet: canRegisterPet,
                onRegisterPet: widget.onRegisterPet,
                onPetViewed: widget.onPetViewed,
                onRecordAdded: _refreshRecords,
              ),
              const SizedBox(height: 16),
              _RecordSection(
                title: "Today's Consultations",
                icon: Icons.medical_services_outlined,
                records: dashboardData.todaysConsultations,
              ),
              _RecordSection(
                title: 'Upcoming Follow-ups',
                icon: Icons.event_note_outlined,
                records: dashboardData.upcomingFollowUps,
                dateSelector: (record) => record.followUpDate,
              ),
              _RecordSection(
                title: 'Vaccinations Due',
                icon: Icons.vaccines_outlined,
                records: dashboardData.vaccinationsDue,
                dateSelector: (record) => record.dueDate,
              ),
              _RecentPetsSection(pets: widget.recentPets),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  final FirestoreService firestoreService;
  final UserModel profile;
  final bool canCreateClinical;
  final bool canRegisterPet;
  final VoidCallback onRegisterPet;
  final ValueChanged<PetModel> onPetViewed;
  final VoidCallback onRecordAdded;

  const _QuickActions({
    required this.firestoreService,
    required this.profile,
    required this.canCreateClinical,
    required this.canRegisterPet,
    required this.onRegisterPet,
    required this.onPetViewed,
    required this.onRecordAdded,
  });

  Future<void> _showRecordDialog(BuildContext context, String type) async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => ClinicalRecordDialog(
        type: type,
        firestoreService: firestoreService,
        userProfile: profile,
      ),
    );
    if (added == true) onRecordAdded();
  }

  Future<void> _searchPet(BuildContext context) async {
    final pet = await showDialog<PetModel>(
      context: context,
      builder: (_) => _PetSearchDialog(firestoreService: firestoreService),
    );
    if (pet != null) onPetViewed(pet);
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      _ActionButton(
        icon: Icons.search,
        label: 'Search Pet',
        onPressed: () => _searchPet(context),
      ),
    ];
    if (canRegisterPet) {
      actions.add(_ActionButton(
        icon: Icons.pets,
        label: 'Register Pet',
        onPressed: onRegisterPet,
      ));
    }
    if (canCreateClinical) {
      actions.addAll([
        _ActionButton(
          icon: Icons.add_circle_outline,
          label: 'New Consultation',
          onPressed: () => _showRecordDialog(context, 'CONSULTATION'),
        ),
        _ActionButton(
          icon: Icons.vaccines_outlined,
          label: 'Add Vaccination',
          onPressed: () => _showRecordDialog(context, 'VACCINATION'),
        ),
        _ActionButton(
          icon: Icons.medication_outlined,
          label: 'Add Treatment',
          onPressed: () => _showRecordDialog(context, 'TREATMENT'),
        ),
      ]);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 8, runSpacing: 8, children: actions),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _RecordSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<ClinicalRecord> records;
  final DateTime? Function(ClinicalRecord record)? dateSelector;

  const _RecordSection({
    required this.title,
    required this.icon,
    required this.records,
    this.dateSelector,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text('${records.length} record${records.length == 1 ? '' : 's'}'),
        children: records.isEmpty
            ? const [ListTile(title: Text('No records to display.'))]
            : records.take(5).map((record) {
                final date = dateSelector?.call(record) ?? record.date;
                return ListTile(
                  title: Text('${record.petName} · ${record.title}'),
                  subtitle: Text(
                    '${date.day}/${date.month}/${date.year} · ${record.veterinarian}',
                  ),
                );
              }).toList(),
      ),
    );
  }
}

class _RecentPetsSection extends StatelessWidget {
  final List<PetModel> pets;

  const _RecentPetsSection({required this.pets});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.history),
        title: const Text('Recently Viewed Pets'),
        subtitle: Text('${pets.length} pet${pets.length == 1 ? '' : 's'}'),
        children: pets.isEmpty
            ? const [ListTile(title: Text('Search for a pet to get started.'))]
            : pets
                .map((pet) => ListTile(
                      leading: const Icon(Icons.pets),
                      title: Text('${pet.name} (${pet.petId})'),
                      subtitle: Text('${pet.species} · ${pet.breed}'),
                    ))
                .toList(),
      ),
    );
  }
}

class _PetSearchDialog extends StatefulWidget {
  final FirestoreService firestoreService;

  const _PetSearchDialog({required this.firestoreService});

  @override
  State<_PetSearchDialog> createState() => _PetSearchDialogState();
}

class _PetSearchDialogState extends State<_PetSearchDialog> {
  final _queryController = TextEditingController();
  List<PetModel> _results = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_queryController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final results = await widget.firestoreService.searchPets(
        _queryController.text,
      );
      if (mounted) setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search pets'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _queryController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Pet ID, name, or species',
                suffixIcon: IconButton(
                  onPressed: _isLoading ? null : _search,
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else if (_results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No matching pets found.'),
              )
            else
              ..._results.map((pet) => ListTile(
                    leading: const Icon(Icons.pets),
                    title: Text('${pet.name} (${pet.petId})'),
                    subtitle: Text('${pet.species} · ${pet.breed}'),
                    onTap: () => Navigator.pop(context, pet),
                  )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
      ),
    );
  }
}