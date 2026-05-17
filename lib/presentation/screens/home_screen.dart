import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../domain/destination.dart';
import '../providers/auth_provider.dart';
import '../providers/destination_provider.dart';
import '../widgets/destination_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const String name = 'home_screen';

  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(destinationProvider.notifier).getAllDestinations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final destinationState = ref.watch(destinationProvider);

    final destinations = destinationState.destinations;

    final featuredDestinations = destinations
        .where((destination) => destination.isFeatured)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.pearl,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _HomeHeader(
              onLogout: () {
                ref.read(authProvider.notifier).logout();
              },
            ),
            Expanded(
              child: _HomeContent(
                destinationState: destinationState,
                destinations: destinations,
                featuredDestinations: featuredDestinations,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _TripPlannerBottomNavigation(),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final DestinationState destinationState;
  final List<Destination> destinations;
  final List<Destination> featuredDestinations;

  const _HomeContent({
    required this.destinationState,
    required this.destinations,
    required this.featuredDestinations,
  });

  @override
  Widget build(BuildContext context) {
    if (destinationState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (destinationState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            destinationState.errorMessage!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return _HomeView(
      destinations: destinations,
      featuredDestinations: featuredDestinations,
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final VoidCallback onLogout;

  const _HomeHeader({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 81,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 10, 12),
      color: AppColors.navy,
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Descubrí Argentina',
                  style: AppTextStyles.headerTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '¿A dónde querés ir?',
                  style: AppTextStyles.headerSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onLogout,
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout, color: AppColors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  final List<Destination> destinations;
  final List<Destination> featuredDestinations;

  const _HomeView({
    required this.destinations,
    required this.featuredDestinations,
  });

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) {
      return const Center(child: Text('Todavía no hay destinos cargados.'));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppOutlineMauveButton(
            text: '＋ Nuevo viaje',
            onPressed: () {
              context.push('/new-trip');
            },
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Destacados', style: AppTextStyles.sectionTitle),
        ),
        const SizedBox(height: 12),
        _FeaturedCarousel(destinations: featuredDestinations),
        const SizedBox(height: 12),
        const _CarouselDots(),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Todos los destinos', style: AppTextStyles.sectionTitle),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _DestinationsGrid(destinations: destinations),
        ),
      ],
    );
  }
}

class _FeaturedCarousel extends StatelessWidget {
  final List<Destination> destinations;

  const _FeaturedCarousel({required this.destinations});

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No hay destinos destacados.'),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: destinations.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final destination = destinations[index];

          return SizedBox(
            width: index == 0 ? 220 : 160,
            child: DestinationCard(
              destination: destination,
              showPrice: true,
              fallbackColor: _fallbackColor(index),
              onTap: () {
                context.push('/new-trip?destinationId=${destination.id}');
              },
            ),
          );
        },
      ),
    );
  }
}

class _DestinationsGrid extends StatelessWidget {
  final List<Destination> destinations;

  const _DestinationsGrid({required this.destinations});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: destinations.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.76,
      ),
      itemBuilder: (context, index) {
        final destination = destinations[index];

        return DestinationCard(
          destination: destination,
          showPrice: false,
          fallbackColor: _fallbackColor(index),
          onTap: () {
            context.push('/new-trip?destinationId=${destination.id}');
          },
        );
      },
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(isActive: true),
        SizedBox(width: 6),
        _Dot(isActive: false),
        SizedBox(width: 6),
        _Dot(isActive: false),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool isActive;

  const _Dot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isActive ? 8 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: isActive ? AppColors.navy : AppColors.border,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _TripPlannerBottomNavigation extends StatelessWidget {
  const _TripPlannerBottomNavigation();

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
            const _NavItem(
              icon: Icons.home_outlined,
              label: 'Inicio',
              selected: true,
            ),
            _NavItem(
              icon: Icons.work_outline,
              label: 'Mi Viaje',
              onTap: () => context.push('/my-trip'),
            ),
            _NavItem(
              icon: Icons.edit_square,
              label: 'Presup.',
              onTap: () => context.push('/budgets'),
            ),
            _NavItem(
              icon: Icons.check_circle_outline,
              label: 'Complet.',
              onTap: () => context.push('/completed'),
            ),
            const _NavItem(icon: Icons.bar_chart, label: 'Ahorro'),
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
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navy : AppColors.mauve;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (selected) {
            return;
          }

          if (onTap != null) {
            onTap!();
            return;
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$label pendiente')));
        },
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

Color _fallbackColor(int index) {
  final colors = [
    AppColors.blueCard,
    AppColors.warmCard,
    AppColors.greenCard,
    AppColors.slate,
    AppColors.blueCard,
    AppColors.purpleCard,
  ];

  return colors[index % colors.length];
}
