import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/loading_error.dart';
import '../../shared/widgets/grade_badge.dart';
import '../providers/admin_providers.dart';

class AdminLeaderboardScreen extends ConsumerWidget {
  const AdminLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(adminStudentsProvider);
    final filter = ref.watch(studentsFilterProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search name or index…',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) => ref
                      .read(studentsFilterProvider.notifier)
                      .update((s) => s.copyWith(search: v, page: 1)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: studentsAsync.when(
            loading: () =>
                const LoadingState(message: 'Loading leaderboard…'),
            error: (e, _) => ErrorState(
                message: 'Failed to load',
                onRetry: () => ref.invalidate(adminStudentsProvider)),
            data: (result) {
              final sorted = [...result.data]
                ..sort((a, b) => (b.averagePercentage ?? 0)
                    .compareTo(a.averagePercentage ?? 0));

              if (sorted.isEmpty) {
                return const EmptyState(
                    message: 'No students found.',
                    icon: Icons.leaderboard_outlined);
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminStudentsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sorted.length,
                  itemBuilder: (_, i) {
                    final s = sorted[i];
                    final rank = i + 1;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: rank == 1
                            ? const Color(0xFFFFF9E6)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.cardShadow, blurRadius: 6)
                        ],
                        border: rank <= 3
                            ? Border.all(
                                color: _rankColor(rank).withOpacity(0.4))
                            : null,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: rank <= 3
                                ? Text(_rankEmoji(rank),
                                    style: const TextStyle(fontSize: 20),
                                    textAlign: TextAlign.center)
                                : Text('$rank',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary),
                                    textAlign: TextAlign.center),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              s.name[0].toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    '${s.indexNumber}${s.batch != null ? " · ${s.batch}" : ""}',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          if (s.averagePercentage != null) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${s.averagePercentage!.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _rankColor(rank),
                                      fontSize: 15),
                                ),
                                if (s.bestGrade != null)
                                  GradeBadge(grade: s.bestGrade!),
                              ],
                            ),
                          ] else
                            const Text('—',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (studentsAsync.hasValue &&
            (studentsAsync.value?.totalPages ?? 0) > 1)
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
                          .update((s) => s.copyWith(page: s.page - 1))
                      : null,
                ),
                Text(
                    '${filter.page} / ${studentsAsync.value?.totalPages ?? 1}'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: filter.page <
                          (studentsAsync.value?.totalPages ?? 1)
                      ? () => ref
                          .read(studentsFilterProvider.notifier)
                          .update((s) => s.copyWith(page: s.page + 1))
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _rankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFD4A017);
      case 2:
        return const Color(0xFF9E9E9E);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.primary;
    }
  }
}
