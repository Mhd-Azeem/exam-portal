import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/grade_badge.dart';
import '../../shared/widgets/loading_error.dart';
import '../providers/student_providers.dart';

class MarksScreen extends ConsumerWidget {
  const MarksScreen({super.key});

  static const _examTypes = [
    'Paper 1', 'Paper 2', 'Mock', 'Term Test', 'Tutorial'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marksAsync = ref.watch(marksProvider);
    final filter = ref.watch(marksFilterProvider);

    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filter.examType,
                  decoration: const InputDecoration(
                      hintText: 'All Types',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Types')),
                    ..._examTypes.map((t) =>
                        DropdownMenuItem(value: t, child: Text(t))),
                  ],
                  onChanged: (v) => ref
                      .read(marksFilterProvider.notifier)
                      .update((s) => s.copyWith(examType: v)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: marksAsync.when(
            loading: () => const LoadingState(message: 'Loading marks…'),
            error: (e, _) => ErrorState(
                message: 'Failed to load marks',
                onRetry: () => ref.invalidate(marksProvider)),
            data: (marks) {
              if (marks.isEmpty) {
                return const EmptyState(
                    message: 'No marks recorded yet.',
                    icon: Icons.bar_chart_outlined);
              }
              // Trend chart at top
              final trendMarks = marks.where((m) => m.date != null).toList()
                ..sort((a, b) => a.date!.compareTo(b.date!));

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(marksProvider),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (trendMarks.length > 1)
                      Container(
                        height: 140,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.cardShadow,
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: LineChart(LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: trendMarks
                                  .asMap()
                                  .entries
                                  .map((e) =>
                                      FlSpot(e.key.toDouble(), e.value.percentage))
                                  .toList(),
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 2,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primary.withOpacity(0.08),
                              ),
                            ),
                          ],
                        )),
                      ),
                    ...marks.map((m) => _MarkTile(mark: m)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MarkTile extends StatelessWidget {
  final dynamic mark;
  const _MarkTile({required this.mark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 1))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mark.subjectName ?? '—',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                    '${mark.examType ?? "—"}${mark.pack != null ? " · ${mark.pack}" : ""}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                if (mark.date != null)
                  Text(mark.date,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${mark.mark}/${mark.totalMarks}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text('${mark.percentage}%',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              GradeBadge(grade: mark.grade),
            ],
          ),
        ],
      ),
    );
  }
}
