import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../domain/trip.dart';

class CompletedCard extends StatelessWidget {
  final Trip trip;

  const CompletedCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8BC9A6),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhotoArea(trip: trip),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.destinationName,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle(trip),
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: USD ${trip.totalUsd.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const _CompletedChip(),
                  ],
                ),
                if (trip.archivedAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Archivado en ${formatMonthYear(trip.archivedAt!)}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(Trip trip) {
    final when = trip.tripDate == null
        ? 'fecha a definir'
        : formatMonthYear(trip.tripDate!);
    final personasLabel = trip.people == 1 ? 'persona' : 'personas';
    return '$when · ${trip.durationDays} días · ${trip.people} $personasLabel';
  }
}

class _PhotoArea extends StatelessWidget {
  final Trip trip;

  const _PhotoArea({required this.trip});

  @override
  Widget build(BuildContext context) {
    final fallbackColor = _fallbackColorForName(trip.destinationName);

    return SizedBox(
      height: 96,
      child: trip.destinationImageUrl.isEmpty
          ? _PhotoPlaceholder(
              name: trip.destinationName, color: fallbackColor)
          : Image.network(
              trip.destinationImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _PhotoPlaceholder(
                name: trip.destinationName,
                color: fallbackColor,
              ),
            ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final String name;
  final Color color;

  const _PhotoPlaceholder({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: Alignment.center,
      child: Text(
        'foto API — $name',
        style: const TextStyle(
          color: Color(0xFFF3EBDF),
          fontStyle: FontStyle.italic,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CompletedChip extends StatelessWidget {
  const _CompletedChip();

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E8B57);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F4EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: green.withValues(alpha: 0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, color: green, size: 13),
          SizedBox(width: 4),
          Text(
            'completado',
            style: TextStyle(
              color: green,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Color _fallbackColorForName(String name) {
  const palette = [
    AppColors.purpleCard,
    AppColors.warmCard,
    AppColors.blueCard,
    AppColors.greenCard,
    AppColors.slate,
  ];
  return palette[name.hashCode.abs() % palette.length];
}
