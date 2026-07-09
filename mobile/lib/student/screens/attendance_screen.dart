import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/loading_error.dart';
import '../providers/student_providers.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(attendanceProvider),
      child: attendanceAsync.when(
        loading: () => const LoadingState(message: 'Loading attendance…'),
        error: (e, _) => ErrorState(
            message: 'Failed to load attendance',
            onRetry: () => ref.invalidate(attendanceProvider)),
        data: (summary) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary row
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Attendance',
                    value: '${summary.percentage}%',
                    color: summary.percentage >= 75
                        ? AppColors.success
                        : summary.percentage >= 50
                            ? AppColors.warning
                            : AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                      label: 'Present',
                      value: '${summary.presentCount}',
                      color: AppColors.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                      label: 'Absent',
                      value: '${summary.absentCount}',
                      color: AppColors.error),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (summary.records.isEmpty)
              const EmptyState(message: 'No attendance records yet.')
            else
              ...summary.records.map((a) => _AttTile(record: a)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 6)
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      );
}

class _AttTile extends StatelessWidget {
  final dynamic record;
  const _AttTile({required this.record});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: record.isPresent ? AppColors.success : AppColors.error,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.subjectName ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (record.sessionName != null)
                    Text(record.sessionName,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  if (record.date != null)
                    Text(record.date,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: record.isPresent
                    ? AppColors.gradeABg
                    : AppColors.gradeFBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                record.isPresent ? 'Present' : 'Absent',
                style: TextStyle(
                    color: record.isPresent ? AppColors.gradeA : AppColors.gradeF,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}
