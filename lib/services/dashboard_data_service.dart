import '../models/clinical_record_model.dart';
import '../models/dashboard_data.dart';
import 'firestore_service.dart';

class DashboardDataService {
  final FirestoreService firestoreService;

  const DashboardDataService({required this.firestoreService});

  Future<DashboardData> load({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final records = await firestoreService.getClinicalRecords();
    final todayConsultations = records.where((record) {
      return record.type == 'CONSULTATION' &&
          _isSameDay(record.date, currentTime);
    }).toList();

    final upcomingFollowUps = records.where((record) {
      final date = record.followUpDate;
      return date != null && !date.isBefore(currentTime);
    }).toList()
      ..sort((first, second) =>
          first.followUpDate!.compareTo(second.followUpDate!));

    final vaccinationLimit = currentTime.add(const Duration(days: 30));
    final vaccinationsDue = records.where((record) {
      final date = record.dueDate;
      return record.type == 'VACCINATION' &&
          date != null &&
          date.isBefore(vaccinationLimit);
    }).toList()
      ..sort((first, second) => first.dueDate!.compareTo(second.dueDate!));

    return DashboardData(
      todaysConsultations: todayConsultations,
      upcomingFollowUps: upcomingFollowUps,
      vaccinationsDue: vaccinationsDue,
    );
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}