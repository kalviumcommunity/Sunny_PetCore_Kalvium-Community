import 'package:flutter/material.dart';
import '../models/owner_model.dart';
import '../services/firestore_service.dart';

// Owner Registration / Edit form screen with validation, duplicate detection,
// and Firestore integration.
class OwnerRegistrationScreen extends StatefulWidget {
  final FirestoreService firestoreService;
  final OwnerModel? existingOwner; // null = create mode, non-null = edit mode

  const OwnerRegistrationScreen({
    super.key,
    required this.firestoreService,
    this.existingOwner,
  });

  @override
  State<OwnerRegistrationScreen> createState() =>
      _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState extends State<OwnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSaving = false;

  bool get _isEditMode => widget.existingOwner != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill form fields if editing an existing owner
    if (_isEditMode) {
      final owner = widget.existingOwner!;
      _nameController.text = owner.name;
      _phoneController.text = owner.phone;
      _emailController.text = owner.email;
      _addressController.text = owner.address;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveOwner() async {
    // 1. Validate Form
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final phone = _phoneController.text.trim();
      final excludeId = _isEditMode ? widget.existingOwner!.id : null;

      // 2. Check for duplicate email
      final emailDuplicate = await widget.firestoreService
          .isEmailDuplicate(email, excludeId: excludeId);
      if (emailDuplicate) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An owner with this email already exists.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 3. Check for duplicate phone
      final phoneDuplicate = await widget.firestoreService
          .isPhoneDuplicate(phone, excludeId: excludeId);
      if (phoneDuplicate) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An owner with this phone number already exists.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_isEditMode) {
        // 4a. Update existing owner
        final updatedOwner = widget.existingOwner!.copyWith(
          name: _nameController.text.trim(),
          phone: phone,
          email: email,
          address: _addressController.text.trim(),
        );
        await widget.firestoreService.updateOwner(updatedOwner);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Owner updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        // 4b. Create new owner
        final newOwner = OwnerModel(
          name: _nameController.text.trim(),
          phone: phone,
          email: email,
          address: _addressController.text.trim(),
        );

        await widget.firestoreService.addOwner(newOwner);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Owner registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save owner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Owner' : 'Register Owner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              if (_isEditMode) ...[
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Editing: ${widget.existingOwner!.name}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Name Field with Validation
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter name';
                  }
                  if (val.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  // Check for valid name characters
                  if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(val.trim())) {
                    return 'Name contains invalid characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 2. Phone Field with Validation
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  hintText: '10-digit phone number',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  final cleaned = val.trim().replaceAll(RegExp(r'[\s\-()]'), '');
                  if (cleaned.length < 10) {
                    return 'Enter a valid 10-digit phone number';
                  }
                  if (!RegExp(r'^[0-9+]+$').hasMatch(cleaned)) {
                    return 'Phone number contains invalid characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Email Field with Validation
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter email';
                  }
                  // RFC-style email validation
                  final emailRegex = RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                  );
                  if (!emailRegex.hasMatch(val.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 4. Address Field with Validation
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter address';
                  }
                  if (val.trim().length < 5) {
                    return 'Address is too short';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveOwner,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_isEditMode ? Icons.save : Icons.person_add),
                  label: Text(_isEditMode ? 'Save Changes' : 'Register Owner'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
