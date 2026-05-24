import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../providers/trip_provider.dart';
import '../widgets/completed/completed_body.dart';

class CompletedTripsScreen extends ConsumerStatefulWidget {
  static const String name = 'completed_trips_screen';

  const CompletedTripsScreen({super.key});

  @override
  ConsumerState<CompletedTripsScreen> createState() =>
      _CompletedTripsScreenState();
}

class _CompletedTripsScreenState extends ConsumerState<CompletedTripsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(tripProvider.notifier).getCompleted();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);

    return Scaffold(
      backgroundColor: AppColors.pearl,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(child: CompletedBody(tripState: tripState)),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppNavTab.completed),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 81,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      color: AppColors.navy,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Completados',
            style: AppTextStyles.headerTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            'Tus viajes archivados',
            style: AppTextStyles.headerSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
