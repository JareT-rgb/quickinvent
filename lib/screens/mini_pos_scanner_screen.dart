import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:animate_do/animate_do.dart';

import '../providers/app_settings_provider.dart';
import '../theme/app_theme.dart';
import '../repositories/products_repository.dart';
import '../providers/cart_notifier.dart';
import '../dialogs/checkout_dialog.dart';
import '../utils/safe_haptic.dart';
import '../widgets/scanner_overlay.dart';

class MiniPosScannerScreen extends ConsumerStatefulWidget {
  const MiniPosScannerScreen({super.key});

  @override
  ConsumerState<MiniPosScannerScreen> createState() => _MiniPosScannerScreenState();
}

class _MiniPosScannerScreenState extends ConsumerState<MiniPosScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: [BarcodeFormat.all],
  );

  bool _isProcessing = false;
  String? _lastScannedCode;
  String? _currentVisibleCode; // Used for trigger mode
  DateTime? _lastScanTime;
  Map<String, dynamic>? _lastScanResult;

  late AnimationController _laserController;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _triggerManualScan() {
    final settings = ref.read(appSettingsProvider);
    if (!settings.useVolumeKeyToScan) return;
    
    if (_currentVisibleCode != null && !_isProcessing) {
      _lastScannedCode = _currentVisibleCode; // Fix: Set this so UI can clear
      _processScannedCode(_currentVisibleCode!);
    }
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    final settings = ref.read(appSettingsProvider);
    final List<Barcode> barcodes = capture.barcodes;
    
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code == null || code.isEmpty) return;

      if (settings.useVolumeKeyToScan) {
        if (_currentVisibleCode != code) {
          setState(() {
            _currentVisibleCode = code;
          });
        }
        return; // Wait for manual trigger
      }

      // Prevent duplicate scanning too fast
      if (_isProcessing) return;
      if (_lastScannedCode == code && _lastScanTime != null) {
        if (DateTime.now().difference(_lastScanTime!).inSeconds < 2) {
          return; // Ignore same code within 2 seconds
        }
      }

      _lastScannedCode = code;
      _lastScanTime = DateTime.now();

      await _processScannedCode(code);
    } else {
      if (settings.useVolumeKeyToScan && _currentVisibleCode != null) {
        setState(() {
          _currentVisibleCode = null;
        });
      }
    }
  }

  Future<void> _processScannedCode(String code) async {
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _lastScanResult = null;
    });

    try {
      final product = await ref.read(productsRepositoryProvider).getProductByBarcode(code);

      if (product != null) {
        // Add to cart local
        final error = ref.read(cartProvider.notifier).addItem(product);
        if (error == null) {
          SafeHaptic.lightImpact();
          if (mounted) {
            setState(() {
              _lastScanResult = {
                'status': 'success',
                'product': product,
                'message': 'Agregado al carrito',
              };
            });
          }
        } else {
          SafeHaptic.heavyImpact();
          if (mounted) {
            setState(() {
              _lastScanResult = {
                'status': 'error',
                'product': product,
                'message': error,
              };
            });
          }
        }
      } else {
        SafeHaptic.vibrate();
        if (mounted) {
          setState(() {
            _lastScanResult = {
              'status': 'not_found',
              'product': null,
              'message': 'Producto no encontrado',
            };
          });
        }
      }

      // Clear the message after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && (_lastScannedCode == code || _currentVisibleCode == code)) {
          setState(() {
            _lastScanResult = null;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _startCheckout() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final total = cart.fold<double>(0, (sum, item) => sum + item.subtotal);
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CheckoutDialog(
          cartItems: cart,
          totalAmount: total,
          onComplete: () {
            ref.read(cartProvider.notifier).clearCart();
            // Pops the MiniPosScannerScreen back to POS
            Navigator.of(context).pop();
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildCartBottomSheet(),
    );
  }

  Widget _buildCartBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 16),
              const Text('Resumen del Carrito', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final cart = ref.watch(cartProvider);
                    if (cart.isEmpty) {
                      return const Center(child: Text('El carrito está vacío', style: TextStyle(color: Colors.grey)));
                    }
                    return ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: cart.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('\$${item.product.price} c/u'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppTheme.error),
                                onPressed: () {
                                  if (item.quantity == 1) {
                                    ref.read(cartProvider.notifier).removeItem(item.product.id);
                                  } else {
                                    ref.read(cartProvider.notifier).decrementQuantity(item.product.id);
                                  }
                                },
                              ),
                              Text('${item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                                onPressed: () {
                                  final error = ref.read(cartProvider.notifier).incrementQuantity(item.product.id);
                                  if (error != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final totalItems = cart.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalAmount = cart.fold<double>(0, (sum, item) => sum + item.subtotal);

    final scanWidth = MediaQuery.of(context).size.width * 0.85;
    final scanHeight = scanWidth * 0.45;
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(const Offset(0, -80)),
      width: scanWidth,
      height: scanHeight,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            scanWindow: scanWindow,
            controller: _controller,
            onDetect: _handleBarcode,
          ),
          
          // Scanner Overlay with Laser
          _buildScannerOverlay(),

          // Top Toolbar
          _buildTopToolbar(),

          // Feedback Message (Center)
          if (_lastScanResult != null)
            Center(
              child: FadeInUp(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: _lastScanResult!['status'] == 'success' 
                        ? AppTheme.primary.withValues(alpha: 0.9) 
                        : AppTheme.error.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: AppTheme.deepShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _lastScanResult!['status'] == 'success' ? Icons.check_circle : Icons.warning_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_lastScanResult!['product'] != null)
                            Text(
                              _lastScanResult!['product'].name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          Text(
                            _lastScanResult!['message'],
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_isProcessing && _lastScanResult == null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: const BoxDecoration(color: Colors.black54),
                  child: const CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 5),
                ),
              ),
            ),

          // Cart Summary / Checkout Button (Bottom)
          Positioned(
            bottom: 20, left: 16, right: 16,
            child: _buildCartSummary(totalItems, totalAmount),
          ),

          // Trigger Button (Highest Z-index)
          if (ref.watch(appSettingsProvider).useVolumeKeyToScan)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 260), // Raised significantly to avoid the cart summary modal
                child: GestureDetector(
                  onTap: _triggerManualScan,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: _currentVisibleCode != null ? AppTheme.primaryGradient : null,
                      color: _currentVisibleCode != null ? null : Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24),
                      boxShadow: [
                        if (_currentVisibleCode != null)
                          BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 1)
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.barcode_reader, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _currentVisibleCode != null ? 'ESCANEAR' : 'BUSCANDO...',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return AnimatedBuilder(
      animation: _laserController,
      builder: (context, child) {
        final scanWidth = MediaQuery.of(context).size.width * 0.85;
        final scanHeight = scanWidth * 0.45; // Aspect ratio of barcode

        return Stack(
          children: [
            Container(
              decoration: ShapeDecoration(
                shape: QrScannerOverlayShape(
                  borderColor: Colors.transparent,
                  overlayColor: Colors.black.withValues(alpha: 0.6),
                  borderRadius: 30,
                  borderLength: 0,
                  borderWidth: 0,
                  cutOutWidth: scanWidth,
                  cutOutHeight: scanHeight,
                  cutOutBottomOffset: 80, // Offset a bit to account for bottom panel
                ),
              ),
            ),
            Center(
              child: Transform.translate(
                offset: const Offset(0, -80), // Match the cutOutBottomOffset
                child: SizedBox(
                  width: scanWidth,
                  height: scanHeight,
                  child: CustomPaint(
                    painter: ScannerVisorPainter(
                      color: AppTheme.primary,
                      laserPosition: _laserController.value,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopToolbar() {
    return Positioned(
      top: 50, left: 16, right: 16,
      child: FadeInDown(
        child: Row(
          children: [
            // Exit Button (Left)
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
              ),
            ),
            
            const Spacer(),
            
            // Camera Tools (Right)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _controller.toggleTorch(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                      child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _controller.switchCamera(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                      child: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(int totalItems, double totalAmount) {
    final hasItems = totalItems > 0;

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppTheme.deepShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shopping_cart_rounded, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasItems ? '$totalItems artículos' : 'Carrito vacío', 
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.textPrimary),
                      ),
                      Text(
                        hasItems ? 'Total: \$${totalAmount.toStringAsFixed(2)}' : 'Escanea un producto para comenzar', 
                        style: TextStyle(color: hasItems ? AppTheme.primary : AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (hasItems) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _showCartBottomSheet,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('VER Y EDITAR CARRITO', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _startCheckout,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('COBRAR AHORA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
