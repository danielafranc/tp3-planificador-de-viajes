import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../domain/destination.dart';
import '../providers/destination_provider.dart';
import '../providers/new_trip_provider.dart';
import '../providers/trip_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PANTALLA PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────
class NewTripScreen extends ConsumerStatefulWidget {
  static const String name = 'new_trip_screen';

  /// Si se llega desde una card de destino, viene preseleccionado.
  final String? preselectedDestinationId;

  const NewTripScreen({super.key, this.preselectedDestinationId});

  @override
  ConsumerState<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends ConsumerState<NewTripScreen> {
  final _durationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Resetear el formulario al entrar
    Future.microtask(() {
      ref.read(newTripProvider.notifier).resetForm();
      ref.read(destinationProvider.notifier).getAllDestinations();

      // Preseleccionar destino si viene desde una card
      if (widget.preselectedDestinationId != null) {
        _preselectDestination(widget.preselectedDestinationId!);
      }
    });

    // Sincronizar controller de duración con el estado inicial
    _durationCtrl.text = '7';
  }

  void _preselectDestination(String id) {
    final dests = ref.read(destinationProvider).destinations;
    final dest = dests.where((d) => d.id == id).firstOrNull;
    if (dest != null) {
      ref.read(newTripProvider.notifier).selectDestination(dest);
    }
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    super.dispose();
  }

