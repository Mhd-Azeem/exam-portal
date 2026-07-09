import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/loading_error.dart';
import '../providers/admin_providers.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(adminStudentsProvider);
    final filter = ref.watch(studentsFilterProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search name or index…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(studentsFilterProvider.notifier).update(
                            (s) => s.copyWith(search: '', page: 1));
                      })
                  : null,
            ),
            onChanged: (v) => ref.read(studentsFilterProvider.notifier).update(
                (s) => s.copyWith(search: v, page: 1)),
          ),
        ),
        Expanded(
          child: studentsAsync.when(
            loading: () => const LoadingState(message: 'Loading students…'),
            error: (e, _) => ErrorState(
                message: 'Failed to load students',
                onRetry: () => ref.invalidate(adminStudentsProvider)),
            data: (result) {
              if (result.data.isEmpty) {
                return const EmptyState(
                    message: 'No students found.',
                    icon: Icons.people_outline);
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminStudentsProvider),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ...result.data.map((s) => _StudentTile(
                          student: s,
                          onEdit: () => _showStudentForm(context, s),
                          onDelete: () => _confirmDelete(context, s),
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
                                      .read(studentsFilterProvider.notifier)
                                      .update((s) =>
                                          s.copyWith(page: s.page - 1))
                                  : null,
                            ),
                            Text('${filter.page} / ${result.totalPages}'),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: filter.page < result.totalPages
                                  ? () => ref
                                      .read(studentsFilterProvider.notifier)
                                      .update((s) =>
                                          s.copyWith(page: s.page + 1))
                                  : null,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showStudentForm(BuildContext context,
      [AdminStudent? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name);
    final indexCtrl =
        TextEditingController(text: existing?.indexNumber);
    final emailCtrl = TextEditingController(text: existing?.email);
    final phoneCtrl = TextEditingController(text: existing?.phone);
    final batchCtrl = TextEditingController(text: existing?.batch);
    final centerCtrl = TextEditingController(text: existing?.center);
    final pwCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Student' : 'Edit Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (existing == null)
                _field(indexCtrl, 'Index Number *'),
              _field(nameCtrl, 'Full Name *'),
              _field(emailCtrl, 'Email', keyboard: TextInputType.emailAddress),
              _field(phoneCtrl, 'Phone', keyboard: TextInputType.phone),
              _field(batchCtrl, 'Batch'),
              _field(centerCtrl, 'Center'),
              _field(pwCtrl, existing == null ? 'Password *' : 'New Password',
                  obscure: true),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
            child: Text(existing == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      final data = {
        'name': nameCtrl.text,
        'email': emailCtrl.text.isEmpty ? null : emailCtrl.text,
        'phone': phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
        'batch': batchCtrl.text.isEmpty ? null : batchCtrl.text,
        'center': centerCtrl.text.isEmpty ? null : centerCtrl.text,
        if (pwCtrl.text.isNotEmpty) 'password': pwCtrl.text,
      };
      if (existing == null) {
        data['index_number'] = indexCtrl.text;
        data['password'] = pwCtrl.text;
        await AdminService.createStudent(data);
      } else {
        await AdminService.updateStudent(existing.id, data);
      }
      ref.invalidate(adminStudentsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, AdminStudent s) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Delete Student?'),
              content: Text('Delete ${s.name}? This cannot be undone.'),
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
            ));
    if (ok != true) return;
    try {
      await AdminService.deleteStudent(s.id);
      ref.invalidate(adminStudentsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _field(TextEditingController ctrl, String label,
          {TextInputType? keyboard, bool obscure = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: label, isDense: true),
        ),
      );
}

class _StudentTile extends StatelessWidget {
  final AdminStudent student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentTile(
      {required this.student,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 6)
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryLight,
              child: Text(student.name[0].toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                      '${student.indexNumber}${student.batch != null ? " · ${student.batch}" : ""}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  if (student.averagePercentage != null)
                    Text('Avg ${student.averagePercentage}%',
                        style: const TextStyle(
                            color: AppColors.primary, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.textSecondary),
                onPressed: onEdit),
            IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                onPressed: onDelete),
          ],
        ),
      );
}
