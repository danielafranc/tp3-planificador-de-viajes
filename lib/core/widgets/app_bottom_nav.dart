import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

enum AppNavTab { home, myTrip, budgets, completed, savings }

class AppBottomNav extends StatelessWidget {
  final AppNavTab current;

  const AppBottomNav({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 58,
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Inicio',
              selected: current == AppNavTab.home,
              onTap: () => context.go('/home'),
            ),
            _NavItem(
              icon: Icons.work_outline,
              label: 'Mi Viaje',
              selected: current == AppNavTab.myTrip,
              onTap: () => context.go('/my-trip'),
            ),
            _NavItem(
              icon: Icons.edit_square,
              label: 'Presup.',
              selected: current == AppNavTab.budgets,
              onTap: () => context.go('/budgets'),
            ),
            _NavItem(
              icon: Icons.check_circle_outline,
              label: 'Complet.',
              selected: current == AppNavTab.completed,
              onTap: () => context.go('/completed'),
            ),
            _NavItem(
              icon: Icons.bar_chart,
              label: 'Ahorro',
              selected: current == AppNavTab.savings,
              onTap: () => context.go('/savings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navy : AppColors.mauve;

    return Expanded(
      child: InkWell(
        onTap: selected ? null : onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 4,
              child: selected
                  ? Container(width: 38, color: AppColors.navy)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 5),
            Icon(icon, color: color, size: 19),
            const SizedBox(height: 2),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
