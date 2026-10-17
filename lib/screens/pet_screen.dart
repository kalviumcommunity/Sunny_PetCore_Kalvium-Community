import 'package:flutter/material.dart';
import '../models/pet_model.dart';
import '../services/firestore_service.dart';
import '../widgets/petcore_ui.dart';
import 'documents_screen.dart';
import 'pet_registration_screen.dart';

class PetScreen extends StatefulWidget {
  final FirestoreService firestoreService;

  const PetScreen({super.key, required this.firestoreService});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  List<PetModel> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPets();
  }

  Future<void> _fetchPets() async {
    setState(() => _isLoading = true);
    try {
      final pets = await widget.firestoreService.getPets();
      setState(() {
        _pets = pets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openRegisterPet() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PetRegistrationScreen(
          firestoreService: widget.firestoreService,
        ),
      ),
    );
    if (result == true) {
      _fetchPets();
    }
  }

  void _openDocuments(PetModel pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentsScreen(petId: pet.petId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pets'),
      ),
      body: _isLoading
          ? const PetCoreLoadingState()
          : _pets.isEmpty
              ? const PetCoreEmptyState(
                  title: 'No pets added yet.',
                  subtitle: 'Add a pet profile to begin tracking medical history.',
                  icon: Icons.pets_outlined,
                )
              : ListView.builder(
                  itemCount: _pets.length,
                  itemBuilder: (context, index) {
                    final pet = _pets[index];
                    return PetCoreInfoCard(
                      title: '${pet.name} (${pet.petId})',
                      subtitle:
                          'Species: ${pet.species} | Breed: ${pet.breed}\n'
                          'Gender: ${pet.gender} | DOB/Age: ${pet.dobAge}\n'
                          'Weight: ${pet.weight} kg | Color: ${pet.color}\n'
                          'Owner ID: ${pet.ownerId}',
                      leadingIcon: Icons.pets,
                      onTap: () => _openDocuments(pet),
                      trailing: IconButton(
                        tooltip: 'Medical documents',
                        onPressed: () => _openDocuments(pet),
                        icon: const Icon(Icons.folder_open_outlined),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRegisterPet,
        icon: const Icon(Icons.add),
        label: const Text('Add pet'),
      ),
    );
  }
}
