import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/consultation_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/medical_firestore_service.dart';

class ConsultationFormScreen extends StatefulWidget {
  final String petId;

  const ConsultationFormScreen({super.key, required this.petId});

  @override
  State<ConsultationFormScreen> createState() =>
      _ConsultationFormScreenState();
}

class _ConsultationFormScreenState extends State<ConsultationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _medicalService = MedicalFirestoreService();
  final _symptomsController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _clinicalNotesController = TextEditingController();
  final _treatmentGivenController = TextEditingController();

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
    _clinicalNotesController.dispose();
    _treatmentGivenController.dispose();
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

  Future<void> _saveConsultation() async {
    if (!_formKey.currentState!.validate() || _vet == null) return;

    setState(() => _isSaving = true);
    try {
      final consultation = ConsultationModel(
        petId: widget.petId,
        vetId: _vet!.id,
        branchId: _vet!.branchId,
        symptoms: _symptomsController.text.trim(),
        diagnosis: _diagnosisController.text.trim(),
        clinicalNotes: _clinicalNotesController.text.trim(),
        treatmentGiven: _treatmentGivenController.text.trim(),
        followUpDate: _followUpDate,
        createdAt: DateTime.now(),
      );
      await _medicalService.addConsultation(consultation);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consultation recorded successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save consultation: $error'),
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
      appBar: AppBar(title: const Text('New Consultation')),
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
                controller: _clinicalNotesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Clinical Notes',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _treatmentGivenController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Treatment Given',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    _requiredValidator(value, 'treatment given'),
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving || _isLoadingProfile || _vet == null
                      ? null
                      : _saveConsultation,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving...' : 'Save Consultation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}