import 'clinical_record_model.dart';

class DashboardData {
  final List<ClinicalRecord> todaysConsultations;
  final List<ClinicalRecord> todaysFollowUps;
  final List<ClinicalRecord> upcomingFollowUps;
  final List<ClinicalRecord> vaccinationsDue;

  const DashboardData({
    required this.todaysConsultations,
    required this.todaysFollowUps,
    required this.upcomingFollowUps,
    required this.vaccinationsDue,
  });
}