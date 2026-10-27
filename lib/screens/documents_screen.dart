import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/document_model.dart';
import '../services/medical_firestore_service.dart';
import '../widgets/petcore_ui.dart';

class DocumentsScreen extends StatefulWidget {
  final String petId;
  final String branchId;

  const DocumentsScreen({
    super.key,
    required this.petId,
    required this.branchId,
  });

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
    _documentsFuture = _medicalService.getDocumentsForPet(
      widget.petId,
      branchId: widget.branchId,
    );
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'doc',
          'docx',
        ],
      );
      if (result == null || result.files.isEmpty) return;

      final selectedFile = result.files.single;
      final bytes = selectedFile.bytes;
      if (bytes == null) {
        throw StateError('The selected file could not be read.');
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });
      await _medicalService.uploadDocument(
        bytes,
        selectedFile.name,
        widget.petId,
        _documentType,
        onProgress: (progress) {
          if (mounted) setState(() => _uploadProgress = progress);
        },
      );
      if (!mounted) return;
      setState(() {
        _documentsFuture = _medicalService.getDocumentsForPet(
          widget.petId,
          branchId: widget.branchId,
        );
      });
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
                    return const PetCoreLoadingState(message: 'Loading documents...');
                }
                if (snapshot.hasError) {
                  return Center(
                    child: FilledButton.icon(
                      onPressed: () => setState(() {
                        _documentsFuture = _medicalService.getDocumentsForPet(
                          widget.petId,
                          branchId: widget.branchId,
                        );
                      }),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry loading documents'),
                    ),
                  );
                }
                final documents = snapshot.data ?? [];
                if (documents.isEmpty) {
                  return const PetCoreEmptyState(
                    title: 'No documents uploaded yet.',
                    subtitle: 'Upload reports, prescriptions, or certificates for this pet.',
                    icon: Icons.folder_open_outlined,
                  );
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
          onPressed: _isUploading || widget.branchId.trim().isEmpty
            ? null
            : _pickAndUploadDocument,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload document'),
      ),
    );
  }
}