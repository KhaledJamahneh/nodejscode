// lib/features/location/presentation/providers/location_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';
import '../../data/location_api_service.dart';

// ─── Service Provider ─────────────────────────────────────────────────────────

final locationApiServiceProvider = Provider<LocationApiService>((ref) {
  return LocationApiService();
});

// ─── Worker: Live Location Tracking ──────────────────────────────────────────

/// State for the worker's location tracker.
class WorkerTrackingState {
  final bool isTracking;
  final double? lastLatitude;
  final double? lastLongitude;
  final String? error;
  final int? activeDeliveryId;

  const WorkerTrackingState({
    this.isTracking = false,
    this.lastLatitude,
    this.lastLongitude,
    this.error,
    this.activeDeliveryId,
  });

  WorkerTrackingState copyWith({
    bool? isTracking,
    double? lastLatitude,
    double? lastLongitude,
    String? error,
    int? activeDeliveryId,
  }) {
    return WorkerTrackingState(
      isTracking: isTracking ?? this.isTracking,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      error: error,
      activeDeliveryId: activeDeliveryId ?? this.activeDeliveryId,
    );
  }
}

/// Manages periodic location upload for the delivery worker.
///
/// Start tracking when a delivery begins → stop when it completes.
/// Pushes location to the backend every 30 seconds.
class WorkerLocationTracker extends StateNotifier<WorkerTrackingState> {
  final LocationApiService _api;
  Timer? _periodicTimer;
  static const _interval = Duration(seconds: 30);

  WorkerLocationTracker(this._api) : super(const WorkerTrackingState());

  /// Begin uploading location for [deliveryId].
  /// Does nothing if already tracking the same delivery.
  Future<void> startTracking(int deliveryId) async {
    if (state.isTracking && state.activeDeliveryId == deliveryId) return;

    stopTracking();
    state = state.copyWith(
        isTracking: true, activeDeliveryId: deliveryId, error: null);

    // Immediately send one location update
    await _sendLocation(deliveryId);

    // Then keep sending every 30 seconds
    _periodicTimer = Timer.periodic(_interval, (_) async {
      await _sendLocation(deliveryId);
    });
  }

