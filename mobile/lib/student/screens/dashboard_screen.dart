import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/grade_badge.dart';
import '../../shared/widgets/loading_error.dart';
import '../providers/student_providers.dart';
import '../../auth/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final upcomingAsync = ref.watch(upcomingExamsProvider);
    final user = ref.watch(authProvider).user;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(upcomingExamsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?['name'] ?? 'Student',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _chip(user?['index_number'] ?? ''),
                      if (user?['batch'] != null) ...[
                        const SizedBox(width: 6),
                        _chip(user!['batch']),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            summaryAsync.when(
              loading: () => const LoadingState(message: 'Loading summary…'),
              error: (e, _) => ErrorState(
                  message: 'Failed to load summary',
                  onRetry: () => ref.invalidate(dashboardSummaryProvider)),
              data: (summary) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 4 stat cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      StatCard(
                          label: 'Subjects',
                          value: '${summary.subjectsCount}',
                          icon: Icons.book_outlined,
                          iconColor: AppColors.primary),
                      StatCard(
                          label: 'Average',
                          value: '${summary.averagePercentage}%',
                          icon: Icons.trending_up,
                          iconColor: AppColors.success),
                      StatCard(
                          label: 'Highest',
                          value: '${summary.highestPercentage}%',
                          icon: Icons.star_outline,
                          iconColor: AppColors.warning),
                      StatCard(
                          label: 'Best Grade',
                          value: summary.bestGrade,
                          icon: Icons.grade_outlined,
                          iconColor: const Color(0xFF7C3AED)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Batch rank
                  Container(
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
                    child: Row(
                      children: [
                        Text(
                          '#${summary.batchRank ?? "—"}',
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Batch Rank',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(
                                'out of ${summary.totalInBatch} students',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                        if (summary.topPerformer != null) ...[
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Top',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11)),
                              Text(
                                summary.topPerformer!.name.split(' ').first,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                              Text(
                                '${summary.topPerformer!.averagePercentage}%',
                                style: const TextStyle(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Trend chart
                  if (summary.recentTrend.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
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
                          const Text('Recent Performance',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 120,
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: false),
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: summary.recentTrend
                                        .asMap()
                                        .entries
                                        .map((e) => FlSpot(
                                            e.key.toDouble(),
                                            e.value.percentage))
                                        .toList(),
                                    isCurved: true,
                                    color: AppColors.primary,
                                    barWidth: 2.5,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: AppColors.primary.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),
            // Upcoming exams
            upcomingAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) {
                final exams = (data['upcoming'] as List? ?? []);
                if (exams.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Upcoming Exams',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...exams.take(4).map((e) {
                      final exam = e as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.cardShadow,
                                blurRadius: 6)
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${exam['days_until'] ?? "?"}d',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(exam['title'] as String,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  if (exam['subject_name'] != null)
                                    Text(
                                        '${exam['subject_name']} · ${exam['exam_type'] ?? ""}',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 11)),
      );
}
