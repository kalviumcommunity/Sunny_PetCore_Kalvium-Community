class DocumentModel {
  final String? id;
  final String petId;
  final String fileName;
  final String fileUrl;
  final String uploadedBy;
  final String branchId;
  final DateTime uploadDate;
  final String documentType;

  DocumentModel({
    this.id,
    required this.petId,
    required this.fileName,
    required this.fileUrl,
    required this.uploadedBy,
    required this.branchId,
    required this.uploadDate,
    required this.documentType,
  });

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'uploadedBy': uploadedBy,
      'branchId': branchId,
      'uploadDate': uploadDate.toIso8601String(),
      'documentType': documentType,
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map, String id) {
    return DocumentModel(
      id: id,
      petId: map['petId'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      fileUrl: map['fileUrl'] as String? ?? '',
      uploadedBy: map['uploadedBy'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      uploadDate: DateTime.tryParse(map['uploadDate'] as String? ?? '') ??
          DateTime.now(),
      documentType: map['documentType'] as String? ?? '',
    );
  }
}