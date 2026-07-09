import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/grade_badge.dart';
import '../../shared/widgets/loading_error.dart';
import '../providers/admin_providers.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';

class MarksScreen extends ConsumerStatefulWidget {
  const MarksScreen({super.key});

  @override
  ConsumerState<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends ConsumerState<MarksScreen>
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
              Tab(text: 'Single Entry'),
              Tab(text: 'Bulk Entry'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              _SingleEntryTab(),
              _BulkEntryTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Single Entry ─────────────────────────────────────────────────────────────

class _SingleEntryTab extends ConsumerStatefulWidget {
  const _SingleEntryTab();

  @override
  ConsumerState<_SingleEntryTab> createState() => _SingleEntryTabState();
}

class _SingleEntryTabState extends ConsumerState<_SingleEntryTab> {
  final _markCtrl = TextEditingController();
  final _totalCtrl = TextEditingController(text: '100');
  final _packCtrl = TextEditingController();

  int? _studentId;
  int? _subjectId;
  String? _examType;
  bool _saving = false;

  static const _examTypes = ['Paper 1', 'Paper 2', 'Mock', 'Term Test', 'Other'];

  @override
  void dispose() {
    _markCtrl.dispose();
    _totalCtrl.dispose();
    _packCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(adminStudentsProvider);
    final subjectsAsync = ref.watch(adminSubjectsProvider);
    final marksAsync = ref.watch(adminMarksProvider);
    final filter = ref.watch(adminMarksFilterProvider);

    return Column(
      children: [
        // Form card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add / Update Mark',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 12),
              // Student picker
              studentsAsync.when(
                loading: () => const SizedBox(
                    height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, __) => const Text('Failed to load students',
                    style: TextStyle(color: AppColors.error)),
                data: (result) => DropdownButtonFormField<int>(
                  value: _studentId,
                  decoration: const InputDecoration(
                      labelText: 'Student *', isDense: true),
                  items: result.data
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.name} (${s.indexNumber})',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _studentId = v),
                ),
              ),
              const SizedBox(height: 10),
              // Subject picker
              subjectsAsync.when(
                loading: () => const SizedBox(
                    height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
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
                  onChanged: (v) => setState(() => _subjectId = v),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _examType,
                decoration: const InputDecoration(
                    labelText: 'Exam Type *', isDense: true),
                items: _examTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _examType = v),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _markCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                      decoration: const InputDecoration(
                          labelText: 'Mark *', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _totalCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                          labelText: 'Out of *', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _packCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Pack', isDense: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save Mark'),
                ),
              ),
            ],
          ),
        ),

