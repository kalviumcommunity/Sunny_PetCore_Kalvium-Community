import 'package:flutter/material.dart';
import '../models/owner_model.dart';
import '../services/firestore_service.dart';
import 'owner_profile_screen.dart';

// Owner Registration form screen with validation and Firestore integration.
class OwnerRegistrationScreen extends StatefulWidget {
  final FirestoreService firestoreService;

  const OwnerRegistrationScreen({super.key, required this.firestoreService});

  @override
  State<OwnerRegistrationScreen> createState() => _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState extends State<OwnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _registerOwner() async {
    // 1. Validate Form
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newOwner = OwnerModel(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
      );

      // 2. Save Owner into Firestore
      final docId = await widget.firestoreService.addOwner(newOwner);
      final savedOwner = newOwner.copyWith(id: docId);

      if (!mounted) return;

      // 3. Show Success Message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Owner registered successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // 4. Navigate to Owner Profile Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OwnerProfileScreen(owner: savedOwner),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Show Error Message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to register owner: $e'),
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
        title: const Text('Register Owner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. Name Field with Validation
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // 2. Phone Field with Validation
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (val.trim().length < 10) {
                    return 'Enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // 3. Email Field with Validation
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter email';
                  }
                  if (!val.contains('@') || !val.contains('.')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // 4. Address Field with Validation
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _registerOwner,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Register Owner'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
