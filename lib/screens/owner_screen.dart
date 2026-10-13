import 'package:flutter/material.dart';
import '../models/owner_model.dart';
import '../services/firestore_service.dart';
import '../widgets/petcore_ui.dart';
import 'owner_profile_screen.dart';
import 'owner_registration_screen.dart';

// Owner Screen displaying all registered owners and a button to register new owners.
class OwnerScreen extends StatefulWidget {
  final FirestoreService firestoreService;

  const OwnerScreen({super.key, required this.firestoreService});

  @override
  State<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen> {
  List<OwnerModel> _owners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOwners();
  }

  Future<void> _fetchOwners() async {
    setState(() => _isLoading = true);
    try {
      final owners = await widget.firestoreService.getOwners();
      setState(() {
        _owners = owners;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerRegistrationScreen(
          firestoreService: widget.firestoreService,
        ),
      ),
    ).then((_) => _fetchOwners());
  }

  void _navigateToProfile(OwnerModel owner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerProfileScreen(owner: owner),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owners'),
      ),
      body: _isLoading
          ? const PetCoreLoadingState()
          : _owners.isEmpty
              ? const PetCoreEmptyState(
                  title: 'No owners registered yet.',
                  subtitle: 'Create the first owner profile to begin record tracking.',
                  icon: Icons.person_outline,
                )
              : ListView.builder(
                  itemCount: _owners.length,
                  itemBuilder: (context, index) {
                    final owner = _owners[index];
                    return PetCoreInfoCard(
                      title: owner.name,
                      subtitle:
                          'Phone: ${owner.phone}\nEmail: ${owner.email}\nAddress: ${owner.address}',
                      leadingIcon: Icons.person,
                      onTap: () => _navigateToProfile(owner),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToRegistration,
        icon: const Icon(Icons.add),
        label: const Text('Add owner'),
      ),
    );
  }
}
