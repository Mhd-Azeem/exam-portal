class AdminOverview {
  final int totalStudents;
  final int totalSubjects;
  final int totalMarksEntered;
  final double overallAverage;
  final Map<String, int> gradeDistribution;
  final Map<String, dynamic>? topScorer;
  final List<String> availableBatches;
  final List<String> availableCenters;

  const AdminOverview({
    required this.totalStudents,
    required this.totalSubjects,
    required this.totalMarksEntered,
    required this.overallAverage,
    required this.gradeDistribution,
    this.topScorer,
    required this.availableBatches,
    required this.availableCenters,
  });

  factory AdminOverview.fromJson(Map<String, dynamic> j) => AdminOverview(
        totalStudents: j['total_students'] as int,
        totalSubjects: j['total_subjects'] as int,
        totalMarksEntered: j['total_marks_entered'] as int,
        overallAverage: (j['overall_average'] as num).toDouble(),
        gradeDistribution: Map<String, int>.from(
            (j['grade_distribution'] as Map).map(
                (k, v) => MapEntry(k as String, (v as num).toInt()))),
        topScorer: j['top_scorer'] as Map<String, dynamic>?,
        availableBatches:
            List<String>.from(j['available_batches'] as List),
        availableCenters:
            List<String>.from(j['available_centers'] as List),
      );
}

class AdminStudent {
  final int id;
  final String indexNumber;
  final String name;
  final String? email;
  final String? phone;
  final String? batch;
  final String? center;
  final bool isActive;
  final double? averagePercentage;
  final String? bestGrade;

  const AdminStudent({
    required this.id,
    required this.indexNumber,
    required this.name,
    this.email,
    this.phone,
    this.batch,
    this.center,
    required this.isActive,
    this.averagePercentage,
    this.bestGrade,
  });

  factory AdminStudent.fromJson(Map<String, dynamic> j) => AdminStudent(
        id: j['id'] as int,
        indexNumber: j['index_number'] as String,
        name: j['name'] as String,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        batch: j['batch'] as String?,
        center: j['center'] as String?,
        isActive: j['is_active'] as bool,
        averagePercentage: j['average_percentage'] != null
            ? (j['average_percentage'] as num).toDouble()
            : null,
        bestGrade: j['best_grade'] as String?,
      );
}

class SubjectModel {
  final int id;
  final String name;
  final String? code;
  final String? description;

  const SubjectModel({
    required this.id,
    required this.name,
    this.code,
    this.description,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> j) => SubjectModel(
        id: j['id'] as int,
        name: j['name'] as String,
        code: j['code'] as String?,
        description: j['description'] as String?,
      );
}

class AdminMarkRecord {
  final int id;
  final int studentId;
  final String? studentName;
  final String? studentIndex;
  final int subjectId;
  final String? subjectName;
  final String? examType;
  final String? pack;
  final double mark;
  final double totalMarks;
  final double percentage;
  final String grade;
  final String? date;

  const AdminMarkRecord({
    required this.id,
    required this.studentId,
    this.studentName,
    this.studentIndex,
    required this.subjectId,
    this.subjectName,
    this.examType,
    this.pack,
    required this.mark,
    required this.totalMarks,
    required this.percentage,
    required this.grade,
    this.date,
  });

  factory AdminMarkRecord.fromJson(Map<String, dynamic> j) => AdminMarkRecord(
        id: j['id'] as int,
        studentId: j['student_id'] as int,
        studentName: j['student_name'] as String?,
        studentIndex: j['student_index'] as String?,
        subjectId: j['subject_id'] as int,
        subjectName: j['subject_name'] as String?,
        examType: j['exam_type'] as String?,
        pack: j['pack'] as String?,
        mark: (j['mark'] as num).toDouble(),
        totalMarks: (j['total_marks'] as num).toDouble(),
        percentage: (j['percentage'] as num).toDouble(),
        grade: j['grade'] as String,
        date: j['date'] as String?,
      );
}

class BulkRowResult {
  final int index;
  final bool success;
  final String? action;
  final String? error;
  final String? code;
  final int? id;

  const BulkRowResult({
    required this.index,
    required this.success,
    this.action,
    this.error,
    this.code,
    this.id,
  });

  factory BulkRowResult.fromJson(Map<String, dynamic> j) => BulkRowResult(
        index: j['index'] as int,
        success: j['success'] as bool,
        action: j['action'] as String?,
        error: j['error'] as String?,
        code: j['code'] as String?,
        id: j['id'] as int?,
      );
}

class BulkResponse {
  final bool success;
  final String message;
  final int total;
  final int successCount;
  final int failed;
  final List<BulkRowResult> results;

  const BulkResponse({
    required this.success,
    required this.message,
    required this.total,
    required this.successCount,
    required this.failed,
    required this.results,
  });

  factory BulkResponse.fromJson(Map<String, dynamic> j) => BulkResponse(
        success: j['success'] as bool,
        message: j['message'] as String,
        total: (j['summary'] as Map)['total'] as int,
        successCount: (j['summary'] as Map)['success'] as int,
        failed: (j['summary'] as Map)['failed'] as int,
        results: (j['results'] as List)
            .map((e) => BulkRowResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PaginatedResult<T> {
  final List<T> data;
  final int page;
  final int totalPages;
  final int totalCount;

  const PaginatedResult({
    required this.data,
    required this.page,
    required this.totalPages,
    required this.totalCount,
  });
}

class AdminAttendanceRecord {
  final int id;
  final int studentId;
  final String? studentName;
  final int subjectId;
  final String? subjectName;
  final String? sessionName;
  final String? examType;
  final String? date;
  final bool isPresent;

  const AdminAttendanceRecord({
    required this.id,
    required this.studentId,
    this.studentName,
    required this.subjectId,
    this.subjectName,
    this.sessionName,
    this.examType,
    this.date,
    required this.isPresent,
  });

  factory AdminAttendanceRecord.fromJson(Map<String, dynamic> j) =>
      AdminAttendanceRecord(
        id: j['id'] as int,
        studentId: j['student_id'] as int,
        studentName: j['student_name'] as String?,
        subjectId: j['subject_id'] as int,
        subjectName: j['subject_name'] as String?,
        sessionName: j['session_name'] as String?,
        examType: j['exam_type'] as String?,
        date: j['date'] as String?,
        isPresent: j['is_present'] as bool,
      );
}

class AdminResourceItem {
  final int id;
  final String title;
  final String? description;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final String? subjectName;
  final String? url;
  final String? uploadedAt;

  const AdminResourceItem({
    required this.id,
    required this.title,
    this.description,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.subjectName,
    this.url,
    this.uploadedAt,
  });

  factory AdminResourceItem.fromJson(Map<String, dynamic> j) =>
      AdminResourceItem(
        id: j['id'] as int,
        title: j['title'] as String,
        description: j['description'] as String?,
        fileName: j['file_name'] as String?,
        fileType: j['file_type'] as String?,
        fileSize: j['file_size'] as int?,
        subjectName: j['subject_name'] as String?,
        url: j['url'] as String?,
        uploadedAt: j['uploaded_at'] as String?,
      );
}
