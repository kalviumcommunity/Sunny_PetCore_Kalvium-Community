import 'package:flutter/material.dart';
import '../models/pet_model.dart';
import '../services/firestore_service.dart';

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

  void _showAddPetDialog() {
    final petIdController = TextEditingController();
    final nameController = TextEditingController();
    final speciesController = TextEditingController();
    final breedController = TextEditingController();
    final genderController = TextEditingController();
    final dobAgeController = TextEditingController();
    final weightController = TextEditingController();
    final colorController = TextEditingController();
    final ownerIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Pet'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: petIdController,
                decoration: const InputDecoration(labelText: 'Pet ID'),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: speciesController,
                decoration: const InputDecoration(labelText: 'Species'),
              ),
              TextField(
                controller: breedController,
                decoration: const InputDecoration(labelText: 'Breed'),
              ),
              TextField(
                controller: genderController,
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              TextField(
                controller: dobAgeController,
                decoration: const InputDecoration(labelText: 'DOB / Age'),
              ),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
              TextField(
                controller: ownerIdController,
                decoration: const InputDecoration(labelText: 'Owner ID'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final newPet = PetModel(
                petId: petIdController.text.trim(),
                name: nameController.text.trim(),
                species: speciesController.text.trim(),
                breed: breedController.text.trim(),
                gender: genderController.text.trim(),
                dobAge: dobAgeController.text.trim(),
                weight: double.tryParse(weightController.text.trim()) ?? 0.0,
                color: colorController.text.trim(),
                ownerId: ownerIdController.text.trim(),
              );

              await widget.firestoreService.addPet(newPet);
              if (ctx.mounted) Navigator.pop(ctx);
              _fetchPets();
            },
            child: const Text('Save'),
          ),
        ],
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
          ? const Center(child: CircularProgressIndicator())
          : _pets.isEmpty
              ? const Center(child: Text('No pets added yet.'))
              : ListView.builder(
                  itemCount: _pets.length,
                  itemBuilder: (context, index) {
                    final pet = _pets[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.pets)),
                        title: Text('${pet.name} (${pet.petId})'),
                        subtitle: Text(
                          'Species: ${pet.species} | Breed: ${pet.breed}\n'
                          'Gender: ${pet.gender} | DOB/Age: ${pet.dobAge}\n'
                          'Weight: ${pet.weight} kg | Color: ${pet.color}\n'
                          'Owner ID: ${pet.ownerId}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPetDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
