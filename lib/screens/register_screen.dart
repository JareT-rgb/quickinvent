import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialog.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getFriendlyErrorMessage(Object error) {
    final errStr = error.toString().toLowerCase();
    if (error is AuthException) {
      if (errStr.contains('user already exists')) return 'Este correo ya está registrado.';
      return error.message;
    }
    return 'Error al crear la cuenta.';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
            fullName: _nameController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cuenta creada. Revisa tu correo.'),
          backgroundColor: AppTheme.success,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_getFriendlyErrorMessage(e)),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: Row(
        children: [
          if (isDesktop) _buildPremiumBranding(size),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: FadeIn(
                  duration: const Duration(milliseconds: 600),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _buildRegisterForm(isDark),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBranding(Size size) {
    return Container(
      width: size.width * 0.42,
      height: size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [AppTheme.primaryDark, AppTheme.primary],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(60.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.person_add_rounded, size: 60, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeInLeft(
                    delay: const Duration(milliseconds: 200),
                    child: const Text('Comienza tu\nhistoria con\nnosotros hoy.', 
                      style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -2)),
                  ),
                  const SizedBox(height: 24),
                  FadeInLeft(
                    delay: const Duration(milliseconds: 400),
                    child: const Text('Únete a la red de comercios más moderna de la región.', 
                      style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (MediaQuery.of(context).size.width < 900)
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        const Text('Crea tu cuenta', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
        const SizedBox(height: 12),
        const Text('Regístrate para empezar a usar QuickInvent.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: appInputDecoration(context, label: 'Nombre completo', icon: Icons.person_rounded),
                validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: appInputDecoration(context, label: 'Correo electrónico', icon: Icons.alternate_email_rounded),
                validator: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: appInputDecoration(context, label: 'Contraseña', icon: Icons.lock_rounded).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: appInputDecoration(context, label: 'Confirmar contraseña', icon: Icons.lock_clock_rounded),
                validator: (v) => (v != _passwordController.text) ? 'Las contraseñas no coinciden' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton(
                  onPressed: _isLoading ? null : _register,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 8,
                    shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('REGISTRARME', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('¿Ya tienes cuenta?', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Inicia sesión', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ],
    );
  }
}
