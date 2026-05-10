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
import '../screens/customers_screen.dart';
import '../widgets/app_sidebar.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_theme.dart';
import '../providers/scanner_status_provider.dart';
import 'package:flutter/foundation.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  String _currentRoute = 'pos';
  bool _isSidebarVisible = true;

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
    'customers': const CustomersScreen(),
  };

  // Primary items shown in the bottom nav bar (max 5 for mobile)
  final List<_BottomNavItem> _primaryNavItems = [
    _BottomNavItem(route: 'pos', icon: Icons.point_of_sale_outlined, activeIcon: Icons.point_of_sale, label: 'POS'),
    _BottomNavItem(route: 'inventory', icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Inventario'),
    _BottomNavItem(route: 'history', icon: Icons.history_outlined, activeIcon: Icons.history, label: 'Historial'),
    _BottomNavItem(route: 'reports', icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Reportes'),
  ];

  // Secondary items shown in the "More" menu
  final List<_BottomNavItem> _secondaryNavItems = [
    _BottomNavItem(route: 'scanner', icon: Icons.qr_code_scanner_outlined, activeIcon: Icons.qr_code_scanner, label: 'Escáner Móvil'),
    _BottomNavItem(route: 'returns', icon: Icons.assignment_return_outlined, activeIcon: Icons.assignment_return, label: 'Devoluciones'),
    _BottomNavItem(route: 'cash_cut', icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Corte de Caja'),
    _BottomNavItem(route: 'settings', icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Configuración'),
    _BottomNavItem(route: 'profile', icon: Icons.person_outlined, activeIcon: Icons.person, label: 'Mi Perfil'),
    _BottomNavItem(route: 'customers', icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'Clientes'),
  ];

  void _onNavigate(String route) {
    if (route == 'logout') {
      _showLogoutDialog();
      return;
    }

    if (route == 'scanner') {
      final isPC = kIsWeb || 
          defaultTargetPlatform == TargetPlatform.windows || 
          defaultTargetPlatform == TargetPlatform.linux || 
          defaultTargetPlatform == TargetPlatform.macOS;
      
      if (isPC) {
        _showScannerLinkingDialog();
        return;
      }
    }

    setState(() => _currentRoute = route);
  }

  void _showScannerLinkingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ScannerLinkingDialog(),
    );
  }

  void _showIncomingLinkingRequest() {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 10),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.primary.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.qr_code_scanner, color: cs.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Solicitud de Escáner desde PC',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ref.read(scannerStatusProvider.notifier).acceptIncomingRequest();
                  _onNavigate('scanner');
                },
                child: Text('VINCULAR', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
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

  void _showMoreMenu() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.apps, color: cs.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Más opciones',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...(_secondaryNavItems.map((item) {
                  final isSelected = _currentRoute == item.route;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? cs.primary : cs.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? cs.primary : cs.onSurface,
                      ),
                    ),
                    trailing: isSelected
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Activo',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                          )
                        : Icon(Icons.chevron_right, color: cs.onSurfaceVariant.withOpacity(0.5)),
                    onTap: () {
                      Navigator.pop(context);
                      _onNavigate(item.route);
                    },
                  );
                })),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.logout, color: Colors.redAccent, size: 22),
                  ),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for incoming linking requests on mobile
    ref.listen(scannerStatusProvider, (previous, next) {
      final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
      if (isMobile && next.hasIncomingRequest && !(previous?.hasIncomingRequest ?? false)) {
        _showIncomingLinkingRequest();
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Scaffold(
          body: Row(
            children: [
              if (!isMobile)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutQuart,
                  width: _isSidebarVisible ? 280 : 0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: 280,
                      child: AppSidebar(
                        currentRoute: _currentRoute,
                        onNavigate: _onNavigate,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Scaffold(
                  appBar: !isMobile ? AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(_isSidebarVisible ? Icons.menu_open_rounded : Icons.menu_rounded, color: AppTheme.primary),
                      onPressed: () => setState(() => _isSidebarVisible = !_isSidebarVisible),
                      tooltip: _isSidebarVisible ? 'Contraer lateral' : 'Expandir lateral',
                    ),
                  ) : null,
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
    // Check if current route is one of the secondary items (for the "More" button highlight)
    final isSecondaryActive = _secondaryNavItems.any((item) => item.route == _currentRoute);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ..._primaryNavItems.map((item) {
                final isSelected = _currentRoute == item.route;
                return _buildNavItem(
                  cs: cs,
                  icon: isSelected ? item.activeIcon : item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () => _onNavigate(item.route),
                );
              }),
              // "More" button
              _buildNavItem(
                cs: cs,
                icon: isSecondaryActive ? Icons.menu_open : Icons.more_horiz,
                label: 'Más',
                isSelected: isSecondaryActive,
                onTap: _showMoreMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required ColorScheme cs,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
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

class _ScannerLinkingDialog extends ConsumerWidget {
  const _ScannerLinkingDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(scannerStatusProvider);
    final isLinked = status.linkingState == ScannerLinkingState.linked;
    final isPending = status.linkingState == ScannerLinkingState.pending;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: AppTheme.glassDecoration(isDark: isDark),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLinked) ...[
               const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 64),
               const SizedBox(height: 24),
               const Text('¡Dispositivo Vinculado!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
               const SizedBox(height: 12),
               const Text('Ahora puedes usar tu teléfono para escanear productos y se reflejarán aquí al instante.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
               const SizedBox(height: 32),
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: () => Navigator.pop(context),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppTheme.success,
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                   child: const Text('LISTO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                 ),
               ),
            ] else if (isPending) ...[
               const SizedBox(
                 height: 64, width: 64,
                 child: CircularProgressIndicator(strokeWidth: 6, color: AppTheme.primary),
               ),
               const SizedBox(height: 24),
               const Text('Esperando Conexión...', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
               const SizedBox(height: 12),
               const Text('Abre la app en tu teléfono o tablet. En un momento recibirás la señal de vínculo.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
               const SizedBox(height: 32),
               TextButton(
                 onPressed: () {
                   ref.read(scannerStatusProvider.notifier).cancelLinking();
                   Navigator.pop(context);
                 },
                 child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
               ),
            ] else ...[
               const Icon(Icons.phone_android_rounded, color: AppTheme.primary, size: 64),
               const SizedBox(height: 24),
               const Text('Vincular Escáner', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
               const SizedBox(height: 12),
               const Text(
                 'Inicia sesión en tu teléfono o tablet con esta misma cuenta para poder vincularlo como escáner móvil.',
                 textAlign: TextAlign.center,
                 style: TextStyle(color: Colors.grey),
               ),
               const SizedBox(height: 32),
               Row(
                 children: [
                   Expanded(
                     child: TextButton(
                       onPressed: () => Navigator.pop(context), 
                       child: const Text('CANCELAR', style: TextStyle(color: Colors.grey))
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: ElevatedButton(
                       onPressed: () => ref.read(scannerStatusProvider.notifier).initiateLinking(),
                       style: ElevatedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       ),
                       child: const Text('ACEPTAR', style: TextStyle(fontWeight: FontWeight.bold)),
                     ),
                   ),
                 ],
               ),
            ],
          ],
        ),
      ),
    );
  }
}