  /// Stop uploading — call when delivery completes or GPS is toggled off.
  void stopTracking() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    state = const WorkerTrackingState();
  }

  Future<void> _sendLocation(int deliveryId) async {
    final result = await LocationService.getCurrentPosition();
    if (result.isSuccess) {
      try {
        await _api.updateWorkerLocation(
          latitude: result.latitude!,
          longitude: result.longitude!,
          activeDeliveryId: deliveryId,
        );
        state = state.copyWith(
          lastLatitude: result.latitude,
          lastLongitude: result.longitude,
          error: null,
        );
      } catch (_) {
        // Silently ignore API errors — worker continues tracking
      }
    } else {
      state = state.copyWith(error: result.error);
    }
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

final workerLocationTrackerProvider =
    StateNotifierProvider<WorkerLocationTracker, WorkerTrackingState>((ref) {
  return WorkerLocationTracker(ref.read(locationApiServiceProvider));
});

// ─── Client: Home Location State ─────────────────────────────────────────────

class ClientHomeLocationState {
  final double? latitude;
  final double? longitude;
  final bool isSaving;
  final String? error;
  final bool isSaved;

  bool get hasLocation => latitude != null && longitude != null;

  const ClientHomeLocationState({
    this.latitude,
    this.longitude,
    this.isSaving = false,
    this.error,
    this.isSaved = false,
  });

  ClientHomeLocationState copyWith({
    double? latitude,
    double? longitude,
    bool? isSaving,
    String? error,
    bool? isSaved,
  }) {
    return ClientHomeLocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

class ClientHomeLocationNotifier
    extends StateNotifier<ClientHomeLocationState> {
  final LocationApiService _api;

  ClientHomeLocationNotifier(this._api,
      {double? initialLat, double? initialLng})
      : super(ClientHomeLocationState(
            latitude: initialLat, longitude: initialLng));

  /// Use the device GPS to set and save home location.
  Future<void> setFromCurrentGPS() async {
    state = state.copyWith(isSaving: true, error: null, isSaved: false);
    final result = await LocationService.getCurrentPosition();

    if (!result.isSuccess) {
      state = state.copyWith(isSaving: false, error: result.error);
      return;
    }
    await _persistLocation(result.latitude!, result.longitude!);
  }

  /// Manually supply coordinates (e.g. from text fields).
  Future<void> setManually({required double lat, required double lng}) async {
    state = state.copyWith(isSaving: true, error: null, isSaved: false);
    await _persistLocation(lat, lng);
  }

  Future<void> _persistLocation(double lat, double lng) async {
    try {
      await _api.saveClientHomeLocation(latitude: lat, longitude: lng);
      state = state.copyWith(
        latitude: lat,
        longitude: lng,
        isSaving: false,
        isSaved: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
          isSaving: false, error: 'Failed to save: $e', isSaved: false);
    }
  }
}

/// Seed this provider with the lat/lng already on the ClientProfile
/// so the UI reflects the saved location on first load.
final clientHomeLocationProvider =
    StateNotifierProvider<ClientHomeLocationNotifier, ClientHomeLocationState>(
        (ref) {
  return ClientHomeLocationNotifier(ref.read(locationApiServiceProvider));
});

// ─── Client: Worker Proximity Monitor ────────────────────────────────────────

class ProximityState {
  final bool isMonitoring;
  final double? distanceMeters;
  final ProximityLevel level;
  final WorkerLocationSnapshot? workerSnapshot;
  final String? error;

  bool get isNear =>
      level == ProximityLevel.near || level == ProximityLevel.veryClose;
  bool get isVeryClose => level == ProximityLevel.veryClose;

  const ProximityState({
    this.isMonitoring = false,
    this.distanceMeters,
    this.level = ProximityLevel.distant,
    this.workerSnapshot,
    this.error,
  });

  ProximityState copyWith({
    bool? isMonitoring,
    double? distanceMeters,
    ProximityLevel? level,
    WorkerLocationSnapshot? workerSnapshot,
    String? error,
  }) {
    return ProximityState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      level: level ?? this.level,
      workerSnapshot: workerSnapshot ?? this.workerSnapshot,
      error: error,
    );
  }
}

/// Polls the worker's live location every 30 seconds when monitoring.
/// Calculates distance vs the client's home coordinates.
/// Exposes [ProximityState] so the UI can show appropriate banners.
class ProximityMonitor extends StateNotifier<ProximityState> {
  final LocationApiService _api;
  Timer? _pollTimer;
  static const _pollInterval = Duration(seconds: 30);

  double? _homeLat;
  double? _homeLng;
  int? _deliveryId;
  bool _isRequest = false;

  ProximityMonitor(this._api) : super(const ProximityState());

  /// Start monitoring for [deliveryId] with the client's home at [homeLat]/[homeLng].
  void startMonitoring({
    required int deliveryId,
    required double homeLat,
    required double homeLng,
    bool isRequest = false,
  }) {
    if (state.isMonitoring &&
        _deliveryId == deliveryId &&
        _homeLat == homeLat &&
        _homeLng == homeLng) return;

    _stopTimer();
    _homeLat = homeLat;
    _homeLng = homeLng;
    _deliveryId = deliveryId;
    _isRequest = isRequest;
    state = state.copyWith(isMonitoring: true);

    // First poll immediately
    _poll();

    // Then poll periodically
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  void stopMonitoring() {
    _stopTimer();
    state = const ProximityState();
  }

  Future<void> _poll() async {
    if (_deliveryId == null || _homeLat == null || _homeLng == null) return;

    try {
      WorkerLocationSnapshot? snapshot;

      if (_isRequest) {
        snapshot = await _api.getWorkerLocationForRequest(_deliveryId!);
      } else {
        snapshot = await _api.getWorkerLocationForDelivery(_deliveryId!);
      }

      if (snapshot == null) return; // No live data yet

      final distance = LocationService.distanceInMeters(
        lat1: _homeLat!,
        lon1: _homeLng!,
        lat2: snapshot.latitude,
        lon2: snapshot.longitude,
      );

      state = state.copyWith(
        distanceMeters: distance,
        level: LocationService.proximityLevel(distance),
        workerSnapshot: snapshot,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void _stopTimer() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

final proximityMonitorProvider =
    StateNotifierProvider<ProximityMonitor, ProximityState>((ref) {
  return ProximityMonitor(ref.read(locationApiServiceProvider));
});
