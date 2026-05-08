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
  bool _obscureConfirmPassword = true;

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
      if (errStr.contains('user already exists')) {
        return 'Este correo ya está registrado.';
      }
      return error.message;
    }
    return 'Error al crear la cuenta. Inténtalo de nuevo.';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada con éxito. Revisa tu email.'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final message = _getFriendlyErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 850;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          if (isDesktop) _buildDesktopBranding(size),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 1000),
                        child: Container(
                          width: 120,
                          height: 120,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset('assets/logo.png', fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.person_add_rounded, size: 60, color: AppTheme.primary)),
                          ),
                        ),
                      ),
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        child: _buildForm(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBranding(Size size) {
    return Container(
      width: size.width * 0.45,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [AppTheme.primary, Color(0xFF6BBA7D)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInLeft(child: const Icon(Icons.person_add_alt_1_rounded, size: 80, color: Colors.white)),
                const SizedBox(height: 24),
                FadeInLeft(
                  delay: const Duration(milliseconds: 200),
                  child: const Text('Únete a nosotros', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                FadeInLeft(
                  delay: const Duration(milliseconds: 400),
                  child: const Text('Crea tu cuenta en pocos segundos', style: TextStyle(fontSize: 18, color: Colors.white70)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Crear Cuenta', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: appInputDecoration(context, label: 'Nombre Completo', icon: Icons.person_outline),
                validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: appInputDecoration(context, label: 'Email', icon: Icons.email_outlined),
                validator: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: appInputDecoration(context, label: 'Contraseña', icon: Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: appInputDecoration(context, label: 'Confirmar Contraseña', icon: Icons.lock_reset_outlined).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                validator: (v) => (v != _passwordController.text) ? 'Las contraseñas no coinciden' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _register,
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('CREAR CUENTA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿Ya tienes cuenta?', style: TextStyle(fontSize: 13)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Inicia sesión', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