  // ── Calcular el presupuesto y guardarlo en Firestore ──────────────────────
  Future<void> _onCalcular() async {
    final result = await ref.read(newTripProvider.notifier).calculate();
    if (result == null || !mounted) return;

    final newId = await ref.read(tripProvider.notifier).createBudget(result);
    if (!mounted) return;

    if (newId == null) {
      final error = ref.read(tripProvider).errorMessage ?? 'No se pudo guardar.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Presupuesto guardado.')),
    );
    context.go('/budgets');
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(newTripProvider);

    return Scaffold(
      backgroundColor: AppColors.pearl,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──
            const _NewTripHeader(),

            // ── Formulario scrolleable ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // Destino
                  _DestinationField(form: form),
                  const SizedBox(height: 12),

                  // Duración + Fecha en fila
                  Row(
                    children: [
                      Expanded(
                        child: _DurationField(controller: _durationCtrl),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _DateField(form: form)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Checkbox "Mes más barato"
                  _CheapestMonthCheckbox(form: form),
                  const SizedBox(height: 12),

                  // Personas + Hotel en fila
                  Row(
                    children: [
                      Expanded(child: _PeopleDropdown(form: form)),
                      const SizedBox(width: 10),
                      Expanded(child: _HotelDropdown(form: form)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Distancia al centro
                  _DistanceDropdown(form: form),
                  const SizedBox(height: 20),

                  // Sección TRANSPORTE
                  if (form.destination != null) ...[
                    _TransportSection(form: form),
                    const SizedBox(height: 24),
                  ],

                  // Error
                  if (form.errorMessage != null) ...[
                    _ErrorBanner(message: form.errorMessage!),
                    const SizedBox(height: 12),
                  ],

                  // Botón Calcular
                  AppPrimaryButton(
                    text: form.isCalculating
                        ? 'Calculando...'
                        : 'Calcular presupuesto',
                    onPressed: form.isFormValid && !form.isCalculating
                        ? _onCalcular
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _NewTripHeader extends StatelessWidget {
  const _NewTripHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.white,
              size: 18,
            ),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Planificar viaje', style: AppTextStyles.headerTitle),
                SizedBox(height: 2),
                Text(
                  'scroll para ver todo',
                  style: AppTextStyles.headerSubtitle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 40), // balance del back button
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CAMPO: DESTINO  (abre bottom sheet con lista)
// ─────────────────────────────────────────────────────────────────────────────
class _DestinationField extends ConsumerWidget {
  final NewTripFormState form;
  const _DestinationField({required this.form});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destState = ref.watch(destinationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Destino', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () =>
              _showDestinationSheet(context, ref, destState.destinations),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: form.destination != null
                    ? AppColors.navy
                    : const Color(0xFFD7BDB8),
                width: form.destination != null ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    form.destination?.name ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: form.destination != null
                          ? AppColors.black
                          : const Color(0xFFB9A9A6),
                      fontStyle: form.destination != null
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDestinationSheet(
    BuildContext context,
    WidgetRef ref,
    List<Destination> destinations,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _DestinationSheet(
        destinations: destinations,
        onSelected: (dest) {
          ref.read(newTripProvider.notifier).selectDestination(dest);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _DestinationSheet extends StatefulWidget {
  final List<Destination> destinations;
  final void Function(Destination) onSelected;

  const _DestinationSheet({
    required this.destinations,
    required this.onSelected,
  });

  @override
  State<_DestinationSheet> createState() => _DestinationSheetState();
}

class _DestinationSheetState extends State<_DestinationSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.destinations
        .where((d) => d.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Buscá un destino...',
                hintStyle: const TextStyle(
                  color: Color(0xFFB9A9A6),
                  fontStyle: FontStyle.italic,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.muted,
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.pearl,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD7BDB8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.navy,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          // Lista
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final dest = filtered[i];
                return ListTile(
                  leading: const Icon(
                    Icons.place_outlined,
                    color: AppColors.mauve,
                    size: 20,
                  ),
                  title: Text(
                    dest.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  subtitle: Text(
                    dest.province,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  onTap: () => widget.onSelected(dest),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CAMPO: DURACIÓN
// ─────────────────────────────────────────────────────────────────────────────
class _DurationField extends ConsumerWidget {
  final TextEditingController controller;
  const _DurationField({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Duración', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (v) {
            final days = int.tryParse(v);
            if (days != null && days > 0) {
              ref.read(newTripProvider.notifier).setDuration(days);
            }
          },
          decoration: InputDecoration(
            hintText: '7 días',
            hintStyle: const TextStyle(
              color: Color(0xFFB9A9A6),
              fontStyle: FontStyle.italic,
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD7BDB8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.navy, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CAMPO: FECHA / MES
// ─────────────────────────────────────────────────────────────────────────────
class _DateField extends ConsumerWidget {
  final NewTripFormState form;
  const _DateField({required this.form});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disabled = form.cheapestMonth;
    final label = form.tripDate != null
        ? '${_monthName(form.tripDate!.month)} ${form.tripDate!.year}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fecha / mes', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: disabled
              ? null
              : () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        form.tripDate ?? now.add(const Duration(days: 90)),
                    firstDate: now,
                    lastDate: DateTime(now.year + 3),
                    helpText: 'Elegí el mes del viaje',
                    locale: const Locale('es'),
                  );
                  if (picked != null) {
                    ref.read(newTripProvider.notifier).setTripDate(picked);
                  }
                },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: disabled ? const Color(0xFFF3EEEC) : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD7BDB8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label ?? (disabled ? '— desactivado —' : ''),
                    style: TextStyle(
                      fontSize: 14,
                      color: disabled
                          ? AppColors.muted
                          : label != null
                          ? AppColors.black
                          : const Color(0xFFB9A9A6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                if (!disabled)
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.muted,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return months[month];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CHECKBOX: MES MÁS BARATO
// ─────────────────────────────────────────────────────────────────────────────
class _CheapestMonthCheckbox extends ConsumerWidget {
  final NewTripFormState form;
  const _CheapestMonthCheckbox({required this.form});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Checkbox(
          value: form.cheapestMonth,
          activeColor: AppColors.navy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onChanged: (v) {
            ref.read(newTripProvider.notifier).setCheapestMonth(v ?? false);
          },
        ),
        const Text(
          'Mes más barato',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DROPDOWN: PERSONAS
// ─────────────────────────────────────────────────────────────────────────────
class _PeopleDropdown extends ConsumerWidget {
  final NewTripFormState form;
  const _PeopleDropdown({required this.form});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _LabeledDropdown<int>(
      label: 'Personas',
      value: form.people,
      items: List.generate(10, (i) => i + 1),
      labelBuilder: (v) => '$v',
      onChanged: (v) {
        if (v != null) ref.read(newTripProvider.notifier).setPeople(v);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DROPDOWN: HOTEL
// ─────────────────────────────────────────────────────────────────────────────
class _HotelDropdown extends ConsumerWidget {
  final NewTripFormState form;
  const _HotelDropdown({required this.form});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _LabeledDropdown<int>(
      label: 'Hotel',
      value: form.hotelStars,
      items: const [1, 2, 3, 4, 5],
      labelBuilder: (v) => '$v★',
      onChanged: (v) {
        if (v != null) ref.read(newTripProvider.notifier).setHotelStars(v);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DROPDOWN: DISTANCIA AL CENTRO
// ─────────────────────────────────────────────────────────────────────────────
class _DistanceDropdown extends ConsumerWidget {
  final NewTripFormState form;
  const _DistanceDropdown({required this.form});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _LabeledDropdown<int>(
      label: 'Distancia al centro',
      value: form.maxDistanceKm,
      items: const [1, 2, 3, 4, 5],
      labelBuilder: (v) => 'Hasta $v km',
      onChanged: (v) {
        if (v != null) ref.read(newTripProvider.notifier).setMaxDistance(v);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  WIDGET GENÉRICO: DROPDOWN CON LABEL
// ─────────────────────────────────────────────────────────────────────────────
class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final void Function(T?) onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD7BDB8)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.muted,
                size: 20,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.black,
                fontWeight: FontWeight.w500,
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(labelBuilder(item)),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECCIÓN: TRANSPORTE
// ─────────────────────────────────────────────────────────────────────────────
class _TransportSection extends ConsumerWidget {
  final NewTripFormState form;
  const _TransportSection({required this.form});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const allTransports = ['Avión', 'Micro', 'Tren'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRANSPORTE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),

        if (form.isLoadingPrices)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.navy,
                ),
              ),
            ),
          )
        else
          ...allTransports.map((transport) {
            final isUnavailable = form.unavailableTransports.contains(
              transport,
            );
            final isSelected = form.selectedTransport == transport;
            final price = form.transportPrices[transport];

            return _TransportCard(
              name: transport,
              priceUsd: price,
              isSelected: isSelected,
              isUnavailable: isUnavailable,
              onTap: isUnavailable
                  ? null
                  : () => ref
                        .read(newTripProvider.notifier)
                        .selectTransport(transport),
            );
          }),

        const SizedBox(height: 6),
        const Text(
          'Por persona ida y vuelta · actualizados ahora',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.muted,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _TransportCard extends StatelessWidget {
  final String name;
  final double? priceUsd;
  final bool isSelected;
  final bool isUnavailable;
  final VoidCallback? onTap;

  const _TransportCard({
    required this.name,
    required this.priceUsd,
    required this.isSelected,
    required this.isUnavailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isUnavailable
              ? const Color(0xFFF9F5F3)
              : isSelected
              ? AppColors.navy.withValues(alpha: 0.06)
              : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUnavailable
                ? const Color(0xFFE4DDE6)
                : isSelected
                ? AppColors.navy
                : const Color(0xFFD7BDB8),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isUnavailable ? AppColors.muted : AppColors.black,
              ),
            ),
            Text(
              isUnavailable
                  ? 'No disponible'
                  : 'Desde USD ${priceUsd!.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isUnavailable ? AppColors.muted : AppColors.navy,
                fontStyle: isUnavailable ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BANNER DE ERROR
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBanner extends ConsumerWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE57373)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFFD32F2F)),
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(newTripProvider.notifier).clearError(),
            child: const Icon(Icons.close, color: Color(0xFFD32F2F), size: 16),
          ),
        ],
      ),
    );
  }
}
