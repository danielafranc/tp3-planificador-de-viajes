import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import '../../domain/app_user.dart';

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends Notifier<User?> {
  late final FirebaseAuth auth;
  late final FirebaseFirestore firestore;

  bool _googleInitialized = false;
  

  @override
  User? build() {
    auth = FirebaseAuth.instance;
    firestore = FirebaseFirestore.instance;

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

  Future<void> loginWithGoogle() async {
  UserCredential userCredential;

  if (kIsWeb) {
    final googleProvider = GoogleAuthProvider();

    userCredential = await auth.signInWithPopup(googleProvider);
  } else {
    final googleSignIn = GoogleSignIn.instance;

    if (!_googleInitialized) {
      await googleSignIn.initialize();
      _googleInitialized = true;
    }

    final googleUser = await googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw Exception('Google no devolvió un token válido.');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    userCredential = await auth.signInWithCredential(credential);
  }

  final user = userCredential.user;

  if (user == null) {
    throw Exception('No se pudo iniciar sesión con Google.');
  }

  await _createUserDocumentIfNeeded(user: user);
}

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final cleanName = displayName.trim();
    final cleanEmail = email.trim();

    final credential = await auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('No se pudo crear el usuario.');
    }

    await user.updateDisplayName(cleanName);

    final appUser = AppUser(
      uid: user.uid,
      email: cleanEmail,
      displayName: cleanName,
      role: 'user',
      isActive: true,
    );

    await firestore
        .collection('users')
        .doc(user.uid)
        .set(appUser.toFirestore());
  }

  Future<void> logout() async {
  if (!kIsWeb && _googleInitialized) {
    await GoogleSignIn.instance.signOut();
  }

  await auth.signOut();
}

  Future<void> _createUserDocumentIfNeeded({
  required User user,
  }) async {
  final userRef = firestore.collection('users').doc(user.uid);
  final snapshot = await userRef.get();

  if (snapshot.exists) {
    await userRef.update({
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return;
  }

  await userRef.set({
    'uid': user.uid,
    'email': user.email ?? '',
    'displayName': user.displayName ?? '',
    'role': 'user',
    'isActive': true,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
   });
 } 
}