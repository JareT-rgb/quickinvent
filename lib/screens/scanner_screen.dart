import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';

import '../theme/app_theme.dart';
import '../models/product.dart';
import '../repositories/products_repository.dart';
import '../dialogs/edit_product_dialog.dart';
import '../utils/safe_haptic.dart';
import '../widgets/scanner_overlay.dart';


class ScannerScreen extends ConsumerStatefulWidget {
  final bool returnCodeMode;
  final VoidCallback? onClose;
  const ScannerScreen({super.key, this.returnCodeMode = false, this.onClose});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.all],
  );

  bool _isProcessing = false;
  bool _auditMode = false; // Toggle between POS and Audit
  String? _detectedCode;
  Map<String, dynamic>? _lastProduct;
  RealtimeChannel? _feedbackSubscription;

  int _currentScanQty = 1;
  RealtimeChannel? _presenceChannel;

  late AnimationController _laserController;

  @override
  void initState() {
    super.initState();
    _setupFeedbackListener();
    _setupPresence();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _setupPresence() {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final channelName = 'scanner_bridge:$userId';
    _presenceChannel = client.channel(channelName);

    _presenceChannel!.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        _presenceChannel!.track({
          'device': 'mobile_scanner',
          'at': DateTime.now().toIso8601String(),
          'mode': _auditMode ? 'audit' : 'pos',
        });
      } else {
        // Handle disconnection if necessary
      }
    });
  }

  void _setupFeedbackListener() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _feedbackSubscription = Supabase.instance.client
        .channel('public:barcode_scans_feedback')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'barcode_scans',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final status = payload.newRecord['status'] as String?;
            final productName = payload.newRecord['product_name'] as String?;
            final stock = payload.newRecord['stock_quantity'] as num?;
            final price = payload.newRecord['price'] as num?;
            final barcode = payload.newRecord['barcode'] as String?;
            
            // SEGURIDAD: Solo procesamos si coincide con lo que estamos viendo
            if (barcode != _detectedCode) return;

            if (status != null && status != 'pending') {
              // Si ya lo encontramos localmente con éxito, no dejamos que un "not_found" del server lo borre
              if (_lastProduct?['status'] == 'success' && status == 'not_found') {
                return;
              }

              setState(() {
                _lastProduct = {
                  'name': productName ?? _lastProduct?['name'],
                  'stock': stock ?? _lastProduct?['stock'],
                  'price': price ?? _lastProduct?['price'],
                  'barcode': barcode,
                  'status': status,
                  'full_product': _lastProduct?['full_product'],
                };
              });
              _provideFeedback(status);
            }
          },
        )
        .subscribe();
  }

  void _provideFeedback(String status) {
    if (!mounted) return;
    switch (status) {
      case 'success':
        SafeHaptic.lightImpact();
        break;
      case 'not_found':
        SafeHaptic.vibrate();
        break;
      case 'out_of_stock':
        SafeHaptic.heavyImpact();
        break;
    }
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty && code != _detectedCode) {
        setState(() {
          _detectedCode = code;
        });
        SafeHaptic.selectionClick();
      }
    }
  }

  Future<void> _processDetectedCode() async {
    if (_detectedCode == null || _isProcessing) return;

    if (widget.returnCodeMode) {
      Navigator.pop(context, _detectedCode);
      return;
    }

    final isSameProduct = _lastProduct != null && _lastProduct!['barcode'] == _detectedCode;

    setState(() {
      _isProcessing = true;
      if (!isSameProduct) {
        _lastProduct = null;
        _currentScanQty = 1;
      }
    });

    try {
      // Play beep sound (don't await so it doesn't block processing)
      // On web, this might throw UnimplementedError if not handled carefully
      try {

      } catch (_) {
        // Silently ignore if audio fails
      }

      // Buscamos el producto localmente para asegurar que la info sea correcta y evitar errores falsos
      final product = await ref.read(productsRepositoryProvider).getProductByBarcode(_detectedCode!);
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (product != null) {
        if (isSameProduct) {
          if (_currentScanQty + 1 > product.stockQuantity) {
            _provideFeedback('out_of_stock');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Stock máximo alcanzado (${product.stockQuantity})'),
                  backgroundColor: AppTheme.error,
                  duration: const Duration(seconds: 1),
                ),
              );
              setState(() {
                _isProcessing = false;
              });
            }
            return;
          }
          setState(() {
            _currentScanQty++;
          });
        }

        setState(() {
          _lastProduct = {
            'id': product.id,
            'name': product.name,
            'stock': product.stockQuantity,
            'price': product.price,
            'barcode': product.barcode,
            'status': 'success',
            'full_product': product,
          };
        });
        
        if (!_auditMode && userId != null) {
          // Enviamos el incremento de +1
          await Supabase.instance.client.from('barcode_scans').insert({
            'barcode': _detectedCode,
            'user_id': userId,
            'quantity': 1,
            'processed': false,
            'status': 'pending',
          });
        }
        _provideFeedback('success');
      } else {
        // Solo si realmente no existe en la DB mostramos el error
        setState(() {
          _lastProduct = {
            'name': null,
            'barcode': _detectedCode,
            'status': 'not_found',
          };
        });
        _provideFeedback('not_found');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    _presenceChannel?.unsubscribe();
    _feedbackSubscription?.unsubscribe();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanWidth = MediaQuery.of(context).size.width * 0.85;
    final scanHeight = scanWidth * 0.45;
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
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

          // Product Info Card (Bottom)
          if (_lastProduct != null)
            Positioned(
              bottom: 20, left: 16, right: 16,
              child: _buildProductCard(),
            ),
          
          if (_isProcessing && _lastProduct == null)
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
            
          // Manual Scan Trigger Button (Highest Z-index)
          _buildManualScanButton(),
        ],
      ),
    );
  }

  Widget _buildManualScanButton() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: _lastProduct != null ? 550 : 160, // Move extremely high up to avoid modal
      left: 0, right: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _processDetectedCode,
              child: _buildScanPill(),
            ),
            if (_detectedCode != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: FadeIn(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      'Detectado: $_detectedCode',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanPill() {
    final hasCode = _detectedCode != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: hasCode ? AppTheme.primaryGradient : null,
        color: hasCode ? null : Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          if (hasCode)
            BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 1),
        ],
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasCode ? Icons.barcode_reader : Icons.center_focus_weak, 
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            hasCode ? (widget.returnCodeMode ? 'ACEPTAR' : 'TOMAR CÓDIGO') : 'BUSCANDO CÓDIGO...',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Positioned(
      top: 50, left: 16, right: 16,
      child: FadeInDown(
        child: Row(
          children: [
            // Exit Button (Left)
            _CircleButton(
              icon: Icons.close_rounded, 
              onTap: () {
                if (widget.onClose != null) {
                  widget.onClose!();
                } else {
                  Navigator.pop(context);
                }
              },
              isGlass: true,
            ),
            
            const Spacer(),
            
            // Mode Indicator (Center)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: AppTheme.glassDecoration(isDark: true).copyWith(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _auditMode ? Icons.inventory_2_rounded : Icons.shopping_cart_rounded, 
                    size: 14, color: AppTheme.primaryLight
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _auditMode ? 'AUDITORÍA' : 'POS',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: _auditMode,
                      onChanged: (val) {
                        setState(() {
                          _auditMode = val;
                          _lastProduct = null;
                        });
                        _presenceChannel?.track({
                          'device': 'mobile_scanner',
                          'at': DateTime.now().toIso8601String(),
                          'mode': val ? 'audit' : 'pos',
                        });
                      },
                      activeThumbColor: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Camera Tools (Right)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: AppTheme.glassDecoration(isDark: true).copyWith(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.flash_on_rounded, 
                    onTap: () => _controller.toggleTorch(),
                    isGlass: false, // Inside glass container
                    isSmall: true,
                  ),
                  const SizedBox(width: 4),
                  _CircleButton(
                    icon: Icons.flip_camera_ios, 
                    onTap: () => _controller.switchCamera(),
                    isGlass: false, // Inside glass container
                    isSmall: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard() {
    final status = _lastProduct!['status'];
    final isError = status == 'not_found' || status == 'out_of_stock';
    final product = _lastProduct!['full_product'] as Product?;
    
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassDecoration(isDark: false).copyWith(
              borderRadius: BorderRadius.circular(28),
              color: Colors.white.withValues(alpha: 0.98),
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
                        color: (isError ? AppTheme.error : AppTheme.primary).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isError ? Icons.warning_rounded : Icons.check_circle_rounded, 
                        color: isError ? AppTheme.error : AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lastProduct!['name'] ?? 'Código: ${_lastProduct!['barcode']}', 
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.textPrimary, letterSpacing: -0.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (!isError)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                'Stock: ${_lastProduct!['stock']} • \$${_lastProduct!['price']}', 
                                style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                          if (isError)
                            Text(
                              status == 'not_found' ? 'No registrado' : 'Sin existencias', 
                              style: const TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 30), // Space for close button
                  ],
                ),
                if (!isError && !_auditMode) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildQuantitySelector()),
                      const SizedBox(width: 10),
                      _ActionButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'BORRAR',
                        color: AppTheme.error,
                        onTap: () {
                          _updateRemoteQty(-999);
                          setState(() {
                            _lastProduct = null;
                            _detectedCode = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickAction('+5', 5),
                        const SizedBox(width: 8),
                        _buildQuickAction('+10', 10),
                        const SizedBox(width: 8),
                        _buildQuickAction('+20', 20),
                        const SizedBox(width: 8),
                        _buildQuickAction('+50', 50),
                      ],
                    ),
                  ),
                ],
                if (_auditMode && !isError && product != null) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openEditDialog(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      label: const Text('EDITAR PRODUCTO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Botón Cerrar (X)
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => setState(() {
                _lastProduct = null;
                _detectedCode = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 20, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditDialog(Product product) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditProductDialog(product: product),
    );
    
    if (result == true) {
      // Si se editó con éxito, actualizamos la vista local
      final updatedProduct = await ref.read(productsRepositoryProvider).getProductByBarcode(product.barcode!);
      if (updatedProduct != null && mounted) {
        setState(() {
          _lastProduct = {
            'id': updatedProduct.id,
            'name': updatedProduct.name,
            'stock': updatedProduct.stockQuantity,
            'price': updatedProduct.price,
            'barcode': updatedProduct.barcode,
            'status': 'success',
            'full_product': updatedProduct,
          };
        });
      }
    }
  }

  Future<void> _updateRemoteQty(int delta) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _lastProduct == null) return;
    
    SafeHaptic.selectionClick();
    // Enviamos el registro con la cantidad seleccionada
    await Supabase.instance.client.from('barcode_scans').insert({
      'barcode': _lastProduct!['barcode'],
      'user_id': userId,
      'quantity': delta,
      'processed': false,
      'status': 'pending', // Esencial para que el POS lo procese
    });
  }

  Widget _buildScannerOverlay() {
    return AnimatedBuilder(
      animation: _laserController,
      builder: (context, child) {
        final scanWidth = MediaQuery.of(context).size.width * 0.85;
        final scanHeight = scanWidth * 0.45;

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
                ),
              ),
            ),
            Center(
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
          ],
        );
      },
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _QtyControl(
            icon: Icons.remove_rounded,
            onTap: () {
              if (_currentScanQty > 1) {
                setState(() => _currentScanQty--);
                _updateRemoteQty(-1);
              }
            },
          ),
          Expanded(
            child: InkWell(
              onTap: _showManualQuantityDialog,
              borderRadius: BorderRadius.circular(10),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: Text(
                    '$_currentScanQty',
                    key: ValueKey(_currentScanQty),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary),
                  ),
                ),
              ),
            ),
          ),
          _QtyControl(
            icon: Icons.add_rounded,
            onTap: () {
              final maxStock = (_lastProduct?['stock'] as num?)?.toInt() ?? 0;
              if (_currentScanQty < maxStock) {
                setState(() => _currentScanQty++);
                _updateRemoteQty(1);
              } else {
                SafeHaptic.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Stock máximo alcanzado ($maxStock)'),
                    backgroundColor: AppTheme.error,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, int delta) {
    return InkWell(
      onTap: () {
        final maxStock = (_lastProduct?['stock'] as num?)?.toInt() ?? 0;
        final availableToAdd = maxStock - _currentScanQty;
        
        if (availableToAdd <= 0) {
          SafeHaptic.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stock máximo alcanzado ($maxStock)'),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 1),
            ),
          );
          return;
        }

        final actualDelta = delta > availableToAdd ? availableToAdd : delta;
        setState(() => _currentScanQty += actualDelta);
        _updateRemoteQty(actualDelta);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  void _showManualQuantityDialog() {
    final controller = TextEditingController(text: _currentScanQty.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingresar Cantidad'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          FilledButton(
            onPressed: () {
              final newQty = int.tryParse(controller.text) ?? 1;
              final maxStock = (_lastProduct?['stock'] as num?)?.toInt() ?? 0;
              
              if (newQty > 0) {
                if (newQty > maxStock) {
                  SafeHaptic.heavyImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Stock máximo es $maxStock unidades'),
                      backgroundColor: AppTheme.error,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return; // Don't close dialog, let them fix it
                }
                
                final delta = newQty - _currentScanQty;
                if (delta != 0) {
                  setState(() => _currentScanQty = newQty);
                  _updateRemoteQty(delta);
                }
              }
              Navigator.pop(context);
            },
            child: const Text('ACEPTAR'),
          ),
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  const _QtyControl({required this.icon, required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? AppTheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: isPrimary ? Colors.white : AppTheme.primary),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isGlass;
  final bool isSmall;

  const _CircleButton({
    required this.icon, 
    required this.onTap, 
    this.isGlass = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmall ? 8 : 12),
        decoration: isGlass 
            ? BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              )
            : const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: isSmall ? 18 : 22),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
