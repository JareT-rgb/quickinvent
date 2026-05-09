import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_prefs_provider.dart';

class AppSettings {
  final String businessName;
  final String businessAddress;
  final String footerMessage;
  final String? logoUrl;
  final double paperWidth; // 58 or 80
  
  // Payment Info
  final String transferName;
  final String transferBank;
  final String transferAccount;

  AppSettings({
    this.businessName = 'QuickInvent',
    this.businessAddress = 'Dirección no configurada',
    this.footerMessage = '¡Gracias por su compra!',
    this.logoUrl,
    this.paperWidth = 80,
    this.transferName = '',
    this.transferBank = '',
    this.transferAccount = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'businessAddress': businessAddress,
      'footerMessage': footerMessage,
      'logoUrl': logoUrl,
      'paperWidth': paperWidth,
      'transferName': transferName,
      'transferBank': transferBank,
      'transferAccount': transferAccount,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      businessName: map['businessName'] ?? 'QuickInvent',
      businessAddress: map['businessAddress'] ?? 'Dirección no configurada',
      footerMessage: map['footerMessage'] ?? '¡Gracias por su compra!',
      logoUrl: map['logoUrl'],
      paperWidth: (map['paperWidth'] as num?)?.toDouble() ?? 80,
      transferName: map['transferName'] ?? '',
      transferBank: map['transferBank'] ?? '',
      transferAccount: map['transferAccount'] ?? '',
    );
  }

  AppSettings copyWith({
    String? businessName,
    String? businessAddress,
    String? footerMessage,
    String? logoUrl,
    double? paperWidth,
    String? transferName,
    String? transferBank,
    String? transferAccount,
  }) {
    return AppSettings(
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      footerMessage: footerMessage ?? this.footerMessage,
      logoUrl: logoUrl ?? this.logoUrl,
      paperWidth: paperWidth ?? this.paperWidth,
      transferName: transferName ?? this.transferName,
      transferBank: transferBank ?? this.transferBank,
      transferAccount: transferAccount ?? this.transferAccount,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _key = 'app_settings';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      try {
        return AppSettings.fromMap(jsonDecode(jsonStr));
      } catch (_) {
        return AppSettings();
      }
    }
    return AppSettings();
  }

  Future<void> updateSettings(AppSettings settings) async {
    state = settings;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, jsonEncode(settings.toMap()));
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(() {
  return AppSettingsNotifier();
});
