import 'package:flutter/material.dart';

import '../models/branch_model.dart';
import '../models/role_permissions.dart';
import '../models/user_model.dart';
import '../services/branch_service.dart';

class BranchManagementScreen extends StatefulWidget {
  final BranchService branchService;
  final UserModel currentUser;

  const BranchManagementScreen({
    super.key,
    required this.branchService,
    required this.currentUser,
  });

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  late Future<List<BranchModel>> _branchesFuture;

  @override
  void initState() {
    super.initState();
    _reloadBranches();
  }

  void _reloadBranches() {
    _branchesFuture = widget.branchService.getBranches();
  }

  Future<void> _openBranchEditor([BranchModel? branch]) async {
    final edited = await showDialog<BranchModel>(
      context: context,
      builder: (_) => _BranchDialog(branch: branch),
    );
    if (edited == null) return;

    try {
      if (branch == null) {
        await widget.branchService.addBranch(edited);
      } else {
        await widget.branchService.updateBranch(edited);
      }
      if (!mounted) return;
      setState(_reloadBranches);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(branch == null ? 'Branch added.' : 'Branch updated.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the branch.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!RolePermissions.canManageUsers(
      UserRole.fromValue(widget.currentUser.role),
    )) {
      return const Center(
        child: Text('You do not have permission to manage branches.'),
      );
    }

    return FutureBuilder<List<BranchModel>>(
      future: _branchesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: FilledButton.icon(
              onPressed: () => setState(_reloadBranches),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry loading branches'),
            ),
          );
        }

        final branches = snapshot.data ?? [];
        return Stack(
          children: [
            if (branches.isEmpty)
              const Center(child: Text('No branches configured.'))
            else
              RefreshIndicator(
                onRefresh: () async => setState(_reloadBranches),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: branches.length,
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          branch.isActive ? Icons.store : Icons.store_outlined,
                        ),
                        title: Text(branch.name),
                        subtitle: Text(
                          '${branch.address}\n${branch.phone}\nID: ${branch.id}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          tooltip: 'Edit branch',
                          onPressed: () => _openBranchEditor(branch),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: _openBranchEditor,
                icon: const Icon(Icons.add),
                label: const Text('Add branch'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BranchDialog extends StatefulWidget {
  final BranchModel? branch;

  const _BranchDialog({this.branch});

  @override
  State<_BranchDialog> createState() => _BranchDialogState();
}

class _BranchDialogState extends State<_BranchDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final branch = widget.branch;
    _nameController = TextEditingController(text: branch?.name ?? '');
    _addressController = TextEditingController(text: branch?.address ?? '');
    _phoneController = TextEditingController(text: branch?.phone ?? '');
    _isActive = branch?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    Navigator.pop(
      context,
      BranchModel(
        id: widget.branch?.id ?? '',
        name: name,
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.branch == null ? 'Add branch' : 'Edit branch'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Branch name'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active branch'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
          ],
        ),
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