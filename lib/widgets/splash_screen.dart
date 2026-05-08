import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() async {
    // Duración del splash antes de pasar a la app
    await Future.delayed(const Duration(milliseconds: 3000));
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animación del logo
            ZoomIn(
              duration: const Duration(milliseconds: 1000),
              child: FadeIn(
                duration: const Duration(milliseconds: 1200),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset('assets/logo.png', errorBuilder: (context, error, stackTrace) {
                    // Fallback por si la imagen no existe aún
                    return const Icon(Icons.inventory_2_rounded, size: 100, color: AppTheme.primary);
                  }),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Nombre de la app animado
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: const Text(
                'QUICKINVENT',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeInUp(
              delay: const Duration(milliseconds: 800),
              child: Text(
                'ABARROTES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
