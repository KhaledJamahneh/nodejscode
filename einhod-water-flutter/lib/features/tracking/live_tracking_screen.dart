// lib/features/tracking/live_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class LiveTrackingScreen extends StatefulWidget {
  final String deliveryId;
  final String workerName;

  const LiveTrackingScreen({
    super.key,
    required this.deliveryId,
    required this.workerName,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  LatLng _workerLocation = const LatLng(31.9539, 35.9106); // Amman
  LatLng _clientLocation = const LatLng(31.9566, 35.9457);
  int _etaMinutes = 15;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTracking() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      // Simulate location updates
      setState(() {
        _etaMinutes = (_etaMinutes - 1).clamp(0, 60);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Delivery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              // Call worker
            },
          ),
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              // Message worker
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _workerLocation,
              zoom: 14,
            ),
            onMapCreated: (c) => _mapController = c,
            markers: {
              Marker(
                markerId: const MarkerId('worker'),
                position: _workerLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                infoWindow: InfoWindow(title: widget.workerName),
              ),
              Marker(
                markerId: const MarkerId('client'),
                position: _clientLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: const InfoWindow(title: 'Your Location'),
              ),
            },
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_shipping, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          widget.workerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Arriving in $_etaMinutes minutes',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    if (_etaMinutes <= 5) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Driver is nearby!'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
