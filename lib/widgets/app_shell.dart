import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/pos_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/sales_history_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/returns_screen.dart';
import '../screens/scanner_screen.dart';
import '../screens/cash_register_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/add_product_screen.dart';
import '../widgets/app_sidebar.dart';
import '../theme/app_theme.dart';
import '../repositories/auth_repository.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  String _currentRoute = 'pos';

  final Map<String, Widget> _screens = {
    'pos': const PosScreen(),
    'inventory': const InventoryScreen(),
    'history': const SalesHistoryScreen(),
    'reports': const ReportsScreen(),
    'returns': const ReturnsScreen(),
    'scanner': const ScannerScreen(),
    'cash_cut': const CashRegisterScreen(),
    'settings': const SettingsScreen(),
    'profile': const ProfileScreen(),
  };

  final List<_BottomNavItem> _bottomNavItems = [
    _BottomNavItem(route: 'pos', icon: Icons.point_of_sale_outlined, activeIcon: Icons.point_of_sale, label: 'POS'),
    _BottomNavItem(route: 'inventory', icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Inv'),
    _BottomNavItem(route: 'history', icon: Icons.history_outlined, activeIcon: Icons.history, label: 'Hist'),
    _BottomNavItem(route: 'reports', icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Rep'),
    _BottomNavItem(route: 'cash_cut', icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Caja'),
    _BottomNavItem(route: 'settings', icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Conf'),
  ];

  void _onNavigate(String route) {
    if (route == 'logout') {
      _showLogoutDialog();
      return;
    }
    setState(() => _currentRoute = route);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authRepositoryProvider).signOut();
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Scaffold(
          body: Row(
            children: [
              if (!isMobile)
                AppSidebar(
                  currentRoute: _currentRoute,
                  onNavigate: _onNavigate,
                ),
              Expanded(
                child: Scaffold(
                  body: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: KeyedSubtree(
                      key: ValueKey(_currentRoute),
                      child: _screens[_currentRoute] ?? const PosScreen(),
                    ),
                  ),
                  floatingActionButton: null,
                ),
              ),
            ],
          ),
          bottomNavigationBar: isMobile ? _buildBottomNav(context) : null,
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _bottomNavItems.map((item) {
              final isSelected = _currentRoute == item.route;
              return InkWell(
                onTap: () => _onNavigate(item.route),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? cs.primaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _BottomNavItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
