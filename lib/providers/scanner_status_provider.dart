import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents the current status of the mobile scanner connection.
class ScannerStatus {
  final bool isActive;
  final String? lastBarcode;
  final String? lastProductName;
  final String? lastScanMode; // 'pos' or 'audit'
  final DateTime? lastScanTime;

  const ScannerStatus({
    this.isActive = false,
    this.lastBarcode,
    this.lastProductName,
    this.lastScanMode,
    this.lastScanTime,
  });

  ScannerStatus copyWith({
    bool? isActive,
    String? lastBarcode,
    String? lastProductName,
    String? lastScanMode,
    DateTime? lastScanTime,
  }) {
    return ScannerStatus(
      isActive: isActive ?? this.isActive,
      lastBarcode: lastBarcode ?? this.lastBarcode,
      lastProductName: lastProductName ?? this.lastProductName,
      lastScanMode: lastScanMode ?? this.lastScanMode,
      lastScanTime: lastScanTime ?? this.lastScanTime,
    );
  }
}

/// Provider that tracks whether a mobile scanner is actively being used.
class ScannerStatusNotifier extends Notifier<ScannerStatus> {
  RealtimeChannel? _channel;
  Timer? _inactivityTimer;

  @override
  ScannerStatus build() {
    _setupListener();
    ref.onDispose(() {
      _channel?.unsubscribe();
      _inactivityTimer?.cancel();
    });
    return const ScannerStatus();
  }

  void _setupListener() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _channel = Supabase.instance.client
        .channel('scanner_status_global')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'barcode_scans',
          callback: (payload) {
            final recordUserId = payload.newRecord['user_id'] as String?;
            
            if (recordUserId != userId) return;

            final barcode = payload.newRecord['barcode'] as String?;
            final productName = payload.newRecord['product_name'] as String?;

            state = ScannerStatus(
              isActive: true,
              lastBarcode: barcode,
              lastProductName: productName,
              lastScanMode: 'pos', // Forzamos POS por ahora
              lastScanTime: DateTime.now(),
            );

            _inactivityTimer?.cancel();
            _inactivityTimer = Timer(const Duration(seconds: 30), () {
              state = state.copyWith(isActive: false);
            });
          },
        );

    _channel?.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        // We don't set isActive to true here because 'subscribed' only means 
        // the PC is listening, not that a phone is actively scanning.
        debugPrint('Scanner bridge: Subscribed and listening...');
      } else if (status == RealtimeSubscribeStatus.closed || status == RealtimeSubscribeStatus.channelError) {
        state = state.copyWith(isActive: false);
      }
    });
  }
}

final scannerStatusProvider =
    NotifierProvider<ScannerStatusNotifier, ScannerStatus>(
  () => ScannerStatusNotifier(),
);
