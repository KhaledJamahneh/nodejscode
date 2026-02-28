import 'package:flutter/services.dart';

class HapticService {
  /// Light haptic feedback for navigation or minor interactions
  static Future<void> light() async => await HapticFeedback.lightImpact();

  /// Medium haptic feedback for standard interactions
  static Future<void> medium() async => await HapticFeedback.mediumImpact();

  /// Heavy haptic feedback for significant events
  static Future<void> heavy() async => await HapticFeedback.heavyImpact();

  /// Selection feedback (like a tick)
  static Future<void> selection() async => await HapticFeedback.selectionClick();

  /// Success pattern: medium tap followed by a light tap
  static Future<void> success() async {
    await medium();
    await Future.delayed(const Duration(milliseconds: 100));
    await light();
  }

  /// Error pattern: two heavy taps
  static Future<void> error() async {
    await heavy();
    await Future.delayed(const Duration(milliseconds: 50));
    await heavy();
  }

  /// Warning pattern: three light taps
  static Future<void> warning() async {
    for (int i = 0; i < 3; i++) {
      await light();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Custom pattern for delivery arrival (simulated heartbeat)
  static Future<void> heartbeat() async {
    await heavy();
    await Future.delayed(const Duration(milliseconds: 100));
    await heavy();
  }
}
