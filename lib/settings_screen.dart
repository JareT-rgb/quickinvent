import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_notifier.dart';

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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configuración', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Tema oscuro'),
              trailing: Switch(
                value: isDark,
                onChanged: (v) => ref.read(themeProvider.notifier).setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.store_outlined),
              title: const Text('Nombre de la tienda'),
              subtitle: Text(storeName),
              trailing: const Icon(Icons.edit, size: 18),
              onTap: () => _showNameDialog(context, ref, storeName),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.percent_outlined),
              title: const Text('Tasa de IVA'),
              subtitle: Text('${(taxRate * 100).toStringAsFixed(0)}%'),
              trailing: const Icon(Icons.edit, size: 18),
              onTap: () => _showTaxDialog(context, ref, taxRate),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Acerca de'),
              subtitle: Text('QuickInvent v1.0.0'),
            ),
          ),
        ],
      ),
    );
  }

  void _showNameDialog(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre de la tienda'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nombre'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
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
          decoration: const InputDecoration(hintText: '16'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
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
