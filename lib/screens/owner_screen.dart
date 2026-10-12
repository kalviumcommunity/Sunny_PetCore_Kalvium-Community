import 'package:flutter/material.dart';
import '../models/owner_model.dart';
import '../services/firestore_service.dart';
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
          ? const Center(child: CircularProgressIndicator())
          : _owners.isEmpty
              ? const Center(child: Text('No owners registered yet.'))
              : ListView.builder(
                  itemCount: _owners.length,
                  itemBuilder: (context, index) {
                    final owner = _owners[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(owner.name),
                        subtitle: Text(
                          'Phone: ${owner.phone}\nEmail: ${owner.email}\nAddress: ${owner.address}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _navigateToProfile(owner),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToRegistration,
        child: const Icon(Icons.add),
      ),
    );
  }
}
