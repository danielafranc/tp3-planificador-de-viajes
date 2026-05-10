import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends Notifier<User?> {
  late final FirebaseAuth auth;

  @override
  User? build() {
    auth = FirebaseAuth.instance;

    final subscription = auth.authStateChanges().listen((user) {
      state = user;
    });

    ref.onDispose(() {
      subscription.cancel();
    });

    return auth.currentUser;
  }

  Future<void> login({required String email, required String password}) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() async {
    await auth.signOut();
  }
}