        // Filters for existing marks list
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: subjectsAsync.maybeWhen(
            data: (subjects) => Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: filter.subjectId,
                    decoration: const InputDecoration(
                        hintText: 'All Subjects', isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Subjects')),
                      ...subjects.map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (v) => ref
                        .read(adminMarksFilterProvider.notifier)
                        .update((s) => s.copyWith(subjectId: v, page: 1)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: filter.examType,
                    decoration: const InputDecoration(
                        hintText: 'All Types', isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Types')),
                      ..._examTypes.map((t) =>
                          DropdownMenuItem(value: t, child: Text(t))),
                    ],
                    onChanged: (v) => ref
                        .read(adminMarksFilterProvider.notifier)
                        .update((s) => s.copyWith(examType: v, page: 1)),
                  ),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ),

        // Marks list
        Expanded(
          child: marksAsync.when(
            loading: () => const LoadingState(message: 'Loading marks…'),
            error: (e, _) => ErrorState(
                message: 'Failed to load marks',
                onRetry: () => ref.invalidate(adminMarksProvider)),
            data: (result) => result.data.isEmpty
                ? const EmptyState(
                    message: 'No marks found.', icon: Icons.edit_note_outlined)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ...result.data.map((m) => _MarkTile(
                            mark: m,
                            onDelete: () => _deleteMark(m),
                          )),
                      if (result.totalPages > 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: filter.page > 1
                                    ? () => ref
                                        .read(adminMarksFilterProvider.notifier)
                                        .update((s) => s.copyWith(page: s.page - 1))
                                    : null,
                              ),
                              Text('${filter.page} / ${result.totalPages}'),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: filter.page < result.totalPages
                                    ? () => ref
                                        .read(adminMarksFilterProvider.notifier)
                                        .update((s) => s.copyWith(page: s.page + 1))
                                    : null,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_studentId == null || _subjectId == null || _examType == null ||
        _markCtrl.text.isEmpty || _totalCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fill in all required fields.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await AdminService.createMark({
        'student_id': _studentId,
        'subject_id': _subjectId,
        'exam_type': _examType,
        'mark': double.parse(_markCtrl.text),
        'total_marks': int.parse(_totalCtrl.text),
        if (_packCtrl.text.isNotEmpty) 'pack': int.tryParse(_packCtrl.text),
      });
      ref.invalidate(adminMarksProvider);
      _markCtrl.clear();
      _packCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mark saved.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteMark(AdminMarkRecord m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Mark?'),
        content: Text(
            'Delete ${m.examType} mark for ${m.studentName} in ${m.subjectName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AdminService.deleteMark(m.id);
      ref.invalidate(adminMarksProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// ─── Bulk Entry ───────────────────────────────────────────────────────────────

class _BulkEntryTab extends ConsumerStatefulWidget {
  const _BulkEntryTab();

  @override
  ConsumerState<_BulkEntryTab> createState() => _BulkEntryTabState();
}

class _BulkEntryTabState extends ConsumerState<_BulkEntryTab> {
  int? _subjectId;
  String? _examType;
  final _batchCtrl = TextEditingController();
  final _totalCtrl = TextEditingController(text: '100');
  final _packCtrl = TextEditingController();

  bool _loading = false;
  bool _saving = false;

  List<AdminStudent> _students = [];
  final Map<int, TextEditingController> _markCtrls = {};
  List<BulkRowResult> _results = [];
  bool _submitted = false;

  static const _examTypes = ['Paper 1', 'Paper 2', 'Mock', 'Term Test', 'Other'];

  @override
  void dispose() {
    _batchCtrl.dispose();
    _totalCtrl.dispose();
    _packCtrl.dispose();
    for (final c in _markCtrls.values) {
      c.dispose();
    }
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
          // Config card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bulk Mark Entry',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                subjectsAsync.when(
                  loading: () => const SizedBox(
                      height: 48,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
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
                      _reset();
                    }),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _examType,
                  decoration: const InputDecoration(
                      labelText: 'Exam Type *', isDense: true),
                  items: _examTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _examType = v;
                    _reset();
                  }),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _batchCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Batch (optional)', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _totalCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                            labelText: 'Out of *', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _packCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                            labelText: 'Pack', isDense: true),
                      ),
                    ),
                  ],
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
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.people_outline, size: 18),
                    label: const Text('Load Students'),
                  ),
                ),
              ],
            ),
          ),

          // Student grid
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
                if (_submitted)
                  TextButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ..._students.asMap().entries.map((e) {
              final idx = e.key;
              final student = e.value;
              final ctrl = _markCtrls[student.id]!;
              final result = _submitted && idx < _results.length
                  ? _results[idx]
                  : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: result == null
                      ? AppColors.surface
                      : result.success
                          ? AppColors.success.withOpacity(0.08)
                          : AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: result == null
                        ? Colors.transparent
                        : result.success
                            ? AppColors.success.withOpacity(0.3)
                            : AppColors.error.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(color: AppColors.cardShadow, blurRadius: 4)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            student.name[0].toUpperCase(),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(student.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Text(student.indexNumber,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: ctrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                            ],
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: 'Mark',
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (result != null)
                          Icon(
                            result.success ? Icons.check_circle : Icons.cancel,
                            color: result.success
                                ? AppColors.success
                                : AppColors.error,
                            size: 20,
                          ),
                      ],
                    ),
                    if (result != null && !result.success && result.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 42),
                        child: Text(
                          result.error!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              );
            }),

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
                label: const Text('Save All'),
              ),
            ),

            if (_submitted && _results.isNotEmpty) ...[
              const SizedBox(height: 12),
              _BulkSummaryRow(results: _results),
            ],
          ],
        ],
      ),
    );
  }

  void _reset() {
    for (final c in _markCtrls.values) {
      c.dispose();
    }
    _markCtrls.clear();
    setState(() {
      _students = [];
      _results = [];
      _submitted = false;
    });
  }

  Future<void> _loadStudents() async {
    if (_subjectId == null || _examType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose a subject and exam type first.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await AdminService.getStudents(
          perPage: 200,
          batch: _batchCtrl.text.isEmpty ? null : _batchCtrl.text);
      for (final c in _markCtrls.values) {
        c.dispose();
      }
      _markCtrls.clear();
      for (final s in result.data) {
        _markCtrls[s.id] = TextEditingController();
      }
      setState(() {
        _students = result.data;
        _results = [];
        _submitted = false;
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
    final totalStr = _totalCtrl.text;
    if (totalStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter the total marks value.')));
      return;
    }
    final totalMarks = int.tryParse(totalStr);
    if (totalMarks == null || totalMarks <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Total marks must be a positive number.')));
      return;
    }

    final entries = <Map<String, dynamic>>[];
    for (final student in _students) {
      final raw = _markCtrls[student.id]?.text.trim() ?? '';
      if (raw.isEmpty) continue;
      entries.add({
        'student_id': student.id,
        'subject_id': _subjectId,
        'exam_type': _examType,
        'mark': double.tryParse(raw) ?? 0,
        'total_marks': totalMarks,
        if (_packCtrl.text.isNotEmpty) 'pack': int.tryParse(_packCtrl.text),
      });
    }

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No marks entered.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final bulk = await AdminService.bulkCreateMarks(entries);
      setState(() {
        _results = bulk.results;
        _submitted = true;
      });
      ref.invalidate(adminMarksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${bulk.successCount} saved, ${bulk.failed} failed out of ${bulk.total}.'),
        ));
      }
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

class _BulkSummaryRow extends StatelessWidget {
  final List<BulkRowResult> results;
  const _BulkSummaryRow({required this.results});

  @override
  Widget build(BuildContext context) {
    final success = results.where((r) => r.success).length;
    final failed = results.length - success;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text('$success',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppColors.success)),
                const Text('Saved',
                    style: TextStyle(
                        color: AppColors.success, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: failed > 0
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.cardShadow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text('$failed',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: failed > 0
                            ? AppColors.error
                            : AppColors.textSecondary)),
                Text('Failed',
                    style: TextStyle(
                        color: failed > 0
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Mark tile ────────────────────────────────────────────────────────────────

class _MarkTile extends StatelessWidget {
  final AdminMarkRecord mark;
  final VoidCallback onDelete;
  const _MarkTile({required this.mark, required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
        ),
        child: Row(
          children: [
            GradeBadge(grade: mark.grade),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mark.studentName ?? '—',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                      '${mark.subjectName} · ${mark.examType}${mark.pack != null ? " Pack ${mark.pack}" : ""}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${mark.mark}/${mark.totalMarks}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${mark.percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 11)),
              ],
            ),
            IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                onPressed: onDelete),
          ],
        ),
      );
}
