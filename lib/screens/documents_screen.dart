import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/document_model.dart';
import '../services/medical_firestore_service.dart';

class DocumentsScreen extends StatefulWidget {
  final String petId;

  const DocumentsScreen({super.key, required this.petId});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  static const _maxUploadBytes = 10 * 1024 * 1024;
  static const _documentTypes = [
    'Blood Report',
    'X-Ray',
    'Lab Report',
    'Prescription',
  ];

  final _medicalService = MedicalFirestoreService();
  late Future<List<DocumentModel>> _documentsFuture;
  String _documentType = _documentTypes.first;
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _documentsFuture = _loadDocuments();
  }

  Future<List<DocumentModel>> _loadDocuments() async {
    try {
      return await _medicalService.getDocumentsForPet(widget.petId);
    } catch (error) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not load documents: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
      rethrow;
    }
  }

  Future<void> _pickAndUploadDocument() async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not select document: $error'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;
    final selectedFile = result.files.single;
    if (selectedFile.size > _maxUploadBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File is too large. Choose a file up to 10 MB.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final path = selectedFile.path;
    if (path == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The selected file could not be read.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });
    try {
      await _medicalService.uploadDocument(
        File(path),
        widget.petId,
        _documentType,
        onProgress: (progress) {
          if (mounted) setState(() => _uploadProgress = progress);
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document uploaded successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _documentsFuture = _loadDocuments());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not upload document: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medical Documents')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: DropdownButtonFormField<String>(
              value: _documentType,
              decoration: const InputDecoration(
                labelText: 'Document Type',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _documentTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: _isUploading
                  ? null
                  : (value) {
                      if (value != null) setState(() => _documentType = value);
                    },
            ),
          ),
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: _uploadProgress),
                  const SizedBox(height: 6),
                  Text('Uploading ${(_uploadProgress * 100).round()}%'),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<DocumentModel>>(
              future: _documentsFuture,
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
                          Text('Could not load documents: ${snapshot.error}'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => setState(
                              () => _documentsFuture = _loadDocuments(),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry loading documents'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final documents = snapshot.data ?? [];
                if (documents.isEmpty) {
                  return const Center(child: Text('No documents uploaded yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(document.fileName),
                        subtitle: Text(
                          '${document.documentType} · '
                          '${DateFormat.yMMMd().format(document.uploadDate)}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadDocument,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload document'),
      ),
    );
  }
}