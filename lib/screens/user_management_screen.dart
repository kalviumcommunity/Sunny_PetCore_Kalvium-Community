import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserManagementScreen extends StatefulWidget {
  final AuthService authService;
  final User firebaseUser;

  const UserManagementScreen({
    super.key,
    required this.authService,
    required this.firebaseUser,
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
      builder: (_) => _EditUserDialog(user: user),
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
              final isCurrentUser = user.id == widget.firebaseUser.uid;
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
                  trailing: isCurrentUser
                      ? IconButton(
                          tooltip: 'Edit profile',
                          onPressed: () => _editProfile(user),
                          icon: const Icon(Icons.edit_outlined),
                        )
                      : null,
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

  const _EditUserDialog({required this.user});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _branchController;
  late String _role;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _branchController = TextEditingController(text: widget.user.branchId);
    _role = widget.user.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _branchController.dispose();
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
        branchId: _branchController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit user profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _branchController,
              decoration: const InputDecoration(labelText: 'Branch ID'),
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