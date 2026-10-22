import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/consultation_model.dart';
import '../models/pet_model.dart';
import '../models/prescription_model.dart';
import '../models/treatment_model.dart';
import '../models/vaccination_model.dart';
import '../services/medical_firestore_service.dart';
import '../widgets/pet_profile_section_card.dart';
import 'consultation_form_screen.dart';
import 'documents_screen.dart';
import 'prescription_form_screen.dart';
import 'treatment_form_screen.dart';
import 'vaccination_form_screen.dart';

class PetProfileScreen extends StatefulWidget {
  final PetModel pet;
  final MedicalFirestoreService? medicalService;

  const PetProfileScreen({
    super.key,
    required this.pet,
    this.medicalService,
  });

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  late final MedicalFirestoreService _medicalService;
  late Future<_PetProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _medicalService = widget.medicalService ?? MedicalFirestoreService();
    _profileFuture = _loadProfileData();
  }

  Future<_PetProfileData> _loadProfileData() async {
    final results = await Future.wait([
      _medicalService.getConsultationsForPet(widget.pet.petId),
      _medicalService.getTreatmentsForPet(widget.pet.petId),
      _medicalService.getVaccinationsForPet(widget.pet.petId),
      _medicalService.getPrescriptionsForPet(widget.pet.petId),
    ]);

    final consultations = results[0] as List<ConsultationModel>;
    final treatments = results[1] as List<TreatmentModel>;
    final vaccinations = results[2] as List<VaccinationModel>;
    final prescriptions = results[3] as List<PrescriptionModel>;

    consultations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    treatments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    vaccinations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    prescriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _PetProfileData(
      consultations: consultations,
      treatments: treatments,
      vaccinations: vaccinations,
      prescriptions: prescriptions,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _profileFuture = _loadProfileData();
    });
    await _profileFuture;
  }

  Future<void> _openForm(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (mounted) _refresh();
  }

  String _date(DateTime value) => DateFormat.yMMMd().format(value);

  Widget _meta(String vetId, String branchId, DateTime createdAt) {
    return Text(
      'Vet: $vetId • Branch: ${branchId.isEmpty ? 'Unassigned' : branchId} • ${_date(createdAt)}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;

    return Scaffold(
      appBar: AppBar(title: Text('${pet.name} (${pet.petId})')),
      body: FutureBuilder<_PetProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry loading profile'),
              ),
            );
          }

          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.pets),
                    title: Text('${pet.species} • ${pet.breed}'),
                    subtitle: Text(
                      'Gender: ${pet.gender}\nDOB/Age: ${pet.dobAge}\nWeight: ${pet.weight} kg\nColor: ${pet.color}\nOwner ID: ${pet.ownerId}',
                    ),
                    isThreeLine: true,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openForm(
                        ConsultationFormScreen(petId: pet.petId),
                      ),
                      icon: const Icon(Icons.medical_services_outlined),
                      label: const Text('Consultation'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openForm(
                        TreatmentFormScreen(petId: pet.petId),
                      ),
                      icon: const Icon(Icons.medication_outlined),
                      label: const Text('Treatment'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openForm(
                        VaccinationFormScreen(petId: pet.petId),
                      ),
                      icon: const Icon(Icons.vaccines_outlined),
                      label: const Text('Vaccination'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openForm(
                        PrescriptionFormScreen(petId: pet.petId),
                      ),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Prescription'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DocumentsScreen(petId: pet.petId),
                        ),
                      ),
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('Documents'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PetProfileSectionCard(
                  title: 'Consultations',
                  icon: Icons.medical_services_outlined,
                  count: data.consultations.length,
                  emptyMessage: 'No consultations yet.',
                  items: data.consultations
                      .map(
                        (record) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(record.diagnosis),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(record.symptoms),
                              _meta(record.vetId, record.branchId, record.createdAt),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                PetProfileSectionCard(
                  title: 'Treatments',
                  icon: Icons.healing_outlined,
                  count: data.treatments.length,
                  emptyMessage: 'No treatments yet.',
                  items: data.treatments
                      .map(
                        (record) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(record.treatment),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${record.medicine} • ${record.dosage}'),
                              _meta(record.vetId, record.branchId, record.createdAt),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                PetProfileSectionCard(
                  title: 'Vaccinations',
                  icon: Icons.vaccines_outlined,
                  count: data.vaccinations.length,
                  emptyMessage: 'No vaccinations yet.',
                  items: data.vaccinations
                      .map(
                        (record) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(record.vaccineName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dose: ${record.dosage} • Next due: ${_date(record.nextDueDate)}'),
                              _meta(record.vetId, record.branchId, record.createdAt),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                PetProfileSectionCard(
                  title: 'Prescription History',
                  icon: Icons.receipt_long_outlined,
                  count: data.prescriptions.length,
                  emptyMessage: 'No prescription history available.',
                  items: data.prescriptions
                      .map(
                        (record) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('Medicine: ${record.medicine}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dosage: ${record.dosage}'),
                              Text('Frequency: ${record.frequency}'),
                              Text('Duration: ${record.duration}'),
                              Text('Instructions: ${record.instructions}'),
                              Text('Date: ${_date(record.createdAt)}'),
                              Text('Veterinarian: ${record.vetId}'),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PetProfileData {
  final List<ConsultationModel> consultations;
  final List<TreatmentModel> treatments;
  final List<VaccinationModel> vaccinations;
  final List<PrescriptionModel> prescriptions;

  const _PetProfileData({
    required this.consultations,
    required this.treatments,
    required this.vaccinations,
    required this.prescriptions,
  });
}
