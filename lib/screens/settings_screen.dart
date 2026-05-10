import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/theme_notifier.dart';
import '../providers/app_settings_provider.dart';
import '../theme/app_theme.dart';
import 'category_management_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final settings = ref.watch(appSettingsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Configuración', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('Preferencias de Interfaz'),
                _buildSettingCard(
                  context,
                  title: 'Modo Oscuro',
                  subtitle: isDark ? 'Activado' : 'Desactivado',
                  icon: Icons.palette_outlined,
                  trailing: Switch(
                    value: isDark,
                    onChanged: (v) => ref.read(themeProvider.notifier).setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                    activeColor: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Negocio y Catálogos'),
                _buildSettingCard(
                  context,
                  title: 'Nombre del Negocio',
                  subtitle: settings.businessName,
                  icon: Icons.store_outlined,
                  onTap: () => _showBusinessNameDialog(context, ref, settings),
                ),
                _buildSettingCard(
                  context,
                  title: 'Dirección',
                  subtitle: settings.businessAddress,
                  icon: Icons.location_on_outlined,
                  onTap: () => _showAddressDialog(context, ref, settings),
                ),
                _buildSettingCard(
                  context,
                  title: 'Gestionar Categorías',
                  subtitle: 'Añade, edita o elimina categorías de productos',
                  icon: Icons.category_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Información de Cobro (QR)'),
                _buildSettingCard(
                  context,
                  title: 'Datos de Transferencia',
                  subtitle: settings.transferAccount.isEmpty 
                    ? 'No configurado' 
                    : '${settings.transferBank} • ${settings.transferAccount}',
                  icon: Icons.account_balance_rounded,
                  onTap: () => _showPaymentInfoDialog(context, ref, settings),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Personalización de Recibos'),
                _buildSettingCard(
                  context,
                  title: 'Tamaño de Papel',
                  subtitle: '${settings.paperWidth.toInt()}mm',
                  icon: Icons.print_outlined,
                  trailing: DropdownButton<double>(
                    value: settings.paperWidth,
                    items: const [
                      DropdownMenuItem(value: 58.0, child: Text('58mm')),
                      DropdownMenuItem(value: 80.0, child: Text('80mm')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(appSettingsProvider.notifier).updateSettings(
                          settings.copyWith(paperWidth: v),
                        );
                      }
                    },
                  ),
                ),
                _buildSettingCard(
                  context,
                  title: 'Mensaje al Pie',
                  subtitle: settings.footerMessage,
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () => _showFooterDialog(context, ref, settings),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Información'),
                _buildSettingCard(
                  context,
                  title: 'Acerca de QuickInvent',
                  subtitle: 'Versión 1.0.0 (Premium)',
                  icon: Icons.info_outline,
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Zona de Peligro'),
                _buildSettingCard(
                  context,
                  title: 'Restablecimiento de Fábrica',
                  subtitle: 'Elimina todo el contenido y empieza de cero',
                  icon: Icons.delete_forever_outlined,
                  trailing: const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                  onTap: () => _showFactoryResetDialog(context, ref),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentInfoDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    final nameCtrl = TextEditingController(text: settings.transferName);
    final bankCtrl = TextEditingController(text: settings.transferBank);
    final accCtrl = TextEditingController(text: settings.transferAccount);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información para Transferencias'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre del Titular', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: bankCtrl, decoration: const InputDecoration(labelText: 'Banco', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: accCtrl, decoration: const InputDecoration(labelText: 'CLABE o Cuenta', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(
                transferName: nameCtrl.text,
                transferBank: bankCtrl.text,
                transferAccount: accCtrl.text,
              ));
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showFactoryResetDialog(BuildContext context, WidgetRef ref) {
    final keywordController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.error),
              SizedBox(width: 10),
              Text('¡Acción Crítica!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta acción eliminará permanentemente todas tus ventas, inventario, gastos y configuraciones. No se puede deshacer.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text('Para confirmar, escribe "quickinvent" abajo:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: keywordController,
                decoration: const InputDecoration(hintText: 'Escribe quickinvent', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Ingresa tu contraseña de cuenta:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Contraseña', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (keywordController.text != 'quickinvent') {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La palabra clave es incorrecta')));
                        return;
                      }
                      if (passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes ingresar tu contraseña')));
                        return;
                      }

                      setState(() => isLoading = true);
                      try {
                        final client = Supabase.instance.client;
                        final user = client.auth.currentUser;
                        if (user == null) throw Exception('No hay sesión activa');

                        // 1. Verify password by re-authenticating
                        await client.auth.signInWithPassword(
                          email: user.email!,
                          password: passwordController.text,
                        );

                        // 2. Wipe data in order to respect foreign keys
                        await client.from('sale_items').delete().neq('id', -1);
                        await client.from('returns').delete().neq('id', -1);
                        await client.from('sales').delete().neq('id', -1);
                        await client.from('expenses').delete().neq('id', -1);
                        await client.from('cash_cuts').delete().neq('id', -1);
                        await client.from('products').delete().neq('id', -1);
                        await client.from('categories').delete().neq('id', -1);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sistema restablecido con éxito'), backgroundColor: AppTheme.success),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error de validación: ${e.toString().contains('Invalid login credentials') ? 'Contraseña incorrecta' : e}'), backgroundColor: AppTheme.error),
                          );
                        }
                      } finally {
                        if (context.mounted) setState(() => isLoading = false);
                      }
                    },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
              child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('ELIMINAR TODO'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: cs.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, size: 20) : null),
        onTap: onTap,
      ),
    );
  }

  void _showBusinessNameDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    final controller = TextEditingController(text: settings.businessName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre del Negocio'),
        content: TextField(controller: controller, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(businessName: controller.text));
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showAddressDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    final controller = TextEditingController(text: settings.businessAddress);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dirección del Negocio'),
        content: TextField(controller: controller, decoration: const InputDecoration(border: OutlineInputBorder()), maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(businessAddress: controller.text));
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showFooterDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    final controller = TextEditingController(text: settings.footerMessage);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mensaje al Pie del Recibo'),
        content: TextField(controller: controller, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(footerMessage: controller.text));
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
