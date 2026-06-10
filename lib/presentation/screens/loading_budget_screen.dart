import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/dollar_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/budget_model.dart';

class LoadingBudgetScreen extends StatefulWidget {
  static const String name = 'calculando_screen';
  final dynamic formData;

  const LoadingBudgetScreen({super.key, required this.formData});

  @override
  State<LoadingBudgetScreen> createState() => _LoadingBudgetScreenState();
}

class _LoadingBudgetScreenState extends State<LoadingBudgetScreen> {
  bool _vueloListo = false;
  bool _hotelListo = false;
  bool _mepListo = false;
  bool _calculandoTotal = false;
  String _headerDestino = 'Buscando...';
  String _headerSubtitulo = 'Calculando detalles';
  String _transporteSeleccionado = 'Vuelo';
  int _hotelEstrellas = 3;
  int _distancia = 2;

  @override
  void initState() {
    super.initState();
    if (widget.formData != null && widget.formData is Map) {
      _headerDestino = widget.formData['destino'] ?? 'Destino';
      _transporteSeleccionado = widget.formData['transporte'] ?? 'Vuelo';
      _hotelEstrellas = widget.formData['hotelEstrellas'] ?? 3;
      _distancia = widget.formData['distancia'] ?? 2;
    }
    _cargarYNavegar();
  }

  Future<void> _cargarYNavegar() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Usuario no autenticado');

      final destino = widget.formData?['destino'] ?? '';

      // Busca  documento en Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('trips')
          .where('destinationName', isEqualTo: destino)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (!mounted) return;
      if (snapshot.docs.isEmpty)
        throw Exception('No se encontró el presupuesto');

      final data = snapshot.docs.first.data();
      final id = snapshot.docs.first.id;

      final int pasajeros = data['people'] ?? 1;
      final String fechaFormateada = data['tripDate'] != null
          ? _formatDate(data['tripDate'] as Timestamp)
          : '';

      setState(() {
        _headerDestino = data['destinationName'] ?? destino;
        _headerSubtitulo =
            '$fechaFormateada • $pasajeros ${pasajeros == 1 ? 'persona' : 'personas'}';
      });

      await Future.delayed(const Duration(milliseconds: 800));
      setState(() => _vueloListo = true);

      await Future.delayed(const Duration(milliseconds: 800));
      setState(() => _hotelListo = true);

      final mepActual = await DollarService().getMepRate();
      print('MEP obtenido: $mepActual');

      setState(() => _mepListo = true);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _calculandoTotal = true);
      await Future.delayed(const Duration(milliseconds: 400));

      final totalUsd = (data['totalUsd'] ?? 0.0).toDouble();

      final budget = BudgetModel(
        id: id,
        destination: data['destinationName'] ?? '',
        passengers: pasajeros,
        totalUSD: totalUsd,
        exchangeRateMEP: mepActual,
        status: data['state'] ?? 'Presupuesto',
        transportUsd: (data['transportCostUsd'] ?? 0.0).toDouble(),
        hotelUsd: (data['hotelCostUsd'] ?? 0.0).toDouble(),
        nights: data['durationDays'] ?? 1,
        targetDate: data['tripDate'] != null
            ? _formatDate(data['tripDate'] as Timestamp)
            : null,
        savingDeadline: data['savingsTargetDate'] != null
            ? _formatDate(data['savingsTargetDate'] as Timestamp)
            : null,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        transport: data['transport'],
        hotelStars: data['hotelStars'],
        maxDistanceKm: data['maxDistanceKm'],
      );

      if (!mounted) return;
      context.go('/budget-result', extra: budget);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      context.pop();
    }
  }

  String _formatDate(Timestamp ts) {
    final date = ts.toDate();
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
    return '${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        '5 — CALCULANDO',
                        style: AppTextStyles.fieldLabel.copyWith(
                          color: Colors.white38,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Calculando presupuesto',
                    style: AppTextStyles.headerTitle.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _headerSubtitulo.isNotEmpty
                        ? '$_headerDestino • $_headerSubtitulo'
                        : _headerDestino,
                    style: AppTextStyles.fieldLabel.copyWith(
                      color: const Color(0xFFF3A382),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.pearl,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          color: AppColors.mauve,
                          strokeWidth: 4.0,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Buscando las mejores opciones...',
                        style: AppTextStyles.headerTitle.copyWith(
                          color: AppColors.navy,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 40),

                      _buildLoadingItem(
                        estaListo: _vueloListo,
                        textoActivo: _transporteSeleccionado,
                        textoDetalle: 'completado',
                        esperandoTexto: 'analizando...',
                      ),
                      const Divider(height: 24, color: Colors.black12),
                      _buildLoadingItem(
                        estaListo: _hotelListo,
                        textoActivo:
                            'Hotel $_hotelEstrellas★ a ${_distancia}km',
                        textoDetalle: 'completado',
                        esperandoTexto: 'buscando...',
                      ),
                      const Divider(height: 24, color: Colors.black12),
                      _buildLoadingItem(
                        estaListo: _mepListo,
                        textoActivo: 'Tipo de cambio MEP',
                        textoDetalle: 'completado',
                        esperandoTexto: 'buscando...',
                        mostrarSpinnerAlCargar: true && _hotelListo,
                      ),
                      const Divider(height: 24, color: Colors.black12),
                      _buildLoadingItem(
                        estaListo: _calculandoTotal,
                        textoActivo: 'Calculando total',
                        textoDetalle: 'listo',
                        esperandoTexto: 'esperando...',
                        mostrarSpinnerAlCargar: true && _mepListo,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingItem({
    required bool estaListo,
    required String textoActivo,
    required String textoDetalle,
    required String esperandoTexto,
    bool mostrarSpinnerAlCargar = false,
  }) {
    return Row(
      children: [
        if (estaListo)
          const Icon(Icons.check_circle, color: Colors.green, size: 24)
        else if (mostrarSpinnerAlCargar)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: AppColors.mauve,
              strokeWidth: 2,
            ),
          )
        else
          Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 24),
        const SizedBox(width: 16),

        Text(
          textoActivo,
          style: AppTextStyles.fieldLabel.copyWith(
            color: estaListo ? AppColors.navy : Colors.grey.shade400,
            fontWeight: estaListo ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const Spacer(),

        Text(
          estaListo ? textoDetalle : esperandoTexto,
          style: AppTextStyles.fieldLabel.copyWith(
            color: estaListo
                ? AppColors.navy.withOpacity(0.8)
                : Colors.grey.shade400,
            fontStyle: estaListo ? FontStyle.normal : FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
