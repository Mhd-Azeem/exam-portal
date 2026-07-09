import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/loading_error.dart';
import '../providers/admin_providers.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Records'),
              Tab(text: 'Bulk Entry'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              _RecordsTab(),
              _BulkAttendanceTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Records tab ──────────────────────────────────────────────────────────────

class _RecordsTab extends ConsumerWidget {
  const _RecordsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(adminAttendanceProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminAttendanceProvider),
      child: attendanceAsync.when(
        loading: () => const LoadingState(message: 'Loading attendance…'),
        error: (e, _) => ErrorState(
            message: 'Failed to load attendance',
            onRetry: () => ref.invalidate(adminAttendanceProvider)),
        data: (result) => result.data.isEmpty
            ? const EmptyState(
                message: 'No attendance records.',
                icon: Icons.calendar_today_outlined)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: result.data.length,
                itemBuilder: (_, i) => _AttendanceTile(record: result.data[i]),
              ),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final AdminAttendanceRecord record;
  const _AttendanceTile({required this.record});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
          border: Border(
            left: BorderSide(
              color:
                  record.isPresent ? AppColors.success : AppColors.error,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              record.isPresent ? Icons.check_circle : Icons.cancel,
              color: record.isPresent ? AppColors.success : AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.studentName ?? '—',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                      '${record.subjectName} · ${record.sessionName}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Text(
              record.isPresent ? 'Present' : 'Absent',
              style: TextStyle(
                color: record.isPresent ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}

// ─── Bulk tab ─────────────────────────────────────────────────────────────────

class _BulkAttendanceTab extends ConsumerStatefulWidget {
  const _BulkAttendanceTab();

  @override
  ConsumerState<_BulkAttendanceTab> createState() =>
      _BulkAttendanceTabState();
}

class _BulkAttendanceTabState extends ConsumerState<_BulkAttendanceTab> {
  int? _subjectId;
  final _sessionCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  String? _examType;
  String _dateStr = DateTime.now().toIso8601String().substring(0, 10);

  bool _loading = false;
  bool _saving = false;

  List<AdminStudent> _students = [];
  final Map<int, bool> _present = {};
  bool _submitted = false;
  String? _resultMsg;

  static const _examTypes = ['Paper 1', 'Paper 2', 'Mock', 'Term Test', 'Other'];

  @override
  void dispose() {
    _sessionCtrl.dispose();
    _batchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(adminSubjectsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: AppColors.cardShadow, blurRadius: 8)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bulk Attendance',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                subjectsAsync.when(
                  loading: () => const SizedBox(
                      height: 48,
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, __) => const Text('Failed to load subjects',
                      style: TextStyle(color: AppColors.error)),
                  data: (subjects) => DropdownButtonFormField<int>(
                    value: _subjectId,
                    decoration: const InputDecoration(
                        labelText: 'Subject *', isDense: true),
                    items: subjects
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _subjectId = v;
                      _students = [];
                      _present.clear();
                    }),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _sessionCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Session Name *', isDense: true),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _examType,
                        decoration: const InputDecoration(
                            labelText: 'Exam Type', isDense: true),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('—')),
                          ..._examTypes.map((t) =>
                              DropdownMenuItem(value: t, child: Text(t))),
                        ],
                        onChanged: (v) => setState(() => _examType = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _batchCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Batch', isDense: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Date', isDense: true),
                    child: Text(_dateStr),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _loadStudents,
                    icon: _loading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.people_outline, size: 18),
                    label: const Text('Load Students'),
                  ),
                ),
              ],
            ),
          ),

          if (_students.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_students.length} students',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontSize: 13)),
                Row(
                  children: [
                    TextButton(
                        onPressed: () => setState(() {
                              for (final s in _students) {
                                _present[s.id] = true;
                              }
                            }),
                        child: const Text('All Present')),
                    TextButton(
                        onPressed: () => setState(() {
                              for (final s in _students) {
                                _present[s.id] = false;
                              }
                            }),
                        child: const Text('All Absent')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._students.map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.cardShadow, blurRadius: 4)
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(s.name[0].toUpperCase(),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(s.indexNumber,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _present[s.id] ?? true,
                        activeColor: AppColors.success,
                        onChanged: (v) =>
                            setState(() => _present[s.id] = v),
                      ),
                      SizedBox(
                        width: 52,
                        child: Text(
                          (_present[s.id] ?? true) ? 'Present' : 'Absent',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: (_present[s.id] ?? true)
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveAll,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save Attendance'),
              ),
            ),

            if (_submitted && _resultMsg != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_resultMsg!,
                    style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateStr) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() =>
          _dateStr = picked.toIso8601String().substring(0, 10));
    }
  }

  Future<void> _loadStudents() async {
    if (_subjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose a subject first.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await AdminService.getStudents(
          perPage: 200,
          batch: _batchCtrl.text.isEmpty ? null : _batchCtrl.text);
      _present.clear();
      for (final s in result.data) {
        _present[s.id] = true;
      }
      setState(() {
        _students = result.data;
        _submitted = false;
        _resultMsg = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveAll() async {
    if (_sessionCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a session name.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final entries = _students.map((s) => {
            'student_id': s.id,
            'subject_id': _subjectId,
            'session_name': _sessionCtrl.text,
            'is_present': _present[s.id] ?? true,
            'date': _dateStr,
            if (_examType != null) 'exam_type': _examType,
          }).toList();

      final bulk = await AdminService.bulkAttendance(entries);
      ref.invalidate(adminAttendanceProvider);
      setState(() {
        _submitted = true;
        _resultMsg =
            '${bulk.successCount} records saved, ${bulk.failed} failed.';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
