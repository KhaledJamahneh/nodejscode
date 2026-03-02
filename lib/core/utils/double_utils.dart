// lib/core/utils/double_utils.dart

class DoubleUtils {
  /// Safely converts a value to double.
  /// Handles null, num, and String types.
  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return 0.0;
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
