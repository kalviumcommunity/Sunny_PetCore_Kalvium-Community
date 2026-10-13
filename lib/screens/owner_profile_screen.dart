import 'package:flutter/material.dart';
import '../models/owner_model.dart';
import '../models/pet_model.dart';
import '../services/firestore_service.dart';
import 'owner_registration_screen.dart';

// Owner Profile screen displaying the owner's complete details and their pets.
// Supports edit, delete, and disable actions.
// Navigation flow: Owners → Owner Profile → Pets
class OwnerProfileScreen extends StatefulWidget {
  final OwnerModel owner;
  final FirestoreService firestoreService;

  const OwnerProfileScreen({
    super.key,
    required this.owner,
    required this.firestoreService,
  });

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  late OwnerModel _owner;
  List<PetModel> _pets = [];
  bool _isLoadingPets = true;

  @override
  void initState() {
    super.initState();
    _owner = widget.owner;
    _fetchPets();
  }

  Future<void> _refreshOwner() async {
    if (_owner.id == null) return;
    final updated = await widget.firestoreService.getOwnerById(_owner.id!);
    if (updated != null && mounted) {
      setState(() => _owner = updated);
    }
  }

  Future<void> _fetchPets() async {
    if (_owner.id == null) {
      setState(() => _isLoadingPets = false);
      return;
    }
    setState(() => _isLoadingPets = true);
    try {
      final pets = await widget.firestoreService.getPetsByOwner(_owner.id!);
      setState(() {
        _pets = pets;
        _isLoadingPets = false;
      });
    } catch (e) {
      setState(() => _isLoadingPets = false);
    }
  }

  Future<void> _editOwner() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerRegistrationScreen(
          firestoreService: widget.firestoreService,
          existingOwner: _owner,
        ),
      ),
    );
    if (result == true) {
      await _refreshOwner();
    }
  }

  Future<void> _toggleStatus() async {
    try {
      if (_owner.isActive) {
        await widget.firestoreService.disableOwner(_owner.id!);
      } else {
        await widget.firestoreService.enableOwner(_owner.id!);
      }
      await _refreshOwner();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _owner.isActive
                  ? '${_owner.name} has been re-enabled'
                  : '${_owner.name} has been disabled',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteOwner() async {
    if (_pets.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: Text(
            '${_owner.name} has ${_pets.length} pet(s) registered. '
            'Please reassign or remove the pets first, or disable the owner instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Owner'),
        content: Text(
          'Are you sure you want to permanently delete ${_owner.name}? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.firestoreService.deleteOwner(_owner.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_owner.name} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: _editOwner,
            icon: const Icon(Icons.edit),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'toggle':
                  _toggleStatus();
                case 'delete':
                  _deleteOwner();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'toggle',
                child: ListTile(
                  leading: Icon(
                    _owner.isActive ? Icons.block : Icons.check_circle,
                  ),
                  title: Text(_owner.isActive ? 'Disable Owner' : 'Enable Owner'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title:
                      Text('Delete Owner', style: TextStyle(color: Colors.red)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Owner Info Card ──
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar and name
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: _owner.isActive
                          ? theme.colorScheme.primaryContainer
                          : Colors.grey.shade300,
                      child: Text(
                        _owner.name.isNotEmpty
                            ? _owner.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _owner.isActive
                              ? theme.colorScheme.onPrimaryContainer
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _owner.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Status badge
                    if (!_owner.isActive) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'DISABLED',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],

                    if (_owner.id != null && _owner.id!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${_owner.id}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const Divider(height: 32),

                    // Contact details
                    _DetailRow(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: _owner.phone,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: _owner.email,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.location_on,
                      label: 'Address',
                      value: _owner.address,
                    ),
                    if (_owner.createdAt != null) ...[
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.calendar_today,
                        label: 'Registered',
                        value:
                            '${_owner.createdAt!.day}/${_owner.createdAt!.month}/${_owner.createdAt!.year}',
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Pets Section ──
            Row(
              children: [
                Icon(Icons.pets, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Pets',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!_isLoadingPets)
                  Chip(
                    label: Text('${_pets.length}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoadingPets)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_pets.isEmpty)
              Card(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.pets, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No pets registered for this owner.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...List.generate(_pets.length, (index) {
                final pet = _pets[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Icon(
                        _getPetIcon(pet.species),
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: Text(
                      '${pet.name} (${pet.petId})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${pet.species} • ${pet.breed} • ${pet.gender}\n'
                      'Age: ${pet.dobAge} • Weight: ${pet.weight} kg • Color: ${pet.color}',
                    ),
                    isThreeLine: true,
                  ),
                );
              }),
          ],
        ),
      ),
    );
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
}

// Reusable detail row widget for showing icon + label + value
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
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
            Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ],
    );
  }
}
