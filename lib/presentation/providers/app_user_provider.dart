import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_user.dart';
import 'auth_provider.dart';

final appUserProvider =
    NotifierProvider<AppUserNotifier, AppUserState>(AppUserNotifier.new);

class AppUserState {
  final bool isLoading;
  final String? errorMessage;
  final AppUser? appUser;

  const AppUserState({
    this.isLoading = false,
    this.errorMessage,
    this.appUser,
  });

  bool get isAdmin => appUser?.isAdmin ?? false;
  bool get isUser => appUser?.isUser ?? false;

  AppUserState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    AppUser? appUser,
    bool clearAppUser = false,
  }) {
    return AppUserState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      appUser: clearAppUser ? null : appUser ?? this.appUser,
    );
  }
}

class AppUserNotifier extends Notifier<AppUserState> {
  @override
  AppUserState build() {
    final firebaseUser = ref.watch(authProvider);

    if (firebaseUser == null) {
      return const AppUserState();
    }

    Future.microtask(() {
      getCurrentAppUser();
    });

    return const AppUserState(isLoading: true);
  }

  Future<void> getCurrentAppUser() async {
    final firebaseUser = ref.read(authProvider);

    if (firebaseUser == null) {
      state = const AppUserState();
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .withConverter(
            fromFirestore: AppUser.fromFirestore,
            toFirestore: (AppUser user, _) => user.toFirestore(),
          );

      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No se encontró el usuario en Firestore.',
          clearAppUser: true,
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        appUser: snapshot.data(),
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo cargar el usuario.',
        clearAppUser: true,
      );
    }
  }
}