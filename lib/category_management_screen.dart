import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'category.dart';
import 'products_provider.dart';
import 'products_repository.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Añadir Categoría',
            onPressed: () => _showCategoryDialog(context, ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No hay categorías. Añade una para empezar.'));
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showCategoryDialog(context, ref, category: category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmar'),
                            content: Text('¿Seguro que quieres eliminar la categoría "${category.name}"? Los productos asociados quedarán sin categoría.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await ref.read(productsRepositoryProvider).deleteCategory(category.id);
                            ref.invalidate(categoriesProvider);
                          } catch (e) {
                            // No need for mounted check here as ScaffoldMessenger is not used.
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref, {Category? category}) {
    final controller = TextEditingController(text: category?.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(category == null ? 'Nueva Categoría' : 'Editar Categoría'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Nombre de la categoría'),
              autofocus: true,
              validator: (value) => (value == null || value.isEmpty) ? 'El nombre no puede estar vacío' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final name = controller.text;
                  try {
                    if (category == null) {
                      await ref.read(productsRepositoryProvider).addCategory(name);
                    } else {
                      await ref.read(productsRepositoryProvider).updateCategory(category.id, name);
                    }
                    ref.invalidate(categoriesProvider);
                    
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}