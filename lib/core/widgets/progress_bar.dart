import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ProgressBar extends StatelessWidget {
  final double progress;
  final double height;

  const ProgressBar({
    super.key,
    required this.progress,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForProgress(progress);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          Container(height: height, color: AppColors.border),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(height: height, color: color),
          ),
        ],
      ),
    );
  }
}

Color _colorForProgress(double progress) {
  if (progress >= 1.0) return const Color(0xFF2E8B57);
  if (progress >= 0.76) return const Color(0xFF8BC34A);
  if (progress >= 0.51) return const Color(0xFFF5C518);
  if (progress >= 0.26) return const Color(0xFFEB8C3A);
  return const Color(0xFFD64545);
}
