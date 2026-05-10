import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppDividerOr extends StatelessWidget {
  final String text;

  const AppDividerOr({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }
}
