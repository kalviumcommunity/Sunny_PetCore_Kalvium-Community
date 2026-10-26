import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/consultation_model.dart';
import '../models/document_model.dart';
import '../models/followup_model.dart';
import '../models/owner_model.dart';
import '../models/pet_model.dart';
import '../models/prescription_model.dart';
import '../models/treatment_model.dart';
import '../models/vaccination_model.dart';
import '../services/firestore_service.dart';
import '../services/medical_firestore_service.dart';
import '../widgets/pet_profile_section_card.dart';
import 'pet_registration_screen.dart';

// Pet Profile screen displaying complete pet details, owner info,
// and medical records summary (vaccinations, treatments, prescriptions,
// consultations, follow-ups, documents).
class PetProfileScreen extends StatefulWidget {
  final PetModel pet;
  final FirestoreService? firestoreService;
  final MedicalFirestoreService? medicalFirestoreService;
  final MedicalFirestoreService? medicalService;

  const PetProfileScreen({
    super.key,
    required this.pet,
    this.firestoreService,
    this.medicalFirestoreService,
    this.medicalService,
  });

  FirestoreService get effectiveFirestoreService =>
      firestoreService ?? FirestoreService();

  MedicalFirestoreService get effectiveMedicalService =>
      medicalFirestoreService ?? medicalService ?? MedicalFirestoreService();

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  late PetModel _pet;
  OwnerModel? _owner;
  bool _isLoading = true;

  // Medical record counts
  int _consultationCount = 0;
  int _treatmentCount = 0;
  int _vaccinationCount = 0;
  int _prescriptionCount = 0;
  int _followUpCount = 0;
  int _documentCount = 0;

  // Recent records for quick view
  List<VaccinationModel> _recentVaccinations = [];
  List<TreatmentModel> _recentTreatments = [];
  List<PrescriptionModel> _recentPrescriptions = [];
  List<ConsultationModel> _recentConsultations = [];
  List<FollowUpModel> _pendingFollowUps = [];
  List<DocumentModel> _documents = [];

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final petId = _pet.petId;
      final ownerFuture = widget.firestoreService == null
          ? Future<OwnerModel?>.value(null)
          : widget.firestoreService!.getOwnerById(_pet.ownerId);

      // Load owner and all medical records in parallel
      final results = await Future.wait([
        ownerFuture,
        widget.effectiveMedicalService.getConsultationsForPet(petId),
        widget.effectiveMedicalService.getTreatmentsForPet(petId),
        widget.effectiveMedicalService.getVaccinationsForPet(petId),
        widget.effectiveMedicalService.getPrescriptionsForPet(petId),
        widget.effectiveMedicalService.getUpcomingFollowUpsForPet(petId),
        widget.effectiveMedicalService.getDocumentsForPet(petId),
      ]);

      if (!mounted) return;

      final consultations = results[1] as List<ConsultationModel>;
      final treatments = results[2] as List<TreatmentModel>;
      final vaccinations = results[3] as List<VaccinationModel>;
      final prescriptions = results[4] as List<PrescriptionModel>;
      final followUps = results[5] as List<FollowUpModel>;
      final documents = results[6] as List<DocumentModel>;

      // Sort by date (newest first)
      consultations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      treatments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      vaccinations.sort((a, b) => b.dateGiven.compareTo(a.dateGiven));
      prescriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _owner = results[0] as OwnerModel?;
        _consultationCount = consultations.length;
        _treatmentCount = treatments.length;
        _vaccinationCount = vaccinations.length;
        _prescriptionCount = prescriptions.length;
        _followUpCount = followUps.length;
        _documentCount = documents.length;

