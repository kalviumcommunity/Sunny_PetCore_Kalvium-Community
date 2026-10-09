import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/branch_model.dart';
import '../models/user_model.dart';
import '../models/role_permissions.dart';
import '../services/auth_service.dart';
import '../services/branch_service.dart';

class UserManagementScreen extends StatefulWidget {
  final AuthService authService;
  final User firebaseUser;
  final UserModel currentUser;
  final BranchService branchService;

  const UserManagementScreen({
    super.key,
    required this.authService,
    required this.firebaseUser,
    required this.currentUser,
    required this.branchService,
  });

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _reloadUsers();
  }

  void _reloadUsers() {
    _usersFuture = widget.authService.getUserProfiles();
  }

  Future<void> _editProfile(UserModel user) async {
    final updated = await showDialog<UserModel>(
      context: context,
      builder: (_) => _EditUserDialog(
        user: user,
        branchService: widget.branchService,
      ),
    );
    if (updated == null) return;

    try {
      await widget.authService.updateUserProfile(updated);
      if (!mounted) return;
      setState(_reloadUsers);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User profile updated.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the user profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!RolePermissions.canManageUsers(
      UserRole.fromValue(widget.currentUser.role),
    )) {
      return const Center(
        child: Text('You do not have permission to manage users.'),
      );
    }

    return FutureBuilder<List<UserModel>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: FilledButton.icon(
              onPressed: () => setState(_reloadUsers),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry loading users'),
            ),
          );
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text('No user profiles found.'));
        }

        return RefreshIndicator(
          onRefresh: () async => setState(_reloadUsers),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(_initials(user.name, user.email)),
                  ),
                  title: Text(
                    user.name.isEmpty ? user.email : user.name,
                  ),
                  subtitle: Text(
                    '${user.email}\nRole: ${user.role} | Branch: ${user.branchId.isEmpty ? 'Unassigned' : user.branchId}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: user.id == widget.firebaseUser.uid
                        ? 'Edit your profile'
                        : 'Edit user',
                    onPressed: () => _editProfile(user),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _initials(String name, String email) {
    final source = name.trim().isEmpty ? email : name;
    final trimmed = source.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }
}

class _EditUserDialog extends StatefulWidget {
  final UserModel user;
  final BranchService branchService;

  const _EditUserDialog({required this.user, required this.branchService});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late final TextEditingController _nameController;
  late Future<List<BranchModel>> _branchesFuture;
  late String _role;
  String? _branchId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _role = widget.user.role;
    _branchId = widget.user.branchId.isEmpty ? null : widget.user.branchId;
    _branchesFuture = widget.branchService.getBranches();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    Navigator.pop(
      context,
      widget.user.copyWith(
        name: name,
        role: _role,
        branchId: _branchId ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit user profile'),
      content: FutureBuilder<List<BranchModel>>(
        future: _branchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const Text('Branches could not be loaded.');
          }

          final branches = snapshot.data ?? [];
          final branchExists = _branchId == null ||
              branches.any((branch) => branch.id == _branchId);
          if (!branchExists) _branchId = null;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _branchId,
              decoration: const InputDecoration(labelText: 'Branch'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Unassigned'),
                ),
                ...branches
                    .where((branch) => branch.isActive)
                    .map((branch) => DropdownMenuItem<String?>(
                          value: branch.id,
                          child: Text(branch.name),
                        )),
              ],
              onChanged: (value) => setState(() => _branchId = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                DropdownMenuItem(
                  value: 'VETERINARIAN',
                  child: Text('VETERINARIAN'),
                ),
                DropdownMenuItem(
                  value: 'CLINIC STAFF',
                  child: Text('CLINIC STAFF'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _role = value);
              },
            ),
              ],
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