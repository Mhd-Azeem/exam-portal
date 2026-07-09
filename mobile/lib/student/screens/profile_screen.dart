import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/loading_error.dart';
import '../providers/student_providers.dart';
import '../models/student_models.dart';
import '../../auth/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final resourcesAsync = ref.watch(resourcesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(profileProvider);
        ref.invalidate(resourcesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          profileAsync.when(
            loading: () => const LoadingState(),
            error: (_, __) => const SizedBox.shrink(),
            data: (profile) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      profile.name[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(profile.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  Text(profile.indexNumber,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 16),
                  _infoRow(Icons.school_outlined, profile.batch ?? '—'),
                  _infoRow(Icons.location_on_outlined, profile.center ?? '—'),
                  if (profile.email != null)
                    _infoRow(Icons.email_outlined, profile.email!),
                  if (profile.phone != null)
                    _infoRow(Icons.phone_outlined, profile.phone!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Resources',
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          resourcesAsync.when(
            loading: () => const LoadingState(),
            error: (_, __) =>
                const Text('Could not load resources',
                    style: TextStyle(color: AppColors.textMuted)),
            data: (resources) => resources.isEmpty
                ? const EmptyState(message: 'No resources available yet.')
                : Column(
                    children: resources.map((r) => _ResourceTile(r: r)).toList()),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text('Log Out',
                style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
}

class _ResourceTile extends StatelessWidget {
  final ResourceItem r;
  const _ResourceTile({required this.r});

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
            const Icon(Icons.file_present_outlined,
                color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (r.subjectName != null)
                    Text(r.subjectName!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (r.url != null)
              const Icon(Icons.open_in_new,
                  color: AppColors.primary, size: 18),
          ],
        ),
      );
}
