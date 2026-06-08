import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/destination.dart';
import '../providers/app_user_provider.dart';
import '../providers/destination_provider.dart';

class AdminDestinationsScreen extends ConsumerStatefulWidget {
  static const String name = 'admin_destinations_screen';

  const AdminDestinationsScreen({super.key});

  @override
  ConsumerState<AdminDestinationsScreen> createState() =>
      _AdminDestinationsScreenState();
}

class _AdminDestinationsScreenState
    extends ConsumerState<AdminDestinationsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(destinationProvider.notifier).getAllDestinations();
    });
  }

  Future<void> confirmDelete(Destination destination) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar destino'),
          content: Text(
            '¿Seguro que querés eliminar "${destination.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await ref
          .read(destinationProvider.notifier)
          .deleteDestination(destination.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Destino "${destination.name}" eliminado.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar el destino.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUserState = ref.watch(appUserProvider);
    final destinationState = ref.watch(destinationProvider);

    if (appUserState.isLoading || destinationState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!appUserState.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.pearl,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          title: const Text('Administrar destinos'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'No tenés permisos para administrar destinos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pearl,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        title: const Text('Administrar destinos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        onPressed: () {
          context.push('/admin-destinations/new');
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: _AdminDestinationContent(
        destinationState: destinationState,
        onDelete: confirmDelete,
      ),
    );
  }
}

class _AdminDestinationContent extends StatelessWidget {
  final DestinationState destinationState;
  final void Function(Destination destination) onDelete;

  const _AdminDestinationContent({
    required this.destinationState,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (destinationState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            destinationState.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (destinationState.destinations.isEmpty) {
      return const Center(
        child: Text(
          'No hay destinos cargados.',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: destinationState.destinations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final destination = destinationState.destinations[index];

        return _AdminDestinationTile(
          destination: destination,
          onDelete: () {
            onDelete(destination);
          },
        );
      },
    );
  }
}

class _AdminDestinationTile extends StatelessWidget {
  final Destination destination;
  final VoidCallback onDelete;

  const _AdminDestinationTile({
    required this.destination,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            destination.imageUrl,
            width: 58,
            height: 58,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 58,
                height: 58,
                color: AppColors.blueCard,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.white,
                ),
              );
            },
          ),
        ),
        title: Text(
          destination.name,
          style: const TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '${destination.province} · USD ${destination.priceFromUsd.toStringAsFixed(0)}',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
          ),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Editar',
              onPressed: () {
                context.push(
                  '/admin-destinations/edit',
                  extra: destination,
                );
              },
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.mauve,
              ),
            ),
            IconButton(
              tooltip: 'Eliminar',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}