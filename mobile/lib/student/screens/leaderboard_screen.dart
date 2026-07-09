import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/grade_badge.dart';
import '../../shared/widgets/loading_error.dart';
import '../providers/student_providers.dart';
import '../models/student_models.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(leaderboardProvider),
      child: leaderboardAsync.when(
        loading: () => const LoadingState(message: 'Loading leaderboard…'),
        error: (e, _) => ErrorState(
            message: 'Failed to load leaderboard',
            onRetry: () => ref.invalidate(leaderboardProvider)),
        data: (data) {
          final top = data['top_performer'] != null
              ? TopPerformer.fromJson(
                  data['top_performer'] as Map<String, dynamic>)
              : null;
          final board = (data['leaderboard'] as List)
              .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (top != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 36)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Top Performer',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text(top.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18)),
                            Text('${top.averagePercentage}% avg · ${top.bestGrade}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ...board.asMap().entries.map((e) => _LeaderRow(entry: e.value)),
            ],
          );
        },
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final LeaderboardEntry entry;
  const _LeaderRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isMe = entry.isCurrentUser;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: isMe
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: entry.rank <= 3
                ? Text(
                    entry.rank == 1
                        ? '🥇'
                        : entry.rank == 2
                            ? '🥈'
                            : '🥉',
                    style: const TextStyle(fontSize: 18))
                : Text('#${entry.rank}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    style: TextStyle(
                        fontWeight:
                            isMe ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                        color: isMe
                            ? AppColors.primary
                            : AppColors.textPrimary)),
                Text(entry.indexNumber,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.averagePercentage}%',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isMe
                          ? AppColors.primary
                          : AppColors.textPrimary)),
              GradeBadge(grade: entry.bestGrade, fontSize: 10),
            ],
          ),
        ],
      ),
    );
  }
}
