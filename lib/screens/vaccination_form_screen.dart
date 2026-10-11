import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../models/vaccination_model.dart';
import '../services/auth_service.dart';
import '../services/medical_firestore_service.dart';

class VaccinationFormScreen extends StatefulWidget {
  final String petId;

  const VaccinationFormScreen({super.key, required this.petId});

  @override
  State<VaccinationFormScreen> createState() => _VaccinationFormScreenState();
}

class _VaccinationFormScreenState extends State<VaccinationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nextDueDateFieldKey = GlobalKey<FormFieldState<DateTime>>();
  final _authService = AuthService();
  final _medicalService = MedicalFirestoreService();
  final _vaccineNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  UserModel? _vet;
  DateTime? _dateGiven;
  DateTime? _nextDueDate;
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
    _vaccineNameController.dispose();
    _dosageController.dispose();
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

  Future<void> _selectDate(
    FormFieldState<DateTime> field, {
    required bool isNextDueDate,
  }) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = isNextDueDate ? (_dateGiven ?? today) : DateTime(2000);
    final lastDate = isNextDueDate ? today.add(const Duration(days: 3650)) : today;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: field.value ?? (isNextDueDate ? firstDate : today),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (selectedDate == null) return;
    setState(() {
      if (isNextDueDate) {
        _nextDueDate = selectedDate;
      } else {
        _dateGiven = selectedDate;
        if (_nextDueDate != null && _nextDueDate!.isBefore(selectedDate)) {
          _nextDueDate = null;
        }
      }
    });
    if (!isNextDueDate && _nextDueDate == null) {
      _nextDueDateFieldKey.currentState?.didChange(null);
    }
    field.didChange(selectedDate);
  }

  Widget _dateField({required bool isNextDueDate}) {
    final label = isNextDueDate ? 'Next Due Date' : 'Date Given';
    return FormField<DateTime>(
      key: isNextDueDate ? _nextDueDateFieldKey : null,
      validator: (value) => value == null ? 'Please select $label' : null,
      builder: (field) {
        final value = isNextDueDate ? _nextDueDate : _dateGiven;
        return InkWell(
          onTap: () => _selectDate(field, isNextDueDate: isNextDueDate),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.calendar_month_outlined),
              errorText: field.errorText,
            ),
            child: Text(
              value == null ? 'Select date' : DateFormat.yMMMd().format(value),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveVaccination() async {
    if (!_formKey.currentState!.validate() ||
        _vet == null ||
        _dateGiven == null ||
        _nextDueDate == null) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final vaccination = VaccinationModel(
        petId: widget.petId,
        vetId: _vet!.id,
        branchId: _vet!.branchId,
        vaccineName: _vaccineNameController.text.trim(),
        dateGiven: _dateGiven!,
        nextDueDate: _nextDueDate!,
        dosage: _dosageController.text.trim(),
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
      );
      await _medicalService.addVaccination(vaccination);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vaccination recorded successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save vaccination: $error'),
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
      appBar: AppBar(title: const Text('New Vaccination')),
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
                controller: _vaccineNameController,
                decoration: const InputDecoration(
                  labelText: 'Vaccine Name',
                  prefixIcon: Icon(Icons.vaccines_outlined),
                ),
                validator: (value) => _requiredValidator(value, 'vaccine name'),
              ),
              const SizedBox(height: 12),
              _dateField(isNextDueDate: false),
              const SizedBox(height: 12),
              _dateField(isNextDueDate: true),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
                validator: (value) => _requiredValidator(value, 'dosage'),
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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isSaving || _isLoadingProfile || _vet == null
                    ? null
                    : _saveVaccination,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save Vaccination'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}