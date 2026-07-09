import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/student_service.dart';
import '../models/student_models.dart';

final profileProvider = FutureProvider<StudentProfile>((ref) async {
  return StudentService.getProfile();
});

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  return StudentService.getDashboardSummary();
});

final upcomingExamsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return StudentService.getUpcomingExams();
});

// Marks with filter state
class MarksFilter {
  final String? subjectId;
  final String? examType;
  final String? pack;
  const MarksFilter({this.subjectId, this.examType, this.pack});

  MarksFilter copyWith({String? subjectId, String? examType, String? pack}) =>
      MarksFilter(
        subjectId: subjectId ?? this.subjectId,
        examType: examType ?? this.examType,
        pack: pack ?? this.pack,
      );
}

final marksFilterProvider = StateProvider<MarksFilter>((_) => const MarksFilter());

final marksProvider = FutureProvider<List<MarkRecord>>((ref) async {
  final filter = ref.watch(marksFilterProvider);
  return StudentService.getMarks(
    subjectId: filter.subjectId,
    examType: filter.examType,
    pack: filter.pack,
  );
});

final attendanceProvider = FutureProvider<AttendanceSummary>((ref) async {
  return StudentService.getAttendance();
});

final leaderboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return StudentService.getLeaderboard();
});

final resourcesProvider = FutureProvider<List<ResourceItem>>((ref) async {
  return StudentService.getResources();
});
