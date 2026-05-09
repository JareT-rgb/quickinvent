import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/products_repository.dart';
import '../models/category.dart';
import '../providers/products_provider.dart';
import '../providers/categories_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialog.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Categorías', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(context, ref),
            tooltip: 'Nueva Categoría',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: cs.primary.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  const Text('No hay categorías registradas', style: TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showCategoryDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Primera Categoría'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.category, color: cs.primary, size: 20),
                  ),
                  title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showCategoryDialog(context, ref, category: category),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                        onPressed: () => _confirmDelete(context, ref, category),
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar categoría?'),
        content: Text('Esta acción desvinculará a todos los productos de la categoría "${category.name}".'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(productsRepositoryProvider).deleteCategory(category.id);
        ref.invalidate(categoriesProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref, {Category? category}) {
    final controller = TextEditingController(text: category?.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        headerIcon: Icons.category_rounded,
        title: category == null ? 'Nueva Categoría' : 'Editar Categoría',
        subtitle: category == null 
            ? 'Crea una nueva clasificación para tus productos' 
            : 'Modifica el nombre de la clasificación seleccionada',
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la categoría',
                  prefixIcon: Icon(Icons.label_important_outline),
                ),
                autofocus: true,
                validator: (value) => (value == null || value.isEmpty) ? 'El nombre no puede estar vacío' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        if (category == null) {
                          await ref.read(productsRepositoryProvider).addCategory(controller.text);
                        } else {
                          await ref.read(productsRepositoryProvider).updateCategory(category.id, controller.text);
                        }
                        ref.invalidate(categoriesProvider);
                        if (context.mounted) Navigator.of(context).pop();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    }
                  },
                  child: const Text('Guardar Cambios', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}