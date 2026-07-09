import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';

// Overview filter state
class OverviewFilter {
  final String? batch;
  final String? center;
  const OverviewFilter({this.batch, this.center});
  OverviewFilter copyWith({String? batch, String? center}) =>
      OverviewFilter(batch: batch ?? this.batch, center: center ?? this.center);
}

final overviewFilterProvider =
    StateProvider<OverviewFilter>((_) => const OverviewFilter());

final adminOverviewProvider = FutureProvider<AdminOverview>((ref) async {
  final f = ref.watch(overviewFilterProvider);
  return AdminService.getOverview(batch: f.batch, center: f.center);
});

// Students
class StudentsFilter {
  final String search;
  final String? batch;
  final String? center;
  final int page;
  const StudentsFilter(
      {this.search = '', this.batch, this.center, this.page = 1});
  StudentsFilter copyWith({
    String? search,
    String? batch,
    String? center,
    int? page,
  }) =>
      StudentsFilter(
          search: search ?? this.search,
          batch: batch ?? this.batch,
          center: center ?? this.center,
          page: page ?? this.page);
}

final studentsFilterProvider =
    StateProvider<StudentsFilter>((_) => const StudentsFilter());

final adminStudentsProvider =
    FutureProvider<PaginatedResult<AdminStudent>>((ref) async {
  final f = ref.watch(studentsFilterProvider);
  return AdminService.getStudents(
      page: f.page,
      search: f.search,
      batch: f.batch,
      center: f.center);
});

// Subjects
final adminSubjectsProvider =
    FutureProvider<List<SubjectModel>>((ref) async {
  return AdminService.getSubjects();
});

// Marks filter
class AdminMarksFilter {
  final int? subjectId;
  final String? examType;
  final String? batch;
  final int page;
  const AdminMarksFilter(
      {this.subjectId, this.examType, this.batch, this.page = 1});
  AdminMarksFilter copyWith(
          {int? subjectId, String? examType, String? batch, int? page}) =>
      AdminMarksFilter(
          subjectId: subjectId ?? this.subjectId,
          examType: examType ?? this.examType,
          batch: batch ?? this.batch,
          page: page ?? this.page);
}

final adminMarksFilterProvider =
    StateProvider<AdminMarksFilter>((_) => const AdminMarksFilter());

final adminMarksProvider =
    FutureProvider<PaginatedResult<AdminMarkRecord>>((ref) async {
  final f = ref.watch(adminMarksFilterProvider);
  return AdminService.getMarks(
      page: f.page,
      subjectId: f.subjectId,
      examType: f.examType,
      batch: f.batch);
});

// Attendance
final adminAttendanceProvider =
    FutureProvider<PaginatedResult<AdminAttendanceRecord>>((ref) async {
  return AdminService.getAttendance();
});

// Resources
final adminResourcesProvider =
    FutureProvider<PaginatedResult<AdminResourceItem>>((ref) async {
  return AdminService.getResources();
});
