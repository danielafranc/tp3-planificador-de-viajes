import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  static const String name = 'register_screen';

  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureRepeatPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final repeatPassword = repeatPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        repeatPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá todos los campos')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres'),
        ),
      );
      return;
    }

    if (password != repeatPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).register(
            displayName: name,
            email: email,
            password: password,
          );

      if (!mounted) return;

      context.go('/');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo crear la cuenta: $e')),
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
      appBar: AppBar(
        backgroundColor: AppColors.pearl,
        elevation: 0,
        title: const Text('Crear cuenta'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'Registrate en TripPlanner',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Creá tu cuenta para planificar tus viajes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Nombre',
                hint: 'Tu nombre',
                controller: nameController,
              ),
              const SizedBox(height: 14),
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
              AppTextField(
                label: 'Repetir contraseña',
                hint: '••••••••',
                controller: repeatPasswordController,
                obscureText: obscureRepeatPassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      obscureRepeatPassword = !obscureRepeatPassword;
                    });
                  },
                  icon: Icon(
                    obscureRepeatPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                text: isLoading ? 'Creando cuenta...' : 'Crear cuenta',
                onPressed: isLoading ? null : register,
              ),
              const SizedBox(height: 14),
              AppSecondaryButton(
                text: 'Ya tengo cuenta',
                onPressed: isLoading ? null : () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}