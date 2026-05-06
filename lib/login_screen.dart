import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';
import 'auth_repository.dart';
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
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } catch (e) {
      setState(() => _errorText = 'Credenciales incorrectas. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          return Row(
            children: [
              if (isWide)
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primaryDark, AppTheme.primary],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.shopping_cart, size: 72, color: Colors.white),
                          const SizedBox(height: 24),
                          const Text(
                            'QUICKINVENT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const Text(
                            'ABARROTES',
                            style: TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 4),
                          ),
                          const Spacer(),
                          const Text(
                            'Sistema de Punto de Venta e Inventario para tu tienda.\nControl rápido, organizado y sin errores.',
                            style: TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
                          ),
                          const SizedBox(height: 48),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              const _FeatureBadge(icon: Icons.bolt, label: 'Ventas rápidas'),
                              const _FeatureBadge(icon: Icons.inventory, label: 'Inventario en tiempo real'),
                              const _FeatureBadge(icon: Icons.analytics, label: 'Reportes inteligentes'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                flex: 4,
                child: Container(
                  color: AppTheme.background,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isWide) ...[
                              const Icon(Icons.shopping_cart, size: 48, color: AppTheme.primaryLight),
                              const SizedBox(height: 16),
                              const Text('QUICKINVENT', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                              const SizedBox(height: 24),
                            ],
                            const Text('Bienvenido de vuelta', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            const SizedBox(height: 6),
                            const Text('Inicia sesión para continuar', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                            const SizedBox(height: 32),
                            if (_errorText != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withValues(alpha: 0.08),
                                  borderRadius: AppTheme.radiusSmall,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(_errorText!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            if (_errorText != null) const SizedBox(height: 16),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Correo electrónico', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) => value == null || value.isEmpty ? 'Ingresa tu correo' : null,
                                    decoration: _inputDecoration('ejemplo@correo.com', Icons.email_outlined),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    validator: (value) => value == null || value.isEmpty ? 'Ingresa tu contraseña' : null,
                                    decoration: _inputDecoration('Ingresa tu contraseña', Icons.lock_outline).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () async {
                                        if (!mounted) return;
                                        if (_emailController.text.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Ingresa tu correo para restablecer la contraseña')),
                                          );
                                          return;
                                        }
                                        try {
                                          await ref.read(authRepositoryProvider).sendPasswordResetEmail(_emailController.text.trim());
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Correo de recuperación enviado')),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                          }
                                        }
                                      },
                                      child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      child: _isLoading
                                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                          : const Text('Iniciar sesión'),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Center(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      children: [
                                        const Text('¿No tienes una cuenta? ', style: TextStyle(color: AppTheme.textSecondary)),
                                        TextButton(
                                          onPressed: _navigateToRegister,
                                          child: const Text('Regístrate', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textMuted),
      prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondary),
      filled: true,
      fillColor: AppTheme.surface,
      border: OutlineInputBorder(borderRadius: AppTheme.radiusMedium, borderSide: const BorderSide(color: AppTheme.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: AppTheme.radiusMedium, borderSide: const BorderSide(color: AppTheme.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: AppTheme.radiusMedium, borderSide: const BorderSide(color: AppTheme.primaryLight, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryLight, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
