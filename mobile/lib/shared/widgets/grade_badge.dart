import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradeBadge extends StatelessWidget {
  final String grade;
  final double fontSize;

  const GradeBadge({super.key, required this.grade, this.fontSize = 12});

  static Color _bg(String g) => switch (g) {
        'A' => AppColors.gradeABg,
        'B' => AppColors.gradeBBg,
        'C' => AppColors.gradeCBg,
        'S' => AppColors.gradeSBg,
        _ => AppColors.gradeFBg,
      };

  static Color _fg(String g) => switch (g) {
        'A' => AppColors.gradeA,
        'B' => AppColors.gradeB,
        'C' => AppColors.gradeC,
        'S' => AppColors.gradeS,
        _ => AppColors.gradeF,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg(grade),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        grade,
        style: TextStyle(
            color: _fg(grade),
            fontSize: fontSize,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}
