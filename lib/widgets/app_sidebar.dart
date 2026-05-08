import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scanner_status_provider.dart';

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
    final cs = Theme.of(context).colorScheme;
    final primaryColor = cs.primary;
    final sidebarBg = Theme.of(context).brightness == Brightness.dark 
        ? cs.surfaceContainerHigh 
        : primaryColor;

    final scannerStatus = ref.watch(scannerStatusProvider);

    return Container(
      width: 260,
      color: sidebarBg,
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo QuickInvent
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.shopping_cart, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QUICKINVENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('ABARROTES', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 2)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Scanner status banner (visible only on desktop/tablet)
          if (scannerStatus.isActive)
            _ScannerActiveBanner(scannerStatus: scannerStatus),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildItem(context, Icons.point_of_sale, 'Punto de Venta', 'pos'),
                _buildItem(context, Icons.inventory_2_outlined, 'Inventario', 'inventory'),
                _buildItem(context, Icons.history, 'Historial de Ventas', 'history'),
                _buildItem(context, Icons.bar_chart, 'Reportes', 'reports'),
                _buildItem(context, Icons.assignment_return_outlined, 'Devoluciones', 'returns'),
                _buildScannerItem(context, scannerStatus),
                _buildItem(context, Icons.point_of_sale_outlined, 'Corte de Caja', 'cash_cut'),
                _buildItem(context, Icons.settings, 'Configuración', 'settings'),
              ],
            ),
          ),
          // Perfil Admin
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF8BC34A),
                  child: Text('A', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('Encargado', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          _buildItem(context, Icons.logout, 'Cerrar sesión', 'logout', isDestructive: true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildScannerItem(BuildContext context, ScannerStatus status) {
    final isActive = currentRoute == 'scanner';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: () => onNavigate('scanner'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        leading: Stack(
          children: [
            Icon(
              Icons.qr_code_scanner,
              color: isActive ? Colors.white : Colors.white60,
            ),
            if (status.isActive)
              Positioned(
                right: 0,
                top: 0,
                child: _PulsingDot(),
              ),
          ],
        ),
        title: Text(
          'Escáner Móvil',
          style: TextStyle(
            color: isActive ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.white60),
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: status.isActive
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ACTIVO',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            : null,
        dense: true,
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String label, String route, {String? badge, bool isDestructive = false}) {
    final isActive = currentRoute == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: () => onNavigate(route),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        leading: Icon(
          icon,
          color: isDestructive ? Colors.redAccent : (isActive ? Colors.white : Colors.white60),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isDestructive ? Colors.redAccent : (isActive ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.white60)),
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFFE91E63), shape: BoxShape.circle),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            : null,
        dense: true,
      ),
    );
  }
}

/// Animated pulsing green dot to indicate scanner is active.
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: _animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: _animation.value * 0.5),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Banner shown at the top of sidebar when scanner is active.
class _ScannerActiveBanner extends StatefulWidget {
  final ScannerStatus scannerStatus;
  const _ScannerActiveBanner({required this.scannerStatus});

  @override
  State<_ScannerActiveBanner> createState() => _ScannerActiveBannerState();
}

class _ScannerActiveBannerState extends State<_ScannerActiveBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.15 * _pulseAnimation.value),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.4 * _pulseAnimation.value),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: _pulseAnimation.value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: _pulseAnimation.value * 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 Escáner conectado',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Recibiendo escaneos',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}