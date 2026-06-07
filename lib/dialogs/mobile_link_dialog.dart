import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_theme.dart';

class MobileLinkDialog extends StatelessWidget {
  const MobileLinkDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                    dataModuleStyle: const QrDataModuleStyle(color: Colors.black87, dataModuleShape: QrDataModuleShape.square),
                    eyeStyle: const QrEyeStyle(color: Colors.black87, eyeShape: QrEyeShape.square),
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
    );
  }
}
