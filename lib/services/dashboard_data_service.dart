import '../models/dashboard_data.dart';
import 'firestore_service.dart';

class DashboardDataService {
  final FirestoreService firestoreService;

  const DashboardDataService({required this.firestoreService});

  Future<DashboardData> load({DateTime? now, String? branchId}) async {
    final currentTime = now ?? DateTime.now();
    final allRecords = await firestoreService.getClinicalRecords();
    final records = branchId == null
      ? allRecords
      : allRecords.where((record) => record.branchId == branchId).toList();

    final todayConsultations = records.where((record) {
      return record.type == 'CONSULTATION' && _isSameDay(record.date, currentTime);
    }).toList()
      ..sort((first, second) => first.date.compareTo(second.date));

    final todaysFollowUps = records.where((record) {
      final date = record.followUpDate;
      return date != null && _isSameDay(date, currentTime);
    }).toList()
      ..sort((first, second) => first.followUpDate!.compareTo(second.followUpDate!));

    final upcomingFollowUps = records.where((record) {
      final date = record.followUpDate;
      return date != null &&
          !date.isBefore(currentTime) &&
          !_isSameDay(date, currentTime);
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
      todaysFollowUps: todaysFollowUps,
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