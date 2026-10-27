// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/clinical_record_model.dart';
import '../models/pet_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class ClinicalRecordDialog extends StatefulWidget {
  final String type;
  final FirestoreService firestoreService;
  final UserModel userProfile;

  const ClinicalRecordDialog({
    super.key,
    required this.type,
    required this.firestoreService,
    required this.userProfile,
  });

  @override
  State<ClinicalRecordDialog> createState() => _ClinicalRecordDialogState();
}

class _ClinicalRecordDialogState extends State<ClinicalRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  late Future<List<PetModel>> _petsFuture;
  PetModel? _selectedPet;
  DateTime _recordDate = DateTime.now();
  DateTime? _followUpDate;
  DateTime? _dueDate;

  bool get _isVaccination => widget.type == 'VACCINATION';
  bool get _hasFollowUp => widget.type != 'VACCINATION';

  @override
  void initState() {
    super.initState();
    _petsFuture = widget.firestoreService.getPets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool dueDate}) async {
    final initialDate = dueDate ? (_dueDate ?? DateTime.now()) :
        (_followUpDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initialDate,
    );
    if (picked == null) return;
    setState(() {
      if (dueDate) {
        _dueDate = picked;
      } else {
        _followUpDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedPet == null) return;
    if (_isVaccination && _dueDate == null) return;

    final record = ClinicalRecord(
      type: widget.type,
      petId: _selectedPet!.petId,
      petName: _selectedPet!.name,
      date: _recordDate,
      title: _titleController.text.trim(),
      notes: _notesController.text.trim(),
      followUpDate: _followUpDate,
      dueDate: _dueDate,
      veterinarian: widget.userProfile.name.isEmpty
          ? widget.userProfile.email
          : widget.userProfile.name,
      branchId: widget.userProfile.branchId,
    );

    await widget.firestoreService.addClinicalRecord(record);
    if (mounted) Navigator.pop(context, true);
  }

  String get _title {
    switch (widget.type) {
      case 'VACCINATION':
        return 'Add vaccination';
      case 'TREATMENT':
        return 'Add treatment';
      default:
        return 'New consultation';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title),
      content: FutureBuilder<List<PetModel>>(
        future: _petsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError || (snapshot.data ?? []).isEmpty) {
            return const Text('Register a pet before adding a clinical record.');
          }

          final pets = snapshot.data!;
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<PetModel>(
                    value: _selectedPet,
                    decoration: const InputDecoration(labelText: 'Pet'),
                    items: pets
                        .map((pet) => DropdownMenuItem<PetModel>(
                              value: pet,
                              child: Text('${pet.name} (${pet.petId})'),
                            ))
                        .toList(),
                    onChanged: (pet) => setState(() => _selectedPet = pet),
                    validator: (value) => value == null ? 'Select a pet' : null,
                  ),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: _isVaccination ? 'Vaccine name' : 'Summary',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a summary'
                        : null,
                  ),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 3,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Record date'),
                    subtitle: Text(DateFormat.yMMMd().format(_recordDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: _recordDate,
                      );
                      if (picked != null) setState(() => _recordDate = picked);
                    },
                  ),
                  if (_hasFollowUp)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Follow-up date'),
                      subtitle: Text(_followUpDate == null
                          ? 'Not set'
                          : DateFormat.yMMMd().format(_followUpDate!)),
                      trailing: const Icon(Icons.event),
                      onTap: () => _pickDate(dueDate: false),
                    ),
                  if (_isVaccination)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Next due date'),
                      subtitle: Text(_dueDate == null
                          ? 'Required'
                          : DateFormat.yMMMd().format(_dueDate!)),
                      trailing: const Icon(Icons.event_available),
                      onTap: () => _pickDate(dueDate: true),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}