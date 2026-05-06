import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'inventory_screen.dart';
import 'pos_screen.dart';
import 'add_product_screen.dart';
import 'sales_history_screen.dart';
import 'reports_screen.dart';
import 'returns_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    PosScreen(),
    InventoryScreen(),
    SalesHistoryScreen(),
    ReportsScreen(),
    ReturnsScreen(),
    ProfileScreen(),
  ];

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.point_of_sale_outlined, activeIcon: Icons.point_of_sale, label: 'Punto de Venta'),
    _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Inventario'),
    _NavItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'Historial'),
    _NavItem(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Reportes'),
    _NavItem(icon: Icons.assignment_return_outlined, activeIcon: Icons.assignment_return, label: 'Devoluciones'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Perfil'),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddProductScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Producto'),
              backgroundColor: AppTheme.primaryLight,
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () => _onItemTapped(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
