import 'package:flutter/material.dart';
import '../models/owner_model.dart';
import '../models/pet_model.dart';
import '../services/firestore_service.dart';

// Pet Registration / Edit form screen with validation, auto Pet ID generation,
// owner linking, and Firestore integration.
class PetRegistrationScreen extends StatefulWidget {
  final FirestoreService firestoreService;
  final OwnerModel? preSelectedOwner; // If opened from owner profile
  final PetModel? existingPet; // null = create mode, non-null = edit mode

  const PetRegistrationScreen({
    super.key,
    required this.firestoreService,
    this.preSelectedOwner,
    this.existingPet,
  });

  @override
  State<PetRegistrationScreen> createState() => _PetRegistrationScreenState();
}

class _PetRegistrationScreenState extends State<PetRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _dobAgeController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();

  String _selectedSpecies = 'Dog';
  String _selectedGender = 'Male';
  String _generatedPetId = '';
  bool _isSaving = false;
  bool _isLoadingId = true;

  // Owner selection
  List<OwnerModel> _owners = [];
  OwnerModel? _selectedOwner;
  bool _isLoadingOwners = true;

  bool get _isEditMode => widget.existingPet != null;

  final List<String> _speciesOptions = [
    'Dog',
    'Cat',
    'Bird',
    'Fish',
    'Rabbit',
    'Hamster',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (_isEditMode) {
      // Edit mode: pre-fill fields from existing pet
      final pet = widget.existingPet!;
      _nameController.text = pet.name;
      _breedController.text = pet.breed;
      _dobAgeController.text = pet.dobAge;
      _weightController.text = pet.weight.toString();
      _colorController.text = pet.color;
      _selectedSpecies = _speciesOptions.contains(pet.species)
          ? pet.species
          : 'Other';
      _selectedGender = pet.gender == 'Female' ? 'Female' : 'Male';
      _generatedPetId = pet.petId;

      // Load owners for dropdown
      final owners = await widget.firestoreService.getActiveOwners();
      if (!mounted) return;
      setState(() {
        _owners = owners;
        _isLoadingOwners = false;
        _isLoadingId = false;
        _selectedOwner = owners.firstWhere(
          (o) => o.id == pet.ownerId,
          orElse: () => owners.first,
        );
      });
    } else {
      // Create mode: generate Pet ID and load owners
      final results = await Future.wait([
        widget.firestoreService.getNextPetId(),
        widget.firestoreService.getActiveOwners(),
      ]);

      if (!mounted) return;
      setState(() {
        _generatedPetId = results[0] as String;
        _isLoadingId = false;
        _owners = results[1] as List<OwnerModel>;
        _isLoadingOwners = false;

        // Pre-select owner if provided
        if (widget.preSelectedOwner != null) {
          _selectedOwner = _owners.firstWhere(
            (o) => o.id == widget.preSelectedOwner!.id,
            orElse: () => widget.preSelectedOwner!,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _dobAgeController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _savePet() async {
    // 1. Validate form
    if (!_formKey.currentState!.validate()) return;

    // 2. Check owner selected
    if (_selectedOwner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an owner'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        // Update existing pet
        final updatedPet = PetModel(
          id: widget.existingPet!.id,
          petId: widget.existingPet!.petId,
          name: _nameController.text.trim(),
          species: _selectedSpecies,
          breed: _breedController.text.trim(),
          gender: _selectedGender,
          dobAge: _dobAgeController.text.trim(),
          weight: double.tryParse(_weightController.text.trim()) ?? 0.0,
          color: _colorController.text.trim(),
          ownerId: _selectedOwner!.id!,
        );

        await widget.firestoreService.updatePet(updatedPet);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        // Create new pet
        final newPet = PetModel(
          petId: _generatedPetId,
          name: _nameController.text.trim(),
          species: _selectedSpecies,
          breed: _breedController.text.trim(),
          gender: _selectedGender,
          dobAge: _dobAgeController.text.trim(),
          weight: double.tryParse(_weightController.text.trim()) ?? 0.0,
          color: _colorController.text.trim(),
          ownerId: _selectedOwner!.id!,
        );

        await widget.firestoreService.addPet(newPet);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newPet.name} (${newPet.petId}) registered!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save pet: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Pet' : 'Register Pet'),
      ),
      body: _isLoadingId || _isLoadingOwners
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pet ID display (auto-generated, read-only)
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.badge,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pet ID: $_generatedPetId',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1. Owner selection dropdown
                    DropdownButtonFormField<OwnerModel>(
                      initialValue: _selectedOwner,
                      decoration: const InputDecoration(
                        labelText: 'Owner',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      items: _owners.map((owner) {
                        return DropdownMenuItem(
                          value: owner,
                          child: Text('${owner.name} (${owner.phone})'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedOwner = val),
                      validator: (val) =>
                          val == null ? 'Please select an owner' : null,
                    ),
                    const SizedBox(height: 16),

                    // 2. Pet Name
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Pet Name',
                        prefixIcon: Icon(Icons.pets),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter pet name';
                        }
                        if (val.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. Species dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSpecies,
                      decoration: const InputDecoration(
                        labelText: 'Species',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: _speciesOptions.map((species) {
                        return DropdownMenuItem(
                          value: species,
                          child: Text(species),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSpecies = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // 4. Breed
                    TextFormField(
                      controller: _breedController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Breed',
                        prefixIcon: Icon(Icons.pets_outlined),
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Labrador Retriever',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter breed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 5. Gender toggle
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.wc),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'Female', child: Text('Female')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedGender = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 6. DOB / Age
                    TextFormField(
                      controller: _dobAgeController,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth / Age',
                        prefixIcon: Icon(Icons.cake),
                        border: OutlineInputBorder(),
                        hintText: 'e.g. 2 years or 15/03/2022',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter DOB or age';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 7. Weight
                    TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        prefixIcon: Icon(Icons.monitor_weight),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter weight';
                        }
                        final weight = double.tryParse(val.trim());
                        if (weight == null || weight <= 0) {
                          return 'Enter a valid weight';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 8. Color
                    TextFormField(
                      controller: _colorController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Color / Markings',
                        prefixIcon: Icon(Icons.color_lens),
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Golden, Black & White',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter color';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _savePet,
                        icon: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(_isEditMode ? Icons.save : Icons.pets),
                        label: Text(
                            _isEditMode ? 'Save Changes' : 'Register Pet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
