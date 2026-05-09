import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_theme.dart';
import '../screens/scanner_screen.dart';

class ScannerSelectionDialog extends StatelessWidget {
  const ScannerSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ZoomIn(
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: AppTheme.deepShadow,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primary, size: 32),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Seleccionar Escáner',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
                ),
                const SizedBox(height: 8),
                Text(
                  '¿Cómo prefieres escanear tus productos?',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                _ScannerOption(
                  title: 'Usar cámara de este equipo',
                  subtitle: 'Activa la cámara web o trasera de esta PC/Tablet',
                  icon: Icons.camera_alt_rounded,
                  color: AppTheme.primary,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScannerScreen()));
                  },
                ),
                
                const SizedBox(height: 16),
                
                _ScannerOption(
                  title: 'Vincular Teléfono (Control Remoto)',
                  subtitle: 'Escanea con tu celular y los productos aparecerán aquí',
                  icon: Icons.phonelink_setup_rounded,
                  color: AppTheme.accent,
                  onTap: () {
                    Navigator.pop(context);
                    _showMobileLinkInfo(context);
                  },
                ),
                
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMobileLinkInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ZoomIn(
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: AppTheme.deepShadow,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Vincular Móvil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 24),
                  const Text(
                    '1. Inicia sesión con esta misma cuenta en tu celular.\n'
                    '2. Abre el menú lateral y entra a "Escáner".\n'
                    '3. ¡Listo! Todo lo que escanees aparecerá aquí.',
                    style: TextStyle(fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade100, width: 2),
                    ),
                    child: QrImageView(
                      data: 'https://quickinvent.app/scanner',
                      version: QrVersions.auto,
                      size: 180.0,
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Escanea para abrir la App móvil',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('ENTENDIDO', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannerOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ScannerOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        // Small delay to allow the ink ripple to show and avoid mouse tracker errors
        await Future.delayed(const Duration(milliseconds: 150));
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
