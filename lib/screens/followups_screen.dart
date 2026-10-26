import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/followup_model.dart';
import '../models/pet_model.dart';
import '../services/firestore_service.dart';
import '../services/medical_firestore_service.dart';

class FollowUpsScreen extends StatefulWidget {
  final String? petId;

  const FollowUpsScreen({super.key, this.petId});

  @override
  State<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends State<FollowUpsScreen> {
  final _medicalService = MedicalFirestoreService();
  final _firestoreService = FirestoreService();
  late Future<_FollowUpsData> _dataFuture;
  String? _completingFollowUpId;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_FollowUpsData> _loadData() async {
    try {
      final followUps = widget.petId == null
          ? await _medicalService.getUpcomingFollowUps()
          : await _medicalService.getUpcomingFollowUpsForPet(widget.petId!);
      final pets = await _firestoreService.getPets();
      return _FollowUpsData(followUps, pets);
    } catch (error) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not load follow-ups: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
      rethrow;
    }
  }

  Future<void> _markCompleted(String followUpId) async {
    if (_completingFollowUpId != null) return;
    setState(() => _completingFollowUpId = followUpId);
    try {
      await _medicalService.markFollowUpCompleted(followUpId);
      if (!mounted) return;
      setState(() => _dataFuture = _loadData());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Follow-up marked as completed.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update follow-up: $error')),
      );
    } finally {
      if (mounted) setState(() => _completingFollowUpId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Follow-ups')),
      body: FutureBuilder<_FollowUpsData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Could not load follow-ups: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () =>
                          setState(() => _dataFuture = _loadData()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry loading follow-ups'),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = snapshot.data!;
          if (data.followUps.isEmpty) {
            return const Center(child: Text('No pending follow-ups.'));
          }

          final petsById = <String, PetModel>{
            for (final pet in data.pets)
              if (pet.id != null) pet.id!: pet,
            for (final pet in data.pets) pet.petId: pet,
          };
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.followUps.length,
            itemBuilder: (context, index) {
              final followUp = data.followUps[index];
              final pet = petsById[followUp.petId];
              final petLabel = pet == null
                  ? followUp.petId
                  : '${pet.name} (${pet.petId})';
              final followUpId = followUp.id;
              final details = [
                DateFormat.yMMMd().format(followUp.followUpDate),
                followUp.relatedRecordType,
                if (followUp.notes.trim().isNotEmpty) followUp.notes.trim(),
              ].join('\n');

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(petLabel),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(details),
                  ),
                  isThreeLine: followUp.notes.trim().isNotEmpty,
                  trailing: IconButton(
                    tooltip: 'Mark completed',
                    onPressed: followUpId == null ||
                            _completingFollowUpId != null
                        ? null
                        : () => _markCompleted(followUpId),
                    icon: _completingFollowUpId == followUpId
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FollowUpsData {
  final List<FollowUpModel> followUps;
  final List<PetModel> pets;

  const _FollowUpsData(this.followUps, this.pets);
}