// lib/core/services/location_tracking_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class LocationTrackingService {
  static StreamSubscription<Position>? _positionStream;
  static final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
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

    // Update location every 30 seconds
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
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
