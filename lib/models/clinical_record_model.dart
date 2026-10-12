class ClinicalRecord {
  final String? id;
  final String type;
  final String petId;
  final String petName;
  final DateTime date;
  final String title;
  final String notes;
  final DateTime? followUpDate;
  final DateTime? dueDate;
  final String veterinarian;
  final String branchId;

  const ClinicalRecord({
    this.id,
    required this.type,
    required this.petId,
    required this.petName,
    required this.date,
    required this.title,
    required this.notes,
    this.followUpDate,
    this.dueDate,
    required this.veterinarian,
    required this.branchId,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'petId': petId,
      'petName': petName,
      'date': date.toIso8601String(),
      'title': title,
      'notes': notes,
      'followUpDate': followUpDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'veterinarian': veterinarian,
      'branchId': branchId,
    };
  }

  factory ClinicalRecord.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(Object? value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return ClinicalRecord(
      id: id,
      type: map['type'] as String? ?? 'CONSULTATION',
      petId: map['petId'] as String? ?? '',
      petName: map['petName'] as String? ?? '',
      date: parseDate(map['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      title: map['title'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      followUpDate: parseDate(map['followUpDate']),
      dueDate: parseDate(map['dueDate']),
      veterinarian: map['veterinarian'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
    );
  }
}