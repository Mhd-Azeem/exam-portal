import '../../core/api_client.dart';
import '../models/student_models.dart';

class StudentService {
  static Future<StudentProfile> getProfile() async {
    final r = await ApiClient.get('/student/profile');
    return StudentProfile.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  static Future<DashboardSummary> getDashboardSummary() async {
    final r = await ApiClient.get('/student/dashboard-summary');
    return DashboardSummary.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> getUpcomingExams() async {
    final r = await ApiClient.get('/student/upcoming-exams');
    return r.data['data'] as Map<String, dynamic>;
  }

  static Future<List<MarkRecord>> getMarks({
    String? subjectId,
    String? examType,
    String? pack,
  }) async {
    final params = <String, dynamic>{};
    if (subjectId != null) params['subject'] = subjectId;
    if (examType != null) params['exam_type'] = examType;
    if (pack != null) params['pack'] = pack;
    final r = await ApiClient.get('/student/marks', params: params);
    return (r.data['data'] as List)
        .map((e) => MarkRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<AttendanceSummary> getAttendance() async {
    final r = await ApiClient.get('/student/attendance');
    return AttendanceSummary.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> getLeaderboard() async {
    final r = await ApiClient.get('/student/leaderboard');
    return r.data['data'] as Map<String, dynamic>;
  }

  static Future<List<ResourceItem>> getResources({String? subjectId}) async {
    final params = subjectId != null ? {'subject': subjectId} : null;
    final r = await ApiClient.get('/student/resources', params: params);
    return (r.data['data'] as List)
        .map((e) => ResourceItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
