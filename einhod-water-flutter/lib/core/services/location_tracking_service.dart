// lib/core/services/location_tracking_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class LocationTrackingService {
  static StreamSubscription<Position>? _positionStream;
  static final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  static final Battery _battery = Battery();
  static bool _isTracking = false;

  static Future<bool> startTracking() async {
    print('🔍 startTracking called');
    if (_isTracking) {
      print('⚠️ Already tracking');
      return true;
    }

    // Check if GPS is enabled first
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('📍 GPS enabled: $serviceEnabled');
    if (!serviceEnabled) {
      print('❌ GPS is OFF - returning false');
      return false;
    }

    final token = await StorageService.getAccessToken();
    if (token == null) {
      print('❌ No token - returning false');
      return false;
    }

    _dio.options.headers['Authorization'] = 'Bearer $token';

    // Check and request permission
    LocationPermission permission = await Geolocator.checkPermission();
    print('🔐 Current permission: $permission');
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print('🔐 After request permission: $permission');
      if (permission == LocationPermission.denied) {
        print('❌ Permission denied - returning false');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Permission denied forever - returning false');
      return false;
    }

    _isTracking = true;
    print('✅ Starting location stream');

    // Battery-aware adaptive location tracking (2026 best practice)
    final batteryLevel = await _battery.batteryLevel;
    final LocationSettings settings;
    
    if (batteryLevel > 50) {
      // High battery: High accuracy for best UX
      settings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50m
      );
      print('🔋 Battery $batteryLevel% - High accuracy mode');
    } else if (batteryLevel > 20) {
      // Medium battery: Balanced mode
      settings = const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 100, // Update every 100m
      );
      print('🔋 Battery $batteryLevel% - Balanced mode');
    } else {
      // Low battery: Power saving mode
      settings = const LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 200, // Update every 200m
      );
      print('🔋 Battery $batteryLevel% - Power saving mode');
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((Position position) {
      _updateLocation(position);
    });

    return true;
  }

  static Future<void> _updateLocation(Position position) async {
    try {
      await _dio.post('/location/update', data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      });
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  static void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
  }

  static bool get isTracking => _isTracking;
}
