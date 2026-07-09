class StudentProfile {
  final int id;
  final String indexNumber;
  final String name;
  final String? email;
  final String? phone;
  final String? batch;
  final String? center;

  const StudentProfile({
    required this.id,
    required this.indexNumber,
    required this.name,
    this.email,
    this.phone,
    this.batch,
    this.center,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> j) => StudentProfile(
        id: j['id'] as int,
        indexNumber: j['index_number'] as String,
        name: j['name'] as String,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        batch: j['batch'] as String?,
        center: j['center'] as String?,
      );
}

class DashboardSummary {
  final int subjectsCount;
  final double averagePercentage;
  final double highestPercentage;
  final String bestGrade;
  final int? batchRank;
  final int totalInBatch;
  final List<TrendPoint> recentTrend;
  final TopPerformer? topPerformer;

  const DashboardSummary({
    required this.subjectsCount,
    required this.averagePercentage,
    required this.highestPercentage,
    required this.bestGrade,
    this.batchRank,
    required this.totalInBatch,
    required this.recentTrend,
    this.topPerformer,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) => DashboardSummary(
        subjectsCount: j['subjects_count'] as int,
        averagePercentage: (j['average_percentage'] as num).toDouble(),
        highestPercentage: (j['highest_percentage'] as num).toDouble(),
        bestGrade: j['best_grade'] as String,
        batchRank: j['batch_rank'] as int?,
        totalInBatch: j['total_in_batch'] as int,
        recentTrend: (j['recent_trend'] as List)
            .map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        topPerformer: j['top_performer'] != null
            ? TopPerformer.fromJson(j['top_performer'] as Map<String, dynamic>)
            : null,
      );
}

class TrendPoint {
  final String? date;
  final String? subject;
  final String? examType;
  final double percentage;
  final String grade;

  const TrendPoint({
    this.date,
    this.subject,
    this.examType,
    required this.percentage,
    required this.grade,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> j) => TrendPoint(
        date: j['date'] as String?,
        subject: j['subject'] as String?,
        examType: j['exam_type'] as String?,
        percentage: (j['percentage'] as num).toDouble(),
        grade: j['grade'] as String,
      );
}

class TopPerformer {
  final int id;
  final String name;
  final String indexNumber;
  final double averagePercentage;
  final String bestGrade;

  const TopPerformer({
    required this.id,
    required this.name,
    required this.indexNumber,
    required this.averagePercentage,
    required this.bestGrade,
  });

  factory TopPerformer.fromJson(Map<String, dynamic> j) => TopPerformer(
        id: j['id'] as int,
        name: j['name'] as String,
        indexNumber: j['index_number'] as String,
        averagePercentage: (j['average_percentage'] as num).toDouble(),
        bestGrade: j['best_grade'] as String,
      );
}

class MarkRecord {
  final int id;
  final int studentId;
  final int subjectId;
  final String? subjectName;
  final String? examType;
  final String? pack;
  final double mark;
  final double totalMarks;
  final double percentage;
  final String grade;
  final String? date;

  const MarkRecord({
    required this.id,
    required this.studentId,
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

  factory MarkRecord.fromJson(Map<String, dynamic> j) => MarkRecord(
        id: j['id'] as int,
        studentId: j['student_id'] as int,
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

class AttendanceRecord {
  final int id;
  final String? subjectName;
  final String? sessionName;
  final String? examType;
  final String? date;
  final bool isPresent;

  const AttendanceRecord({
    required this.id,
    this.subjectName,
    this.sessionName,
    this.examType,
    this.date,
    required this.isPresent,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: j['id'] as int,
        subjectName: j['subject_name'] as String?,
        sessionName: j['session_name'] as String?,
        examType: j['exam_type'] as String?,
        date: j['date'] as String?,
        isPresent: j['is_present'] as bool,
      );
}

class AttendanceSummary {
  final double percentage;
  final int totalSessions;
  final int presentCount;
  final int absentCount;
  final List<AttendanceRecord> records;

  const AttendanceSummary({
    required this.percentage,
    required this.totalSessions,
    required this.presentCount,
    required this.absentCount,
    required this.records,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> j) => AttendanceSummary(
        percentage: (j['percentage'] as num).toDouble(),
        totalSessions: j['total_sessions'] as int,
        presentCount: j['present_count'] as int,
        absentCount: j['absent_count'] as int,
        records: (j['records'] as List)
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class LeaderboardEntry {
  final int id;
  final String name;
  final String indexNumber;
  final String? batch;
  final double averagePercentage;
  final String bestGrade;
  final bool isCurrentUser;
  final int rank;

  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.indexNumber,
    this.batch,
    required this.averagePercentage,
    required this.bestGrade,
    required this.isCurrentUser,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        id: j['id'] as int,
        name: j['name'] as String,
        indexNumber: j['index_number'] as String,
        batch: j['batch'] as String?,
        averagePercentage: (j['average_percentage'] as num).toDouble(),
        bestGrade: j['best_grade'] as String,
        isCurrentUser: j['is_current_user'] as bool,
        rank: j['rank'] as int,
      );
}

class ResourceItem {
  final int id;
  final String title;
  final String? description;
  final String? fileName;
  final String? fileType;
  final String? subjectName;
  final String? url;
  final String? uploadedAt;

  const ResourceItem({
    required this.id,
    required this.title,
    this.description,
    this.fileName,
    this.fileType,
    this.subjectName,
    this.url,
    this.uploadedAt,
  });

  factory ResourceItem.fromJson(Map<String, dynamic> j) => ResourceItem(
        id: j['id'] as int,
        title: j['title'] as String,
        description: j['description'] as String?,
        fileName: j['file_name'] as String?,
        fileType: j['file_type'] as String?,
        subjectName: j['subject_name'] as String?,
        url: j['url'] as String?,
        uploadedAt: j['uploaded_at'] as String?,
      );
}

class UpcomingExam {
  final int id;
  final String title;
  final String? subjectName;
  final String? examType;
  final String? examDate;
  final int? daysUntil;

  const UpcomingExam({
    required this.id,
    required this.title,
    this.subjectName,
    this.examType,
    this.examDate,
    this.daysUntil,
  });

  factory UpcomingExam.fromJson(Map<String, dynamic> j) => UpcomingExam(
        id: j['id'] as int,
        title: j['title'] as String,
        subjectName: j['subject_name'] as String?,
        examType: j['exam_type'] as String?,
        examDate: j['exam_date'] as String?,
        daysUntil: j['days_until'] as int?,
      );
}
