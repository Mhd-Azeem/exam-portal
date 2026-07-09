import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/loading_error.dart';
import '../providers/admin_providers.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  static const _gradeColors = {
    'A': AppColors.gradeA,
    'B': AppColors.gradeB,
    'C': AppColors.gradeC,
    'S': AppColors.gradeS,
    'F': AppColors.gradeF,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(adminOverviewProvider);
    final filter = ref.watch(overviewFilterProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminOverviewProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: overviewAsync.when(
          loading: () => const LoadingState(message: 'Loading overview…'),
          error: (e, _) => ErrorState(
              message: 'Failed to load overview',
              onRetry: () => ref.invalidate(adminOverviewProvider)),
          data: (overview) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Batch/center filter
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: filter.batch,
                      decoration: const InputDecoration(
                          hintText: 'All Batches',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10)),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All Batches')),
                        ...overview.availableBatches.map((b) =>
                            DropdownMenuItem(value: b, child: Text(b))),
                      ],
                      onChanged: (v) {
                        ref
                            .read(overviewFilterProvider.notifier)
                            .update((s) => s.copyWith(batch: v));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: filter.center,
                      decoration: const InputDecoration(
                          hintText: 'All Centers',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10)),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All Centers')),
                        ...overview.availableCenters.map((c) =>
                            DropdownMenuItem(value: c, child: Text(c))),
                      ],
                      onChanged: (v) {
                        ref
                            .read(overviewFilterProvider.notifier)
                            .update((s) => s.copyWith(center: v));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stat cards 2x2
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  StatCard(
                      label: 'Students',
                      value: '${overview.totalStudents}',
                      icon: Icons.people_outline,
                      iconColor: AppColors.primary),
                  StatCard(
                      label: 'Subjects',
                      value: '${overview.totalSubjects}',
                      icon: Icons.book_outlined,
                      iconColor: const Color(0xFF7C3AED)),
                  StatCard(
                      label: 'Marks Entered',
                      value: '${overview.totalMarksEntered}',
                      icon: Icons.edit_note_outlined,
                      iconColor: AppColors.success),
                  StatCard(
                      label: 'Overall Avg',
                      value: '${overview.overallAverage}%',
                      icon: Icons.analytics_outlined,
                      iconColor: AppColors.warning),
                ],
              ),
              const SizedBox(height: 16),

              // Grade distribution donut + top scorer
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Donut chart
                  Expanded(
                    child: Container(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Grade Distribution',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 140,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 36,
                                sections: overview.gradeDistribution.entries
                                    .where((e) => e.value > 0)
                                    .map((e) => PieChartSectionData(
                                          value: e.value.toDouble(),
                                          color: _gradeColors[e.key] ??
                                              Colors.grey,
                                          radius: 36,
                                          title: e.key,
                                          titleStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...overview.gradeDistribution.entries.map((e) => Row(
                                children: [
                                  Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                          color: _gradeColors[e.key] ??
                                              Colors.grey,
                                          shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  Text('${e.key}: ${e.value}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary)),
                                ],
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Top scorer
                  if (overview.topScorer != null)
                    Expanded(
                      child: Container(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Top Scorer',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            const SizedBox(height: 12),
                            const Text('🏆',
                                style: TextStyle(fontSize: 32)),
                            const SizedBox(height: 8),
                            Text(
                              overview.topScorer!['name'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            Text(
                              overview.topScorer!['index_number'] as String,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${overview.topScorer!['average_percentage']}%',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18),
                            ),
                            Text(
                              'Grade ${overview.topScorer!['best_grade']}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
