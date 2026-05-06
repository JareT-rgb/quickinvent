import 'package:flutter/material.dart';
import 'app_sidebar.dart';
import 'pos_screen.dart';
import 'inventory_screen.dart';
import 'sales_history_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'returns_screen.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _currentRoute = 'pos';

  Widget _getCurrentView() {
    switch (_currentRoute) {
      case 'pos':
        return const PosScreen();
      case 'inventory':
        return const InventoryScreen();
      case 'history':
        return const SalesHistoryScreen();
      case 'reports':
        return const ReportsScreen();
      case 'settings':
        return const SettingsScreen();
      case 'returns':
        return const ReturnsScreen();
      default:
        return const PosScreen();
    }
  }

  void _onNavigate(String route) {
    if (route == 'logout') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      return;
    }
    setState(() {
      _currentRoute = route;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          AppSidebar(
            currentRoute: _currentRoute,
            onNavigate: _onNavigate,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _getCurrentView(),
            ),
          ),
        ],
      ),
    );
  }
}
