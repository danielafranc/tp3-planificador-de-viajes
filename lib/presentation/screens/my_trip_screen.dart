import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../providers/savings_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/my_trip/my_trip_body.dart';

class MyTripScreen extends ConsumerStatefulWidget {
  static const String name = 'my_trip_screen';

  const MyTripScreen({super.key});

  @override
  ConsumerState<MyTripScreen> createState() => _MyTripScreenState();
}

class _MyTripScreenState extends ConsumerState<MyTripScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(tripProvider.notifier).getActiveTrip();
      ref.read(savingsProvider.notifier).getAllMovements();
    });
  }

  Future<void> _onArchive(String tripId) async {
    await ref.read(tripProvider.notifier).archive(tripId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Viaje archivado en Completados.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final savingsState = ref.watch(savingsProvider);

    return Scaffold(
      backgroundColor: AppColors.pearl,
      body: SafeArea(
        bottom: false,
        child: MyTripBody(
          tripState: tripState,
          savingsState: savingsState,
          onArchive: _onArchive,
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppNavTab.myTrip),
    );
  }
}
