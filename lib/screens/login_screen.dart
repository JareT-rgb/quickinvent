import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialog.dart';
import '../utils/route_transitions.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getFriendlyErrorMessage(Object error) {
    final errStr = error.toString().toLowerCase();
    
    if (error is AuthException) {
      if (errStr.contains('invalid login credentials')) {
        return 'El correo o la contraseña no son correctos.';
      }
      if (errStr.contains('email not confirmed')) {
        return 'Por favor, confirma tu correo electrónico antes de entrar.';
      }
      if (errStr.contains('too many requests')) {
        return 'Demasiados intentos. Por favor, espera un momento.';
      }
      return error.message;
    }
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } catch (e) {
      if (mounted) {
        final message = _getFriendlyErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message))]),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Animado
                      FadeInDown(
                        duration: const Duration(milliseconds: 1000),
                        child: Container(
                          width: 150,
                          height: 150,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset('assets/logo.png', fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.inventory_2_rounded, size: 80, color: AppTheme.primary)),
                          ),
                        ),
                      ),
                      
                      // Formulario Animado
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
        color: AppTheme.primary,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, Color(0xFF6BBA7D)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: -50,
            left: -50,
            child: Icon(Icons.shopping_cart_outlined, size: 300, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInLeft(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.inventory_2_rounded, size: 80, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInLeft(
                  delay: const Duration(milliseconds: 200),
                  child: const Text(
                    'QuickInvent',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
                  ),
                ),
                FadeInLeft(
                  delay: const Duration(milliseconds: 400),
                  child: const Text(
                    'ABARROTES',
                    style: TextStyle(fontSize: 18, color: Colors.white70, letterSpacing: 4),
                  ),
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
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Bienvenido', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              const Text('Ingresa tus credenciales para acceder al sistema', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: appInputDecoration(context, label: 'Correo', icon: Icons.email_outlined),
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
                validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _login,
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('INGRESAR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿No tienes cuenta?', style: TextStyle(fontSize: 13)),
                  TextButton(
                    onPressed: () => Navigator.push(context, RouteTransitions.slideTransition(const RegisterScreen())),
                    child: const Text('Regístrate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
