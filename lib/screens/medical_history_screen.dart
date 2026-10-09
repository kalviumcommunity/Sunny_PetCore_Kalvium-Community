import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/medical_firestore_service.dart';
import 'consultation_form_screen.dart';
import 'treatment_form_screen.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final String petId;

  const MedicalHistoryScreen({super.key, required this.petId});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  final _medicalService = MedicalFirestoreService();
  late Future<List<Map<String, dynamic>>> _historyFuture;
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _historyFuture = _medicalService.getMedicalHistoryForPet(widget.petId);
  }

  DateTime _recordDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _recordSummary(Map<String, dynamic> record) {
    final type = record['type'] as String? ?? '';
    final candidates = switch (type) {
      'consultation' => [record['diagnosis'], record['symptoms']],
      'treatment' => [record['treatment'], record['diagnosis']],
      'vaccination' => [record['vaccineName']],
      'prescription' => [record['medicine']],
      _ => <dynamic>[],
    };
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return 'No summary available';
  }

  String _recordTypeLabel(String type) {
    switch (type) {
      case 'consultation':
        return 'Consultation';
      case 'treatment':
        return 'Treatment';
      case 'vaccination':
        return 'Vaccination';
      case 'prescription':
        return 'Prescription';
      default:
        return 'Medical record';
    }
  }

  void _openConsultationForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultationFormScreen(petId: widget.petId),
      ),
    ).then((_) {
      if (mounted) setState(_loadHistory);
    });
  }

  void _openTreatmentForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TreatmentFormScreen(petId: widget.petId),
      ),
    ).then((_) {
      if (mounted) setState(_loadHistory);
    });
  }

  @override
  Widget build(BuildContext context) {
    const filters = <String, String>{
      'all': 'All',
      'consultation': 'Consultations',
      'treatment': 'Treatments',
      'vaccination': 'Vaccinations',
      'prescription': 'Prescriptions',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Medical History')),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: filters.entries.map((filter) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(filter.value),
                    selected: _selectedType == filter.key,
                    onSelected: (_) =>
                        setState(() => _selectedType = filter.key),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: FilledButton.icon(
                      onPressed: () => setState(_loadHistory),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry loading history'),
                    ),
                  );
                }

                final records = snapshot.data ?? [];
                if (records.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.medical_information_outlined, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No medical history yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openConsultationForm,
                            icon: const Icon(Icons.add),
                            label: const Text('Add consultation'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final visibleRecords = _selectedType == 'all'
                    ? records
                    : records
                        .where((record) => record['type'] == _selectedType)
                        .toList();

                if (visibleRecords.isEmpty) {
                  return Center(
                    child: Text('No ${filters[_selectedType]!.toLowerCase()} yet'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: visibleRecords.length,
                  itemBuilder: (context, index) {
                    final record = visibleRecords[index];
                    final type = record['type'] as String? ?? '';
                    final date = DateFormat.yMMMd().format(
                      _recordDate(record['createdAt']),
                    );
                    final vetId = record['vetId'] as String? ?? 'Unknown';
                    final branchId =
                        record['branchId'] as String? ?? 'Unassigned';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _recordTypeLabel(type),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(date, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_recordSummary(record)),
                              const SizedBox(height: 8),
                              Text('Vet ID: $vetId  |  Branch ID: $branchId'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add-consultation',
            onPressed: _openConsultationForm,
            icon: const Icon(Icons.add),
            label: const Text('Consultation'),
          ),
          const SizedBox(width: 10),
          FloatingActionButton.extended(
            heroTag: 'add-treatment',
            onPressed: _openTreatmentForm,
            icon: const Icon(Icons.add),
            label: const Text('Treatment'),
          ),
        ],
      ),
    );
  }
}