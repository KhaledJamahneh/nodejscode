# Water Delivery Map - Kotlin Fragment with osmdroid

## Features Implemented

### ✅ MapView with OSM Mapnik Tiles
- Standard OpenStreetMap Mapnik tile source
- Multi-touch controls enabled
- Zoom levels: 10-20

### ✅ Follow My Location Mode
- Real-time GPS tracking (updates every 2 seconds)
- Map centers on worker's location
- Compass-based rotation using rotation vector sensor
- Auto-disables on manual pan

### ✅ Route Polyline
- Draws route from current location to nearest urgent delivery
- Deep Ocean Blue color (#0A4D8C)
- 8px stroke width
- Updates in real-time as worker moves

### ✅ High-Contrast Recenter Button
- Orange circular button (#FF6B00)
- White border for visibility
- 8dp elevation for depth
- Re-enables follow mode on tap
- Positioned bottom-right

### ✅ Custom Delivery Markers
- **Blue markers**: Main List deliveries
- **Orange markers**: Urgent/Secondary List deliveries
- Custom icons with anchor at bottom center
- Titles on tap

## Files Created

1. **DeliveryMapFragment.kt** - Main fragment implementation
2. **fragment_delivery_map.xml** - Layout file
3. **bg_recenter_button.xml** - Button background drawable
4. **build.gradle.snippet** - Required dependencies
5. **AndroidManifest.snippet.xml** - Required permissions

## Usage

```kotlin
// In your Activity
supportFragmentManager.beginTransaction()
    .replace(R.id.container, DeliveryMapFragment())
    .commit()
```

## Dependencies Required

```gradle
implementation 'org.osmdroid:osmdroid-android:6.1.18'
implementation 'com.google.android.gms:play-services-location:21.0.1'
```

## Permissions Required

- ACCESS_FINE_LOCATION
- ACCESS_COARSE_LOCATION
- INTERNET
- ACCESS_NETWORK_STATE
- WRITE_EXTERNAL_STORAGE

## Key Components

### Location Tracking
- Uses FusedLocationProviderClient for accurate GPS
- High accuracy priority
- 2-second update interval

### Compass Rotation
- TYPE_ROTATION_VECTOR sensor for smooth rotation
- Azimuth calculation for bearing
- Map rotates to match device orientation

### Follow Mode
- Automatically centers and rotates map
- Disables on user interaction
- Re-enables via recenter button

### Marker System
- Main deliveries: Blue markers
- Urgent deliveries: Orange markers
- Custom drawable icons (create ic_marker_blue.xml and ic_marker_orange.xml)

## Customization

### Change Delivery Points
```kotlin
private val mainListDeliveries = listOf(
    GeoPoint(latitude, longitude),
    // Add more points
)

private val urgentDeliveries = listOf(
    GeoPoint(latitude, longitude),
    // Add more points
)
```

### Change Route Color
```kotlin
outlinePaint.color = Color.parseColor("#YOUR_COLOR")
```

### Change Update Interval
```kotlin
LocationRequest.Builder(
    Priority.PRIORITY_HIGH_ACCURACY,
    5000 // 5 seconds
)
```

## Notes

- Requires runtime permission handling for Android 6.0+
- osmdroid caches tiles locally for offline use
- Compass requires device with rotation vector sensor
- Route is straight line (use routing API for actual roads)
