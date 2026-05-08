import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primaryColor = cs.primary;
    final sidebarBg = Theme.of(context).brightness == Brightness.dark 
        ? cs.surfaceContainerHigh 
        : primaryColor;

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
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildItem(context, Icons.point_of_sale, 'Punto de Venta', 'pos'),
                _buildItem(context, Icons.inventory_2_outlined, 'Inventario', 'inventory'),
                _buildItem(context, Icons.history, 'Historial de Ventas', 'history'),
                _buildItem(context, Icons.bar_chart, 'Reportes', 'reports'),
                _buildItem(context, Icons.assignment_return_outlined, 'Devoluciones', 'returns'),
                _buildItem(context, Icons.qr_code_scanner, 'Escáner Móvil', 'scanner'),
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