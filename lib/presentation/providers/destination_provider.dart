import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/destination.dart';

final destinationProvider =
    NotifierProvider<DestinationNotifier, DestinationState>(
      DestinationNotifier.new,
    );

class DestinationState {
  final bool isLoading;
  final String? errorMessage;
  final List<Destination> destinations;

  const DestinationState({
    this.isLoading = false,
    this.errorMessage,
    this.destinations = const [],
  });

  DestinationState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<Destination>? destinations,
  }) {
    return DestinationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      destinations: destinations ?? this.destinations,
    );
  }
}

class DestinationNotifier extends Notifier<DestinationState> {
  @override
  DestinationState build() {
    return const DestinationState();
  }

  Future<void> getAllDestinations() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    final collection = FirebaseFirestore.instance
        .collection('destinations')
        .withConverter(
          fromFirestore: Destination.fromFirestore,
          toFirestore: (Destination destination, _) =>
              destination.toFirestore(),
        );

    try {
      final result = await collection.orderBy('name').get();

      final destinations = result.docs.map((doc) => doc.data()).toList();

      state = state.copyWith(
        isLoading: false,
        destinations: destinations,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudieron cargar los destinos.',
        destinations: [],
      );
    }
  }
}
