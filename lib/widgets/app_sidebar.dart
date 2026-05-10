import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/scanner_status_provider.dart';
import '../theme/app_theme.dart';

class AppSidebar extends ConsumerWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = AppTheme.primary;
    final sidebarBg = isDark ? theme.cardColor : const Color(0xFF065F46); // Adaptive background

    final scannerStatus = ref.watch(scannerStatusProvider);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
      ),
      child: Column(
        children: [
          // Logo Section with Premium Header
          _buildBrandHeader(primaryColor),
          
          if (scannerStatus.isActive)
            FadeInDown(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _ScannerActiveBanner(scannerStatus: scannerStatus),
              ),
            ),
            
          const SizedBox(height: 12),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSectionLabel('MÓDULOS OPERATIVOS'),
                _buildItem(context, Icons.grid_view_rounded, 'Terminal de Venta', 'pos'),
                _buildItem(context, Icons.inventory_2_rounded, 'Inventario Real', 'inventory'),
                _buildItem(context, Icons.history_rounded, 'Historial de Ventas', 'history'),
                _buildItem(context, Icons.assignment_return_rounded, 'Devoluciones', 'returns'),
                _buildItem(context, Icons.account_balance_wallet_rounded, 'Cierre de Caja', 'cash_cut'),
                
                const SizedBox(height: 28),
                _buildSectionLabel('ESTADÍSTICAS & BI'),
                _buildItem(context, Icons.analytics_rounded, 'Análisis de Negocio', 'reports'),
                _buildItem(context, Icons.people_alt_rounded, 'Cartera de Clientes', 'customers'),
                
                const SizedBox(height: 28),
                _buildSectionLabel('SISTEMA'),
                _buildScannerItem(context, scannerStatus),
                _buildItem(context, Icons.settings_suggest_rounded, 'Configuración', 'settings'),
              ],
            ),
          ),
          
          _buildProfileFooter(context),
        ],
      ),
    );
  }

  Widget _buildBrandHeader(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 60, 24, 32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4), // Reducido para máximo aprovechamiento
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Transform.scale(
                scale: 1.6, // Zoom para eliminar espacios blancos en el sidebar
                child: Image.asset(
                  'assets/logo.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.shopping_cart_checkout_rounded, color: primaryColor, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QuickInvent',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'PREMIUM CLOUD POS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12, top: 4),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.25),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildProfileFooter(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppTheme.radiusMedium,
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'AD',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Master',
                      style: TextStyle(color: theme.textTheme.titleSmall?.color, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.2),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Licencia Vitalicia',
                      style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildItem(context, Icons.logout_rounded, 'Cerrar Sesión', 'logout', isDestructive: true, dense: true),
        ],
      ),
    );
  }

  Widget _buildScannerItem(BuildContext context, ScannerStatus status) {
    final isActive = currentRoute == 'scanner';
    return _buildItem(
      context, 
      Icons.qr_code_scanner_rounded, 
      'Escáner Móvil', 
      'scanner',
      badge: status.isActive ? 'ACTIVO' : null,
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String label, String route, {String? badge, bool isDestructive = false, bool dense = false}) {
    final isActive = currentRoute == route;
    final color = isDestructive 
        ? const Color(0xFFF87171) 
        : (isActive ? Colors.white : Colors.white.withOpacity(0.4));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => onNavigate(route),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: dense ? 10 : 14),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: dense ? 20 : 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: dense ? 13 : 14,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                  ),
                  child: Text(
                    badge, 
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                  ),
                ),
              if (isActive && !isDestructive && badge == null)
                FadeIn(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerActiveBanner extends StatefulWidget {
  final ScannerStatus scannerStatus;
  const _ScannerActiveBanner({required this.scannerStatus});

  @override
  State<_ScannerActiveBanner> createState() => _ScannerActiveBannerState();
}

class _ScannerActiveBannerState extends State<_ScannerActiveBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2 * _pulse.value)),
          ),
          child: Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: _pulse.value),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 8)],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Escáner Remoto Activo',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}