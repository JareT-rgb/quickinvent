import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ScannerLinkingState { none, pending, linked }

/// Represents the current status of the mobile scanner connection.
class ScannerStatus {
  final bool isActive;
  final String? lastBarcode;
  final String? lastProductName;
  final String? lastScanMode; // 'pos' or 'audit'
  final DateTime? lastScanTime;
  final int quantityDelta;
  final ScannerLinkingState linkingState;
  final bool hasIncomingRequest;

  const ScannerStatus({
    this.isActive = false,
    this.lastBarcode,
    this.lastProductName,
    this.lastScanMode,
    this.lastScanTime,
    this.quantityDelta = 1,
    this.linkingState = ScannerLinkingState.none,
    this.hasIncomingRequest = false,
  });

  ScannerStatus copyWith({
    bool? isActive,
    String? lastBarcode,
    String? lastProductName,
    String? lastScanMode,
    DateTime? lastScanTime,
    int? quantityDelta,
    ScannerLinkingState? linkingState,
    bool? hasIncomingRequest,
  }) {
    return ScannerStatus(
      isActive: isActive ?? this.isActive,
      lastBarcode: lastBarcode ?? this.lastBarcode,
      lastProductName: lastProductName ?? this.lastProductName,
      lastScanMode: lastScanMode ?? this.lastScanMode,
      lastScanTime: lastScanTime ?? this.lastScanTime,
      quantityDelta: quantityDelta ?? this.quantityDelta,
      linkingState: linkingState ?? this.linkingState,
      hasIncomingRequest: hasIncomingRequest ?? this.hasIncomingRequest,
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
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    // Use a unique channel for this user's scanner bridge
    final channelName = 'scanner_bridge:$userId';
    _channel = client.channel(channelName);

    // 0. Listen for Linking Requests (For Mobile)
    _channel!.onBroadcast(
      event: 'linking_request',
      callback: (payload) {
        final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
        if (isMobile) {
          state = state.copyWith(hasIncomingRequest: true);
        }
      },
    );

    // 1. Listen for Scans with a server-side filter for performance and reliability
    _channel!.onPostgresChanges(
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
        final status = payload.newRecord['status'] as String?;
        final delta = payload.newRecord['quantity_delta'] as int? ?? 1;

        state = ScannerStatus(
          isActive: true, // Activity confirms it's definitely active
          lastBarcode: barcode,
          lastProductName: status == 'audit_view' ? 'AUDIT_MODE' : productName,
          lastScanMode: status == 'audit_view' ? 'audit' : 'pos',
          lastScanTime: DateTime.now(),
          quantityDelta: delta,
        );

        // Keep active status for 60s after a scan
        _inactivityTimer?.cancel();
        _inactivityTimer = Timer(const Duration(seconds: 60), () {
          // Check if presence still says someone is there before setting false
          final presence = _channel?.presenceState();
          if (presence == null || presence.isEmpty) {
            state = state.copyWith(isActive: false);
          }
        });
      },
    );

    // 2. Use Presence to know when the scanner app is actually open
    _channel!.onPresenceSync((_) {
      final presenceState = _channel!.presenceState();
      // If there's more than one member in the channel, it means another device is linked
      // (The PC itself might be one, or we just count all members)
      final hasOtherDevices = presenceState.length > 1;
      
      if (state.isActive != hasOtherDevices) {
        state = state.copyWith(
          isActive: hasOtherDevices,
          linkingState: hasOtherDevices ? ScannerLinkingState.linked : ScannerLinkingState.none,
        );
      }
    }).subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        debugPrint('Scanner bridge: Subscribed to $channelName');
        // Track the PC itself so the phone can see we are listening
        _channel!.track({'device': 'terminal', 'at': DateTime.now().toIso8601String()});
      } else if (error != null) {
        debugPrint('Scanner bridge subscription error: $error');
      }
    });
  }

  void initiateLinking() {
    state = state.copyWith(linkingState: ScannerLinkingState.pending);
    
    // Broadcast a linking request to other devices on the same channel
    // Using dynamic to bypass persistent compilation issues with the enum name in this environment
    final dynamic channel = _channel;
    if (channel != null) {
      channel.send(
        type: (channel as dynamic).subscription.topic == null ? 'broadcast' : 'broadcast', 
        event: 'linking_request',
        payload: {
          'requested_at': DateTime.now().toIso8601String(),
          'from': kIsWeb ? 'web_terminal' : 'desktop_terminal',
        },
      );
    }
  }

  void cancelLinking() {
    state = state.copyWith(linkingState: ScannerLinkingState.none, hasIncomingRequest: false);
  }

  void acceptIncomingRequest() {
    state = state.copyWith(hasIncomingRequest: false);
  }
}

final scannerStatusProvider =
    NotifierProvider<ScannerStatusNotifier, ScannerStatus>(
  () => ScannerStatusNotifier(),
);
