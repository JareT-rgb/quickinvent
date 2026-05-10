import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class SafeHaptic {
  static Future<void> lightImpact() async {
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        await HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  static Future<void> mediumImpact() async {
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }

  static Future<void> heavyImpact() async {
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }

  static Future<void> selectionClick() async {
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        await HapticFeedback.selectionClick();
      }
    } catch (_) {}
  }

  static Future<void> vibrate() async {
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        await HapticFeedback.vibrate();
      }
    } catch (_) {}
  }
}
