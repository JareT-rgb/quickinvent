import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';
import 'auth_repository.dart';
import 'login_screen.dart';

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
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorText = 'Las contraseñas no coinciden');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await ref.read(authRepositoryProvider).signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Cuenta creada! Bienvenido.'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      setState(() => _errorText = 'Error al registrarse: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                            style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold, letterSpacing: 2),
                          ),
                          const Text('ABARROTES', style: TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 4)),
                          const Spacer(),
                          const Text(
                            'Únete y empieza a gestionar tu tienda de forma inteligente.',
                            style: TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
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
                            const Text('Crear cuenta', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            const SizedBox(height: 6),
                            const Text('Regístrate para empezar a vender', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
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
                                    Expanded(child: Text(_errorText!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                                  ],
                                ),
                              ),
                            if (_errorText != null) const SizedBox(height: 16),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _Label('Nombre completo'),
                                  _buildField(_nameController, 'Ej. Juan Pérez', Icons.badge_outlined),
                                  const SizedBox(height: 16),
                                  const _Label('Correo electrónico'),
                                  _buildField(_emailController, 'ejemplo@correo.com', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                                  const SizedBox(height: 16),
                                  _buildLabel('Contraseña'),
                                  _buildPasswordField(_passwordController, 'Crea una contraseña'),
                                  const SizedBox(height: 16),
                                  _buildLabel('Confirmar contraseña'),
                                  _buildPasswordField(_confirmPasswordController, 'Repite tu contraseña'),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _register,
                                      child: _isLoading
                                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                          : const Text('Registrarme'),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Center(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      children: [
                                        const Text('¿Ya tienes una cuenta? ', style: TextStyle(color: AppTheme.textSecondary)),
                                        TextButton(
                                          onPressed: () => Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                                            (route) => false,
                                          ),
                                          child: const Text('Inicia sesión', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
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


class _Label extends StatelessWidget {
  final String label;
  const _Label(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
    );
  }
}

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) => value == null || value.isEmpty ? 'Este campo es obligatorio' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(borderRadius: AppTheme.radiusMedium, borderSide: const BorderSide(color: AppTheme.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: AppTheme.radiusMedium, borderSide: const BorderSide(color: AppTheme.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: AppTheme.radiusMedium, borderSide: const BorderSide(color: AppTheme.primaryLight, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      obscureText: _obscurePassword,
      validator: (value) {
        if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
        if (value.length < 6) return 'Debe tener al menos 6 caracteres';
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppTheme.textSecondary),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(borderRadius: AppTheme.radiusMedium, borderSide: const BorderSide(color: AppTheme.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: AppTheme.radiusMedium, borderSide: const BorderSide(color: AppTheme.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: AppTheme.radiusMedium, borderSide: const BorderSide(color: AppTheme.primaryLight, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
