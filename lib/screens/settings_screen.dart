import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_notifier.dart';
import '../theme/app_theme.dart';
import 'category_management_screen.dart';

class StoreNameNotifier extends Notifier<String> {
  @override
  String build() => 'QuickInvent Abarrotes';
  void set(String value) => state = value;
}

final storeNameProvider = NotifierProvider<StoreNameNotifier, String>(() => StoreNameNotifier());

class TaxRateNotifier extends Notifier<double> {
  @override
  double build() => 0.16;
  void set(double value) => state = value;
}

final taxRateProvider = NotifierProvider<TaxRateNotifier, double>(() => TaxRateNotifier());

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final storeName = ref.watch(storeNameProvider);
    final taxRate = ref.watch(taxRateProvider);
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
                  title: 'Nombre de la Tienda',
                  subtitle: storeName,
                  icon: Icons.store_outlined,
                  onTap: () => _showNameDialog(context, ref, storeName),
                ),
                _buildSettingCard(
                  context,
                  title: 'Tasa de IVA',
                  subtitle: '${(taxRate * 100).toStringAsFixed(0)}%',
                  icon: Icons.percent_outlined,
                  onTap: () => _showTaxDialog(context, ref, taxRate),
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
                _buildSectionHeader('Información'),
                _buildSettingCard(
                  context,
                  title: 'Acerca de QuickInvent',
                  subtitle: 'Versión 1.0.0 (Premium)',
                  icon: Icons.info_outline,
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
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
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.4),
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

  void _showNameDialog(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre de la Tienda'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre Comercial',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              ref.read(storeNameProvider.notifier).set(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showTaxDialog(BuildContext context, WidgetRef ref, double current) {
    final controller = TextEditingController(text: (current * 100).toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tasa de IVA (%)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Porcentaje',
            suffixText: '%',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                ref.read(taxRateProvider.notifier).set(val / 100);
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
