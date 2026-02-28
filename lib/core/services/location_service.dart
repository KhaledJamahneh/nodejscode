// lib/core/services/location_service.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

/// Result wrapper for location operations
class LocationResult {
  final double? latitude;
  final double? longitude;
  final String? error;
  bool get isSuccess => latitude != null && longitude != null;

  const LocationResult({this.latitude, this.longitude, this.error});
  const LocationResult.error(String msg)
      : latitude = null,
        longitude = null,
        error = msg;
}

/// Core GPS + distance utilities.
class LocationService {
  // ─── Proximity Thresholds ─────────────────────────────────────────────────
  /// Worker is "near" when within this radius (metres). Triggers notification.
  static const double nearThresholdMeters = 500.0;

  /// Worker is "very close" when within this radius. Triggers urgent banner.
  static const double veryCloseThresholdMeters = 150.0;

  // ─── Internal Config ──────────────────────────────────────────────────────
  static const int _maxRetries = 3;
  static const Duration _firstAttemptTimeout = Duration(seconds: 15);
  static const Duration _retryTimeout = Duration(seconds: 30);
  static const Duration _retryDelay = Duration(seconds: 2);

  // ─── GPS Fetching ─────────────────────────────────────────────────────────

  /// Request permission and fetch current device position, with retry/backoff.
  static Future<LocationResult> getCurrentPosition() async {
    // 1. Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult.error(
        'Location services are disabled. Please enable GPS in your device settings.',
      );
    }

    // 2. Check & request permission
    final permError = await _ensurePermission();
    if (permError != null) return LocationResult.error(permError);

    // 3. Attempt with retry/backoff
    Exception? lastError;
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final timeout = attempt == 1 ? _firstAttemptTimeout : _retryTimeout;
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: timeout,
        );
        return LocationResult(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } on TimeoutException {
        lastError = TimeoutException(
            'Location request timed out (attempt $attempt/$_maxRetries)');
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt); // exponential backoff
        }
      } catch (e) {
        lastError = Exception(e.toString());
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
        }
      }
    }

    return LocationResult.error(
      'Failed to get location after $_maxRetries attempts. '
      'Check your GPS signal and try again. (${lastError?.toString() ?? "Unknown error"})',
    );
  }

  /// Opens a stream that emits position updates every [distanceFilter] metres.
  static Stream<LocationResult> trackPosition({
    int distanceFilter = 20,
  }) async* {
    // Check permissions first
    final permResult = await _ensurePermission();
    if (permResult != null) {
      yield LocationResult.error(permResult);
      return;
    }

    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
    );

    await for (final position in Geolocator.getPositionStream(
      locationSettings: locationSettings,
    )) {
      yield LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }
  }

  // ─── Distance Calculation (Haversine) ────────────────────────────────────

  /// Returns distance in metres between two coordinates using the
  /// Haversine formula. No packages required — pure math.
  static double distanceInMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Human-readable distance label e.g. "320 m", "1.4 km"
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Estimated minutes of travel at an average walking/driving speed.
  static int estimatedMinutes(double meters, {double speedKmh = 30.0}) {
    final hours = (meters / 1000) / speedKmh;
    return (hours * 60).ceil().clamp(1, 999);
  }

  // ─── Proximity Helpers ────────────────────────────────────────────────────

  static bool isNear(double meters) => meters <= nearThresholdMeters;
  static bool isVeryClose(double meters) => meters <= veryCloseThresholdMeters;

  static ProximityLevel proximityLevel(double meters) {
    if (meters <= veryCloseThresholdMeters) return ProximityLevel.veryClose;
    if (meters <= nearThresholdMeters) return ProximityLevel.near;
    if (meters <= 2000) return ProximityLevel.approaching;
    return ProximityLevel.distant;
  }

  // ─── Private Helpers ─────────────────────────────────────────────────────
  static double _toRadians(double degrees) => degrees * (math.pi / 180);

  /// Returns an error message string if permissions are not granted, or null if OK.
  static Future<String?> _ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'Location permission denied. Please allow location access to use this feature.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Location permission is permanently denied. '
          'Please enable it in your device Settings → App Permissions.';
    }

    return null; // All good
  }
}

enum ProximityLevel {
  distant,
  approaching,
  near,
  veryClose;

  String get label {
    switch (this) {
      case ProximityLevel.distant:
        return 'Far away';
      case ProximityLevel.approaching:
        return 'On the way';
      case ProximityLevel.near:
        return 'Nearby';
      case ProximityLevel.veryClose:
        return 'Arriving now';
    }
  }
}
