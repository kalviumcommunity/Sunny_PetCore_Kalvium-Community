import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/treatment_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/medical_firestore_service.dart';

class TreatmentFormScreen extends StatefulWidget {
  final String petId;

  const TreatmentFormScreen({super.key, required this.petId});

  @override
  State<TreatmentFormScreen> createState() => _TreatmentFormScreenState();
}

class _TreatmentFormScreenState extends State<TreatmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _medicalService = MedicalFirestoreService();
  final _symptomsController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _medicineController = TextEditingController();
  final _dosageController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  UserModel? _vet;
  DateTime? _followUpDate;
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
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _medicineController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    _notesController.dispose();
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
        _profileError = 'Could not load staff profile';
      });
    }
  }

  String? _requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Please enter $label';
    return null;
  }

  Future<void> _selectFollowUpDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selectedDate != null) setState(() => _followUpDate = selectedDate);
  }

  Future<void> _saveTreatment() async {
    if (!_formKey.currentState!.validate() || _vet == null) return;

    setState(() => _isSaving = true);
    try {
      final treatment = TreatmentModel(
        petId: widget.petId,
        vetId: _vet!.id,
        branchId: _vet!.branchId,
        symptoms: _symptomsController.text.trim(),
        diagnosis: _diagnosisController.text.trim(),
        treatment: _treatmentController.text.trim(),
        medicine: _medicineController.text.trim(),
        dosage: _dosageController.text.trim(),
        duration: _durationController.text.trim(),
        followUpDate: _followUpDate,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
      );
      await _medicalService.addTreatment(treatment);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treatment recorded successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save treatment: $error'),
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
      appBar: AppBar(title: const Text('New Treatment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.badge_outlined),
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
                controller: _symptomsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Symptoms',
                  prefixIcon: Icon(Icons.sick_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (value) => _requiredValidator(value, 'symptoms'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _diagnosisController,
                decoration: const InputDecoration(
                  labelText: 'Diagnosis',
                  prefixIcon: Icon(Icons.assignment_outlined),
                ),
                validator: (value) => _requiredValidator(value, 'diagnosis'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _treatmentController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Treatment',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
                validator: (value) => _requiredValidator(value, 'treatment'),
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
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  prefixIcon: Icon(Icons.schedule_outlined),
                ),
                validator: (value) => _requiredValidator(value, 'duration'),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectFollowUpDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Follow-up Date',
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    suffixIcon: _followUpDate == null
                        ? null
                        : IconButton(
                            tooltip: 'Clear follow-up date',
                            onPressed: () =>
                                setState(() => _followUpDate = null),
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  child: Text(
                    _followUpDate == null
                        ? 'Not set'
                        : DateFormat.yMMMd().format(_followUpDate!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving || _isLoadingProfile || _vet == null
                      ? null
                      : _saveTreatment,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving...' : 'Save Treatment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}