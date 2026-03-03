# WebSocket Implementation Plan (B-14)

**Estimated Time:** 4-6 hours  
**Priority:** Medium (polling works, but WebSocket is better for real-time)  
**Status:** ⏸️ Deferred

---

## Overview

Replace polling-based GPS tracking with WebSocket push for real-time delivery tracking.

---

## Backend Implementation

### 1. Install Dependencies
```bash
npm install socket.io
```

### 2. Update server.js
```javascript
const http = require('http');
const socketIo = require('socket.io');

const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: process.env.CORS_ORIGIN?.split(',') || '*',
    credentials: true
  }
});

// Socket.IO middleware for authentication
io.use(async (socket, next) => {
  const token = socket.handshake.auth.token;
  if (!token) return next(new Error('Authentication error'));
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    socket.userId = decoded.id;
    socket.role = decoded.role;
    next();
  } catch (err) {
    next(new Error('Authentication error'));
  }
});

// Socket.IO connection handler
io.on('connection', (socket) => {
  console.log(`User connected: ${socket.userId}`);
  
  // Worker joins their own room
  if (socket.role === 'delivery_worker') {
    socket.join(`worker_${socket.userId}`);
  }
  
  // Client joins delivery room
  socket.on('join_delivery', (deliveryId) => {
    socket.join(`delivery_${deliveryId}`);
  });
  
  // Worker sends location update
  socket.on('location_update', async (data) => {
    const { deliveryId, latitude, longitude, accuracy } = data;
    
    // Save to database
    await query(
      'UPDATE worker_locations SET latitude = $1, longitude = $2, accuracy = $3, updated_at = NOW() WHERE user_id = $4',
      [latitude, longitude, accuracy, socket.userId]
    );
    
    // Broadcast to clients tracking this delivery
    io.to(`delivery_${deliveryId}`).emit('worker_location', {
      latitude,
      longitude,
      accuracy,
      timestamp: new Date().toISOString()
    });
  });
  
  socket.on('disconnect', () => {
    console.log(`User disconnected: ${socket.userId}`);
  });
});

// Change app.listen to server.listen
server.listen(PORT, () => {
  logger.info(`Server running on port ${PORT}`);
});
```

---

## Frontend Implementation

### 1. Add Dependencies
```yaml
# pubspec.yaml
dependencies:
  socket_io_client: ^2.0.3+1
```

### 2. Create Socket Service
```dart
// lib/core/services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'storage_service.dart';
import '../config/api_config.dart';

class SocketService {
  static IO.Socket? _socket;
  
  static Future<void> connect() async {
    final token = await StorageService.getAccessToken();
    if (token == null) return;
    
    _socket = IO.io(
      ApiConfig.baseUrl.replaceAll('/api/v1', ''),
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .build()
    );
    
    _socket!.connect();
    
    _socket!.onConnect((_) {
      print('Socket connected');
    });
    
    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });
  }
  
  static void joinDelivery(int deliveryId) {
    _socket?.emit('join_delivery', deliveryId);
  }
  
  static void sendLocationUpdate({
    required int deliveryId,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) {
    _socket?.emit('location_update', {
      'deliveryId': deliveryId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
    });
  }
  
  static void onWorkerLocation(Function(Map<String, dynamic>) callback) {
    _socket?.on('worker_location', (data) => callback(data));
  }
  
  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
```

### 3. Update TrackDeliveryScreen
```dart
@override
void initState() {
  super.initState();
  SocketService.connect();
  SocketService.joinDelivery(widget.deliveryId);
  
  SocketService.onWorkerLocation((data) {
    setState(() {
      _workerLat = data['latitude'];
      _workerLng = data['longitude'];
      _lastUpdate = DateTime.parse(data['timestamp']);
    });
    
    // Animate marker to new position
    _animateMarker(_workerLat, _workerLng);
  });
}

@override
void dispose() {
  SocketService.disconnect();
  super.dispose();
}
```

### 4. Update Worker Location Service
```dart
// Replace HTTP POST with Socket emit
static Future<void> _updateLocation(Position position) async {
  if (_currentDeliveryId != null) {
    SocketService.sendLocationUpdate(
      deliveryId: _currentDeliveryId!,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );
  }
}
```

---

## Testing

1. Start backend with WebSocket support
2. Worker starts delivery → joins socket room
3. Client opens track screen → joins delivery room
4. Worker moves → location updates broadcast in real-time
5. Client sees marker move smoothly on map

---

## Benefits

- **Real-time updates** - No polling delay
- **Reduced server load** - No repeated HTTP requests
- **Better UX** - Smooth marker animation
- **Scalable** - Socket.IO handles thousands of connections

---

## Fallback

If WebSocket fails, app should fall back to polling:
```dart
if (!SocketService.isConnected) {
  // Use existing polling mechanism
  Timer.periodic(Duration(seconds: 5), (_) {
    _fetchWorkerLocation();
  });
}
```

---

## Status

**Not implemented yet** - Current polling system works adequately for MVP.  
Implement when:
- User base grows (>100 concurrent deliveries)
- Real-time tracking becomes critical feature
- Server load from polling becomes issue

**Estimated effort:** 4-6 hours for full implementation and testing.
