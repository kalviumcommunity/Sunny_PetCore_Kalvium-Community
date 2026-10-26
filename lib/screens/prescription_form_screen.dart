import 'package:flutter/material.dart';

import '../models/prescription_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/medical_firestore_service.dart';

class PrescriptionFormScreen extends StatefulWidget {
  final String petId;

  const PrescriptionFormScreen({super.key, required this.petId});

  @override
  State<PrescriptionFormScreen> createState() =>
      _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _medicalService = MedicalFirestoreService();
  final _medicineController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();

  UserModel? _vet;
  bool _isLoadingProfile = true;
  bool _isSaving = false;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _loadVetProfile();
  }

  @override
  void dispose() {
    _medicineController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadVetProfile() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) {
      setState(() {
        _isLoadingProfile = false;
        _profileError = 'No signed-in staff profile';
      });
      return;
    }
    try {
      final vet = await _authService.getUserProfile(firebaseUser.uid);
      if (!mounted) return;
      setState(() {
        _vet = vet;
        _isLoadingProfile = false;
        if (vet == null) _profileError = 'Staff profile not found';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
        _profileError = 'Could not load staff profile: $error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load staff profile: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Please enter $label';
    return null;
  }

  Future<void> _savePrescription() async {
    if (_isSaving || !_formKey.currentState!.validate() || _vet == null) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final prescription = PrescriptionModel(
        petId: widget.petId,
        vetId: _vet!.id,
        branchId: _vet!.branchId,
        medicine: _medicineController.text.trim(),
        dosage: _dosageController.text.trim(),
        frequency: _frequencyController.text.trim(),
        duration: _durationController.text.trim(),
        instructions: _instructionsController.text.trim(),
        createdAt: DateTime.now(),
      );
      await _medicalService.addPrescription(prescription);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription recorded successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save prescription: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vetName = _vet?.name.trim() ?? '';
    final recordedBy = vetName.isNotEmpty ? vetName : _vet?.email ?? '';
    final branch = _vet?.branchId.isNotEmpty == true
        ? _vet!.branchId
        : 'Unassigned';
    return Scaffold(
      appBar: AppBar(title: const Text('New Prescription')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  leading: _isLoadingProfile
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.badge_outlined),
                  title: Text(
                    _isLoadingProfile
                        ? 'Loading staff profile...'
                        : _profileError != null
                            ? _profileError!
                            : 'Recorded by $recordedBy - $branch',
                  ),
                  subtitle: _vet == null ? null : Text('Pet ID: ${widget.petId}'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _medicineController,
                decoration: const InputDecoration(
                  labelText: 'Medicine',
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
                validator: (value) => _requiredValidator(value, 'medicine'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
                validator: (value) => _requiredValidator(value, 'dosage'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  prefixIcon: Icon(Icons.schedule_outlined),
                ),
                validator: (value) => _requiredValidator(value, 'frequency'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  prefixIcon: Icon(Icons.timelapse_outlined),
                ),
                validator: (value) => _requiredValidator(value, 'duration'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isSaving || _isLoadingProfile || _vet == null
                    ? null
                    : _savePrescription,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save Prescription'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}