import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../models/admin_models.dart';

class AdminService {
  // ── Overview ──────────────────────────────────────────────────────────────
  static Future<AdminOverview> getOverview({String? batch, String? center}) async {
    final params = <String, dynamic>{};
    if (batch != null) params['batch'] = batch;
    if (center != null) params['center'] = center;
    final r = await ApiClient.get('/admin/overview', params: params);
    return AdminOverview.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  // ── Students ──────────────────────────────────────────────────────────────
  static Future<PaginatedResult<AdminStudent>> getStudents({
    int page = 1,
    int perPage = 20,
    String? search,
    String? batch,
    String? center,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (batch != null) params['batch'] = batch;
    if (center != null) params['center'] = center;
    final r = await ApiClient.get('/admin/students', params: params);
    return PaginatedResult(
      data: (r.data['data'] as List)
          .map((e) => AdminStudent.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: r.data['page'] as int,
      totalPages: r.data['total_pages'] as int,
      totalCount: r.data['total_count'] as int,
    );
  }

  static Future<AdminStudent> createStudent(Map<String, dynamic> data) async {
    final r = await ApiClient.post('/admin/students', data: data);
    return AdminStudent.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  static Future<AdminStudent> updateStudent(
      int id, Map<String, dynamic> data) async {
    final r = await ApiClient.put('/admin/students/$id', data: data);
    return AdminStudent.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  static Future<void> deleteStudent(int id) async {
    await ApiClient.delete('/admin/students/$id');
  }

  // ── Subjects ──────────────────────────────────────────────────────────────
  static Future<List<SubjectModel>> getSubjects() async {
    final r = await ApiClient.get('/admin/subjects');
    return (r.data['data'] as List)
        .map((e) => SubjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<SubjectModel> createSubject(
      String name, String? code, String? description) async {
    final r = await ApiClient.post('/admin/subjects',
        data: {'name': name, 'code': code, 'description': description});
    return SubjectModel.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  static Future<SubjectModel> updateSubject(
      int id, String name, String? code, String? description) async {
    final r = await ApiClient.put('/admin/subjects/$id',
        data: {'name': name, 'code': code, 'description': description});
    return SubjectModel.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  static Future<void> deleteSubject(int id) async {
    await ApiClient.delete('/admin/subjects/$id');
  }

  // ── Marks ─────────────────────────────────────────────────────────────────
  static Future<PaginatedResult<AdminMarkRecord>> getMarks({
    int page = 1,
    int perPage = 30,
    int? studentId,
    int? subjectId,
    String? examType,
    String? batch,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (studentId != null) params['student_id'] = studentId;
    if (subjectId != null) params['subject_id'] = subjectId;
    if (examType != null) params['exam_type'] = examType;
    if (batch != null) params['batch'] = batch;
    final r = await ApiClient.get('/admin/marks', params: params);
    return PaginatedResult(
      data: (r.data['data'] as List)
          .map((e) => AdminMarkRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: r.data['page'] as int,
      totalPages: r.data['total_pages'] as int,
      totalCount: r.data['total_count'] as int,
    );
  }

  static Future<AdminMarkRecord> createMark(Map<String, dynamic> data) async {
    final r = await ApiClient.post('/admin/marks', data: data);
    return AdminMarkRecord.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  static Future<BulkResponse> bulkCreateMarks(
      List<Map<String, dynamic>> entries) async {
    final r = await ApiClient.post('/admin/marks/bulk',
        data: {'entries': entries});
    return BulkResponse.fromJson(r.data as Map<String, dynamic>);
  }

  static Future<void> deleteMark(int id) async {
    await ApiClient.delete('/admin/marks/$id');
  }

  // ── Attendance ────────────────────────────────────────────────────────────
  static Future<PaginatedResult<AdminAttendanceRecord>> getAttendance({
    int page = 1,
    int perPage = 30,
    int? studentId,
    int? subjectId,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (studentId != null) params['student_id'] = studentId;
    if (subjectId != null) params['subject_id'] = subjectId;
    final r = await ApiClient.get('/admin/attendance', params: params);
    return PaginatedResult(
      data: (r.data['data'] as List)
          .map((e) =>
              AdminAttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: r.data['page'] as int,
      totalPages: r.data['total_pages'] as int,
      totalCount: r.data['total_count'] as int,
    );
  }

  static Future<BulkResponse> bulkAttendance(
      List<Map<String, dynamic>> entries) async {
    final r = await ApiClient.post('/admin/attendance/bulk',
        data: {'entries': entries});
    return BulkResponse.fromJson(r.data as Map<String, dynamic>);
  }

  // ── Resources ─────────────────────────────────────────────────────────────
  static Future<PaginatedResult<AdminResourceItem>> getResources({
    int page = 1,
  }) async {
    final r = await ApiClient.get('/admin/resources',
        params: {'page': page, 'per_page': 20});
    return PaginatedResult(
      data: (r.data['data'] as List)
          .map((e) => AdminResourceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: r.data['page'] as int,
      totalPages: r.data['total_pages'] as int,
      totalCount: r.data['total_count'] as int,
    );
  }

  static Future<void> deleteResource(int id) async {
    await ApiClient.delete('/admin/resources/$id');
  }

  static Future<AdminResourceItem> uploadResource({
    required String title,
    String? description,
    int? subjectId,
    String? url,
    String? filePath,
    String? fileName,
  }) async {
    Response r;
    if (filePath != null) {
      final formData = FormData.fromMap({
        'title': title,
        if (description != null) 'description': description,
        if (subjectId != null) 'subject_id': subjectId.toString(),
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      r = await ApiClient.postFormData('/admin/resources', formData);
    } else {
      r = await ApiClient.post('/admin/resources', data: {
        'title': title,
        'description': description,
        'subject_id': subjectId,
        'url': url,
      });
    }
    return AdminResourceItem.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  // ── Leaderboard settings ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getLeaderboardSettings() async {
    final r = await ApiClient.get('/admin/leaderboard-settings');
    return r.data['data'] as Map<String, dynamic>;
  }
}
