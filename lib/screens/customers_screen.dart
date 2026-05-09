import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customers_provider.dart';
import '../repositories/customers_repository.dart';
import '../models/customer.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';
import '../repositories/sales_repository.dart';
import '../widgets/app_dialog.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clientes'),
        actions: [
          IconButton(
            onPressed: () => _showAddCustomerDialog(context),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Nuevo Cliente',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          Expanded(
            child: customersAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (_, __) => SkeletonLoader.productCard(), // Using product card skeleton as it's similar
              ),
              error: (e, s) => Center(child: Text('Error: $e')),
              data: (customers) {
                final filtered = customers.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                
                if (filtered.isEmpty) {
                  return const Center(child: Text('No se encontraron clientes'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _CustomerCard(
                    customer: filtered[index],
                    onEdit: (c) => _showEditCustomerDialog(context, c),
                    onDelete: (c) => _confirmDelete(context, c),
                    onPayment: (c) => _showPaymentDialog(context, c),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: appInputDecoration(
          context,
          label: 'Buscar cliente...',
          icon: Icons.search,
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        headerIcon: Icons.person_add_alt_1_rounded,
        title: 'Nuevo Cliente',
        subtitle: 'Registra los datos básicos de tu cliente',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController, 
              decoration: appInputDecoration(context, label: 'Nombre Completo *', icon: Icons.person)
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController, 
              keyboardType: TextInputType.phone,
              decoration: appInputDecoration(context, label: 'Teléfono (Opcional)', icon: Icons.phone)
            ),
          ],
        ),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                try {
                  await ref.read(customersRepositoryProvider).addCustomer(
                    Customer(
                      id: '',
                      name: nameController.text,
                      phone: phoneController.text.isEmpty ? null : phoneController.text,
                      createdAt: DateTime.now(),
                    ),
                  );
                  ref.invalidate(customersProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al guardar: $e'), backgroundColor: AppTheme.error),
                    );
                  }
                }
              },
              child: const Text('Guardar Cliente'),
            ),
          ],
        ),
      ),
    );

  }

  void _showEditCustomerDialog(BuildContext context, Customer customer) {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        headerIcon: Icons.edit_note_rounded,
        title: 'Editar Cliente',
        subtitle: 'Actualiza la información de tu cliente',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController, 
              decoration: appInputDecoration(context, label: 'Nombre Completo *', icon: Icons.person)
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController, 
              keyboardType: TextInputType.phone,
              decoration: appInputDecoration(context, label: 'Teléfono (Opcional)', icon: Icons.phone)
            ),
          ],
        ),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                try {
                  await ref.read(customersRepositoryProvider).updateCustomer(
                    customer.id,
                    {
                      'name': nameController.text,
                      'phone': phoneController.text.isEmpty ? null : phoneController.text,
                    },
                  );
                  ref.invalidate(customersProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: AppTheme.error),
                    );
                  }
                }
              },
              child: const Text('Actualizar Datos'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar cliente?'),
        content: Text('Esta acción no se puede deshacer. Se eliminará a ${customer.name}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(customersRepositoryProvider).deleteCustomer(customer.id);
                ref.invalidate(customersProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Customer customer) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        headerIcon: Icons.payments_rounded,
        headerColor: AppTheme.success,
        title: 'Registrar Abono',
        subtitle: 'Deuda actual: \$${customer.balance.toStringAsFixed(2)}',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el monto que el cliente está pagando en efectivo:'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: appInputDecoration(context, label: 'Monto a pagar', icon: Icons.attach_money),
            ),
          ],
        ),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;
                
                if (amount > customer.balance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('El abono no puede ser mayor a la deuda (\$${customer.balance.toStringAsFixed(2)})'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                try {
                  await ref.read(customersRepositoryProvider).processPayment(
                    customer.id,
                    amount,
                    customer.name,
                  );
                  ref.invalidate(customersProvider);
                  // Also invalidate sales to update cash reports
                  ref.invalidate(salesProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Abono registrado: \$${amount.toStringAsFixed(2)}'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al registrar pago: $e'), backgroundColor: AppTheme.error),
                    );
                  }
                }
              },
              child: const Text('Confirmar Pago'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends ConsumerWidget {
  final Customer customer;
  final Function(Customer) onEdit;
  final Function(Customer) onDelete;
  final Function(Customer) onPayment;

  const _CustomerCard({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    required this.onPayment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: Text(customer.name[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
        ),
        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(customer.phone ?? customer.email ?? 'Sin contacto'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${customer.balance.toStringAsFixed(2)}', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: customer.balance > 0 ? AppTheme.error : AppTheme.success
                  )
                ),
                const Text('Saldo', style: TextStyle(fontSize: 10)),
              ],
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'payment') onPayment(customer);
                if (value == 'edit') onEdit(customer);
                if (value == 'delete') onDelete(customer);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'payment',
                  child: ListTile(
                    leading: Icon(Icons.payments_outlined, color: AppTheme.success, size: 20),
                    title: Text('Abonar / Pagar', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit, size: 20),
                    title: Text('Editar'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: AppTheme.error, size: 20),
                    title: Text('Eliminar', style: TextStyle(color: AppTheme.error)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
