import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/loading_error.dart';
import '../providers/admin_providers.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(adminSubjectsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminSubjectsProvider),
      child: subjectsAsync.when(
        loading: () => const LoadingState(message: 'Loading subjects…'),
        error: (e, _) => ErrorState(
            message: 'Failed to load subjects',
            onRetry: () => ref.invalidate(adminSubjectsProvider)),
        data: (subjects) => subjects.isEmpty
            ? const EmptyState(
                message: 'No subjects yet. Add one!',
                icon: Icons.book_outlined)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: subjects.length,
                itemBuilder: (_, i) => _SubjectTile(
                  subject: subjects[i],
                  onEdit: () =>
                      _showForm(context, ref, existing: subjects[i]),
                  onDelete: () =>
                      _confirmDelete(context, ref, subjects[i]),
                ),
              ),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref,
      {SubjectModel? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name);
    final codeCtrl = TextEditingController(text: existing?.code);
    final descCtrl = TextEditingController(text: existing?.description);

    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(existing == null ? 'New Subject' : 'Edit Subject'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _f(nameCtrl, 'Name *'),
                  _f(codeCtrl, 'Code (e.g. PH)'),
                  _f(descCtrl, 'Description', maxLines: 2),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style:
                        ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
                    child: Text(existing == null ? 'Create' : 'Update')),
              ],
            ));

    if (ok != true) return;
    try {
      if (existing == null) {
        await AdminService.createSubject(
            nameCtrl.text, codeCtrl.text.isEmpty ? null : codeCtrl.text,
            descCtrl.text.isEmpty ? null : descCtrl.text);
      } else {
        await AdminService.updateSubject(existing.id, nameCtrl.text,
            codeCtrl.text.isEmpty ? null : codeCtrl.text,
            descCtrl.text.isEmpty ? null : descCtrl.text);
      }
      ref.invalidate(adminSubjectsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, SubjectModel s) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Delete Subject?'),
              content: Text('Delete "${s.name}"? All marks and attendance for this subject will also be deleted.'),
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
      await AdminService.deleteSubject(s.id);
      ref.invalidate(adminSubjectsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _f(TextEditingController c, String label, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label, isDense: true),
        ),
      );
}

class _SubjectTile extends StatelessWidget {
  final SubjectModel subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _SubjectTile(
      {required this.subject, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.book_outlined,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (subject.code != null)
                    Text(subject.code!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
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
