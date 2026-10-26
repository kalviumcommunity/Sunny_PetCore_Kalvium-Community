import 'package:flutter/material.dart';
import '../models/owner_model.dart';
import '../services/firestore_service.dart';
import 'owner_profile_screen.dart';
import 'owner_registration_screen.dart';

// Owner Screen displaying all registered owners with search, filter, and management actions.
class OwnerScreen extends StatefulWidget {
  final FirestoreService firestoreService;

  const OwnerScreen({super.key, required this.firestoreService});

  @override
  State<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen> {
  List<OwnerModel> _allOwners = [];
  List<OwnerModel> _filteredOwners = [];
  bool _isLoading = true;
  bool _showInactive = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchOwners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOwners() async {
    setState(() => _isLoading = true);
    try {
      final owners = await widget.firestoreService.getOwners();
      setState(() {
        _allOwners = owners;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load owners: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    _filteredOwners = _allOwners.where((owner) {
      // Filter by active/inactive status
      if (!_showInactive && !owner.isActive) return false;

      // Filter by search query
      if (query.isNotEmpty) {
        return owner.name.toLowerCase().contains(query) ||
            owner.email.toLowerCase().contains(query) ||
            owner.phone.contains(query) ||
            owner.address.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    // Sort: active owners first, then alphabetically by name
    _filteredOwners.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  void _onSearchChanged(String _) {
    setState(() => _applyFilters());
  }

  void _navigateToRegistration({OwnerModel? ownerToEdit}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerRegistrationScreen(
          firestoreService: widget.firestoreService,
          existingOwner: ownerToEdit,
        ),
      ),
    );
    if (result == true) _fetchOwners();
  }

  void _navigateToProfile(OwnerModel owner) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerProfileScreen(
          owner: owner,
          firestoreService: widget.firestoreService,
        ),
      ),
    );
    // Refresh list in case owner was edited or deleted from profile screen
    _fetchOwners();
  }

  Future<void> _toggleOwnerStatus(OwnerModel owner) async {
    try {
      if (owner.isActive) {
        await widget.firestoreService.disableOwner(owner.id!);
      } else {
        await widget.firestoreService.enableOwner(owner.id!);
      }
      _fetchOwners();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              owner.isActive
                  ? '${owner.name} has been disabled'
                  : '${owner.name} has been re-enabled',
            ),
            backgroundColor: owner.isActive ? Colors.orange : Colors.green,
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

  Future<void> _deleteOwner(OwnerModel owner) async {
    // Check if the owner has pets before deleting
    final pets = await widget.firestoreService.getPetsByOwner(owner.id!);
    if (!mounted) return;

    if (pets.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: Text(
            '${owner.name} has ${pets.length} pet(s) registered. '
            'Please reassign or remove the pets first, or disable the owner instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _toggleOwnerStatus(owner);
              },
              child: const Text('Disable Instead'),
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
          'Are you sure you want to permanently delete ${owner.name}? '
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
        await widget.firestoreService.deleteOwner(owner.id!);
        _fetchOwners();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${owner.name} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
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
    final activeCount = _allOwners.where((o) => o.isActive).length;
    final inactiveCount = _allOwners.where((o) => !o.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owners'),
        actions: [
          if (inactiveCount > 0)
            IconButton(
              tooltip: _showInactive ? 'Hide inactive' : 'Show inactive',
              onPressed: () {
                setState(() {
                  _showInactive = !_showInactive;
                  _applyFilters();
                });
              },
              icon: Icon(
                _showInactive ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _fetchOwners,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.person, size: 18),
                  label: Text('$activeCount active'),
                ),
                const SizedBox(width: 8),
                if (inactiveCount > 0)
                  Chip(
                    avatar: const Icon(Icons.person_off, size: 18),
                    label: Text('$inactiveCount inactive'),
                    backgroundColor:
                        Colors.orange.shade100,
                  ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name, email, phone, or address...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
          ),

          // Owner list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOwners.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _searchController.text.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.person_add,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No owners match your search.'
                                  : 'No owners registered yet.',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            if (_searchController.text.isEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Tap + to register a new owner.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchOwners,
                        child: ListView.builder(
                          itemCount: _filteredOwners.length,
                          padding: const EdgeInsets.only(bottom: 80),
                          itemBuilder: (context, index) {
                            final owner = _filteredOwners[index];
                            return _OwnerListTile(
                              owner: owner,
                              onTap: () => _navigateToProfile(owner),
                              onEdit: () =>
                                  _navigateToRegistration(ownerToEdit: owner),
                              onToggleStatus: () =>
                                  _toggleOwnerStatus(owner),
                              onDelete: () => _deleteOwner(owner),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToRegistration(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Owner'),
      ),
    );
  }
}

// Individual owner list tile with actions
class _OwnerListTile extends StatelessWidget {
  final OwnerModel owner;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _OwnerListTile({
    required this.owner,
    required this.onTap,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: owner.isActive ? 1 : 0,
      color: owner.isActive ? null : Colors.grey.shade100,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: owner.isActive
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey.shade300,
                child: Text(
                  owner.name.isNotEmpty ? owner.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: owner.isActive
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Owner info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            owner.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: owner.isActive ? null : Colors.grey,
                              decoration: owner.isActive
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        if (!owner.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Disabled',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          owner.phone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.email, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            owner.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                    case 'toggle':
                      onToggleStatus();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: ListTile(
                      leading: Icon(
                        owner.isActive ? Icons.block : Icons.check_circle,
                      ),
                      title: Text(owner.isActive ? 'Disable' : 'Enable'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
