import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents the current status of the mobile scanner connection.
class ScannerStatus {
  final bool isActive;
  final String? lastBarcode;
  final String? lastProductName;
  final DateTime? lastScanTime;

  const ScannerStatus({
    this.isActive = false,
    this.lastBarcode,
    this.lastProductName,
    this.lastScanTime,
  });

  ScannerStatus copyWith({
    bool? isActive,
    String? lastBarcode,
    String? lastProductName,
    DateTime? lastScanTime,
  }) {
    return ScannerStatus(
      isActive: isActive ?? this.isActive,
      lastBarcode: lastBarcode ?? this.lastBarcode,
      lastProductName: lastProductName ?? this.lastProductName,
      lastScanTime: lastScanTime ?? this.lastScanTime,
    );
  }
}

/// Provider that tracks whether a mobile scanner is actively being used.
/// It listens for inserts on the `barcode_scans` table via Supabase Realtime.
/// After 30 seconds of inactivity, the status is set to inactive.
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
        .channel('scanner_status_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'barcode_scans',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final barcode = payload.newRecord['barcode'] as String?;
            final productName = payload.newRecord['product_name'] as String?;

            state = ScannerStatus(
              isActive: true,
              lastBarcode: barcode,
              lastProductName: productName,
              lastScanTime: DateTime.now(),
            );

            // Reset after 30 seconds of inactivity
            _inactivityTimer?.cancel();
            _inactivityTimer = Timer(const Duration(seconds: 30), () {
              state = state.copyWith(isActive: false);
            });
          },
        )
        .subscribe();
  }
}

final scannerStatusProvider =
    NotifierProvider<ScannerStatusNotifier, ScannerStatus>(
  () => ScannerStatusNotifier(),
);
