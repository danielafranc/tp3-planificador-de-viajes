import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_divider_or.dart';
import '../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';


class LoginScreen extends ConsumerStatefulWidget {
  static const String name = 'login_screen';

  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
  final email = emailController.text.trim();
  final password = passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ingresá email y contraseña')),
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    await ref
        .read(authProvider.notifier)
        .login(email: email, password: password);
  } catch (e) {
    if (!mounted) {
      return;
    }

    String message = 'No se pudo iniciar sesión.';

    if (e is FirebaseAuthException) {
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        message = 'Email o contraseña incorrectos.';
      } else if (e.code == 'invalid-email') {
        message = 'El email ingresado no es válido.';
      } else if (e.code == 'user-disabled') {
        message = 'El usuario está deshabilitado.';
      } else if (e.code == 'too-many-requests') {
        message = 'Demasiados intentos. Probá de nuevo más tarde.';
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  if (mounted) {
    setState(() {
      isLoading = false;
    });
  }
}

  Future<void> loginWithGoogle() async {
  setState(() {
    isLoading = true;
  });

  try {
    await ref.read(authProvider.notifier).loginWithGoogle();

    if (!mounted) return;

    context.go('/');
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(
        content: Text('No se pudo iniciar sesión con Google.'),
      ),
    );
  }

  if (mounted) {
    setState(() {
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pearl,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _LoginHero(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Email',
                      hint: 'ejemplo@mail.com',
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Contraseña',
                      hint: '••••••••',
                      controller: passwordController,
                      obscureText: obscurePassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppPrimaryButton(
                      text: isLoading ? 'Ingresando...' : 'Iniciar sesión',
                      onPressed: isLoading ? null : login,
                    ),
                    const SizedBox(height: 14),
                    const AppDividerOr(text: 'o'),
                    const SizedBox(height: 14),
                    AppSecondaryButton(
                      text: isLoading ? 'Ingresando...' : 'Continuar con Google',
                      onPressed: isLoading ? null : loginWithGoogle,
                      leading: const Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const AppDividerOr(text: '¿no tenés cuenta?'),
                    const SizedBox(height: 14),
                    AppSecondaryButton(
                      text: 'Crear cuenta nueva',
                      onPressed: () {
                        context.push('/register');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 205,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      color: AppColors.navy,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Text('✈️', style: TextStyle(fontSize: 38)),
          ),
          const SizedBox(height: 16),
          const Text(
            'TripPlanner',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Planificá tu próximo viaje',
            style: TextStyle(
              color: AppColors.peach,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