        // Keep only 3 most recent for quick view
        _recentConsultations = consultations.take(3).toList();
        _recentTreatments = treatments.take(3).toList();
        _recentVaccinations = vaccinations.take(3).toList();
        _recentPrescriptions = prescriptions.take(3).toList();
        _pendingFollowUps = followUps.take(3).toList();
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editPet() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PetRegistrationScreen(
          firestoreService: widget.effectiveFirestoreService,
          existingPet: _pet,
        ),
      ),
    );
    if (result == true) {
      // Refresh pet data after edit
      final pets = await widget.effectiveFirestoreService.getPets();
      final updated = pets.firstWhere(
        (p) => p.id == _pet.id,
        orElse: () => _pet,
      );
      setState(() => _pet = updated);
      _loadAllData();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getPetIcon(String species) {
    switch (species.toLowerCase()) {
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.pets;
      case 'bird':
        return Icons.flutter_dash;
      case 'fish':
        return Icons.water;
      default:
        return Icons.pets;
    }
  }

  Future<void> _openDocument(DocumentModel document) async {
    final url = document.fileUrl.trim();
    if (url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document URL is available.')),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this document.')),
      );
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this document.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_pet.name),
        actions: [
          IconButton(
            tooltip: 'Edit Pet',
            onPressed: _editPet,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Pet Info Card ──
                    _buildPetInfoCard(theme),
                    const SizedBox(height: 16),

                    // ── Owner Info Card ──
                    _buildOwnerInfoCard(theme),
                    const SizedBox(height: 24),

                    // ── Medical Summary ──
                    _buildMedicalSummary(theme),
                    const SizedBox(height: 24),

                    // ── Prescription History Card ──
                    PetProfileSectionCard(
                      key: const ValueKey('pet-profile-prescription-history-card'),
                      title: 'Prescription History',
                      icon: Icons.receipt_long,
                      count: _prescriptionCount,
                      emptyMessage: 'No prescription history available.',
                      items: _recentPrescriptions.isEmpty
                          ? const []
                          : _recentPrescriptions.map((prescription) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Medicine: ${prescription.medicine}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Dosage: ${prescription.dosage}'),
                                    Text(
                                      'Frequency: ${prescription.frequency}',
                                    ),
                                    Text('Duration: ${prescription.duration}'),
                                    Text(
                                      'Instructions: ${prescription.instructions}',
                                    ),
                                    Text(
                                      'Date: ${DateFormat.yMMMd().format(prescription.createdAt)}',
                                    ),
                                    Text(
                                      'Veterinarian: ${prescription.vetId}',
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── Follow-up Plan Card ──
                    PetProfileSectionCard(
                      key: const ValueKey('pet-profile-followup-card'),
                      title: 'Follow-up plan',
                      icon: Icons.event,
                      count: _followUpCount,
                      emptyMessage: 'No follow-up plan scheduled.',
                      items: _pendingFollowUps.isEmpty
                          ? const []
                          : _pendingFollowUps.map((followUp) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.event_available),
                                  title: Text(
                                    'Follow-up ${followUp.relatedRecordType}',
                                  ),
                                  subtitle: Text(
                                    '${followUp.notes.isNotEmpty ? '${followUp.notes}\n' : ''}'
                                    'Date: ${_formatDate(followUp.followUpDate)}\n'
                                    'Status: ${followUp.status}',
                                  ),
                                ),
                              );
                            }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── Recent Vaccinations ──
                    if (_recentVaccinations.isNotEmpty) ...[
                      _buildSectionHeader(
                          theme, 'Vaccinations', Icons.vaccines,
                          count: _vaccinationCount),
                      ..._recentVaccinations.map((v) => _buildRecordTile(
                            title: v.vaccineName,
                            subtitle:
                                'Dosage: ${v.dosage} • Next due: ${_formatDate(v.nextDueDate)}',
                            date: _formatDate(v.dateGiven),
                            icon: Icons.vaccines,
                            color: Colors.green,
                          )),
                      const SizedBox(height: 16),
                    ],

                    // ── Recent Consultations ──
                    if (_recentConsultations.isNotEmpty) ...[
                      _buildSectionHeader(
                          theme, 'Consultations', Icons.medical_services,
                          count: _consultationCount),
                      ..._recentConsultations.map((c) => _buildRecordTile(
                            title: c.diagnosis,
                            subtitle:
                                'Symptoms: ${c.symptoms}\nTreatment: ${c.treatmentGiven}',
                            date: _formatDate(c.createdAt),
                            icon: Icons.medical_services,
                            color: Colors.blue,
                          )),
                      const SizedBox(height: 16),
                    ],

                    // ── Recent Treatments ──
                    if (_recentTreatments.isNotEmpty) ...[
                      _buildSectionHeader(
                          theme, 'Treatments', Icons.healing,
                          count: _treatmentCount),
                      ..._recentTreatments.map((t) => _buildRecordTile(
                            title: t.treatment,
                            subtitle:
                                'Diagnosis: ${t.diagnosis}\nMedicine: ${t.medicine} (${t.dosage})',
                            date: _formatDate(t.createdAt),
                            icon: Icons.healing,
                            color: Colors.orange,
                          )),
                      const SizedBox(height: 16),
                    ],

                    // ── Medical Documents Card ──
                    PetProfileSectionCard(
                      key: const ValueKey('pet-profile-documents-card'),
                      title: 'Medical Documents',
                      icon: Icons.folder,
                      count: _documentCount,
                      emptyMessage: 'No medical documents available.',
                      items: _documents.isEmpty
                          ? const []
                          : _documents.map((document) {
                              final label = document.documentType.isEmpty
                                  ? 'Document'
                                  : document.documentType;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.description_outlined),
                                  title: Text(document.fileName),
                                  subtitle: Text(
                                    '$label • ${DateFormat.yMMMd().format(document.uploadDate)}',
                                  ),
                                  trailing: IconButton(
                                    tooltip: 'View document',
                                    onPressed: () => _openDocument(document),
                                    icon: const Icon(Icons.open_in_new),
                                  ),
                                ),
                              );
                            }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── Empty state if no records ──
                    if (_consultationCount == 0 &&
                        _treatmentCount == 0 &&
                        _vaccinationCount == 0 &&
                        _prescriptionCount == 0 &&
                        _followUpCount == 0 &&
                        _documentCount == 0)
                      Card(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        child: const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.medical_information,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'No medical records yet.',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Pet Info Card ──
  Widget _buildPetInfoCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile image placeholder with species icon
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                _getPetIcon(_pet.species),
                size: 40,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _pet.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _pet.petId,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
            const Divider(height: 32),

            // Pet details in rows
            _InfoRow(icon: Icons.category, label: 'Species', value: _pet.species),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.pets_outlined, label: 'Breed', value: _pet.breed),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.wc, label: 'Gender', value: _pet.gender),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.cake, label: 'DOB / Age', value: _pet.dobAge),
            const SizedBox(height: 10),
            _InfoRow(
                icon: Icons.monitor_weight,
                label: 'Weight',
                value: '${_pet.weight} kg'),
            const SizedBox(height: 10),
            _InfoRow(
                icon: Icons.color_lens, label: 'Color', value: _pet.color),
          ],
        ),
      ),
    );
  }

  // ── Owner Info Card ──
  Widget _buildOwnerInfoCard(ThemeData theme) {
    if (_owner == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.person_off, color: Colors.grey.shade400),
              const SizedBox(width: 12),
              const Text('Owner information not available',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Owner',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _InfoRow(icon: Icons.person, label: 'Name', value: _owner!.name),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.phone, label: 'Phone', value: _owner!.phone),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.email, label: 'Email', value: _owner!.email),
          ],
        ),
      ),
    );
  }

  // ── Medical Summary Grid ──
  Widget _buildMedicalSummary(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medical Summary',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.2,
          children: [
            _SummaryTile(
                icon: Icons.vaccines,
                label: 'Vaccinations',
                count: _vaccinationCount,
                color: Colors.green),
            _SummaryTile(
                icon: Icons.medical_services,
                label: 'Consultations',
                count: _consultationCount,
                color: Colors.blue),
            _SummaryTile(
                icon: Icons.healing,
                label: 'Treatments',
                count: _treatmentCount,
                color: Colors.orange),
            _SummaryTile(
                icon: Icons.receipt_long,
                label: 'Prescriptions',
                count: _prescriptionCount,
                color: Colors.purple),
            _SummaryTile(
                icon: Icons.folder,
                label: 'Documents',
                count: _documentCount,
                color: Colors.brown),
            _SummaryTile(
                icon: Icons.event,
                label: 'Follow-ups',
                count: _followUpCount,
                color: Colors.teal),
          ],
        ),
      ],
    );
  }

  // ── Section Header ──
  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon,
      {required int count}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text('$count'),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // ── Record Tile ──
  Widget _buildRecordTile({
    required String title,
    required String subtitle,
    required String date,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Text(
          date,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        isThreeLine: subtitle.contains('\n'),
      ),
    );
  }
}

// ── Reusable info row widget ──
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(value, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ],
    );
  }
}

// ── Summary tile for the medical grid ──
class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
