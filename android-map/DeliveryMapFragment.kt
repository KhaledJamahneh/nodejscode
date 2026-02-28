// DeliveryMapFragment.kt
package com.einhod.water.delivery

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Color
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import com.google.android.gms.location.*
import org.osmdroid.config.Configuration
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.GeoPoint
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.Marker
import org.osmdroid.views.overlay.Polyline
import org.osmdroid.views.overlay.mylocation.GpsMyLocationProvider
import org.osmdroid.views.overlay.mylocation.MyLocationNewOverlay

class DeliveryMapFragment : Fragment(), SensorEventListener {

    private lateinit var mapView: MapView
    private lateinit var recenterButton: Button
    private lateinit var myLocationOverlay: MyLocationNewOverlay
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var sensorManager: SensorManager
    
    private var currentLocation: GeoPoint? = null
    private var currentBearing: Float = 0f
    private var followMode = true
    private var routePolyline: Polyline? = null
    
    // Sample delivery points
    private val mainListDeliveries = listOf(
        GeoPoint(32.0853, 34.7818), // Tel Aviv
        GeoPoint(32.0667, 34.7667)
    )
    
    private val urgentDeliveries = listOf(
        GeoPoint(32.0900, 34.7900),
        GeoPoint(32.0750, 34.7750)
    )

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        val view = inflater.inflate(R.layout.fragment_delivery_map, container, false)
        
        // Initialize osmdroid configuration
        Configuration.getInstance().userAgentValue = requireContext().packageName
        
        mapView = view.findViewById(R.id.mapView)
        recenterButton = view.findViewById(R.id.recenterButton)
        
        setupMap()
        setupLocationTracking()
        setupCompass()
        setupRecenterButton()
        addDeliveryMarkers()
        
        return view
    }

    private fun setupMap() {
        mapView.apply {
            setTileSource(TileSourceFactory.MAPNIK) // Standard OSM Mapnik
            setMultiTouchControls(true)
            controller.setZoom(16.0)
            minZoomLevel = 10.0
            maxZoomLevel = 20.0
        }
        
        // My location overlay
        myLocationOverlay = MyLocationNewOverlay(
            GpsMyLocationProvider(requireContext()),
            mapView
        ).apply {
            enableMyLocation()
            enableFollowLocation()
        }
        mapView.overlays.add(myLocationOverlay)
    }

    private fun setupLocationTracking() {
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(requireActivity())
        
        if (ActivityCompat.checkSelfPermission(
                requireContext(),
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                LOCATION_PERMISSION_REQUEST
            )
            return
        }
        
        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            2000 // 2 seconds
        ).build()
        
        val locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.lastLocation?.let { location ->
                    updateLocation(location)
                }
            }
        }
        
        fusedLocationClient.requestLocationUpdates(
            locationRequest,
            locationCallback,
            null
        )
    }

    private fun setupCompass() {
        sensorManager = requireContext().getSystemService(SensorManager::class.java)
        sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)?.let { sensor ->
            sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
        }
    }

    private fun setupRecenterButton() {
        recenterButton.apply {
            // High contrast styling
            setBackgroundColor(Color.parseColor("#FF6B00")) // Orange
            setTextColor(Color.WHITE)
            elevation = 8f
            
            setOnClickListener {
                followMode = true
                currentLocation?.let { location ->
                    mapView.controller.animateTo(location)
                    mapView.mapOrientation = -currentBearing
                }
            }
        }
        
        // Disable follow mode on manual pan
        mapView.setOnTouchListener { _, _ ->
            followMode = false
            false
        }
    }

    private fun addDeliveryMarkers() {
        // Main List - Blue markers
        mainListDeliveries.forEach { point ->
            Marker(mapView).apply {
                position = point
                setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM)
                icon = ContextCompat.getDrawable(requireContext(), R.drawable.ic_marker_blue)
                title = "Main Delivery"
                mapView.overlays.add(this)
            }
        }
        
        // Urgent List - Orange markers
        urgentDeliveries.forEach { point ->
            Marker(mapView).apply {
                position = point
                setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM)
                icon = ContextCompat.getDrawable(requireContext(), R.drawable.ic_marker_orange)
                title = "URGENT Delivery"
                mapView.overlays.add(this)
            }
        }
    }

    private fun updateLocation(location: Location) {
        val newLocation = GeoPoint(location.latitude, location.longitude)
        currentLocation = newLocation
        
        if (followMode) {
            mapView.controller.animateTo(newLocation)
            mapView.mapOrientation = -currentBearing // Rotate map based on compass
        }
        
        // Draw route to nearest urgent delivery
        urgentDeliveries.firstOrNull()?.let { targetPoint ->
            drawRoute(newLocation, targetPoint)
        }
    }

    private fun drawRoute(start: GeoPoint, end: GeoPoint) {
        // Remove old route
        routePolyline?.let { mapView.overlays.remove(it) }
        
        // Create new route polyline
        routePolyline = Polyline(mapView).apply {
            setPoints(listOf(start, end))
            outlinePaint.apply {
                color = Color.parseColor("#0A4D8C") // Deep Ocean Blue
                strokeWidth = 8f
                isAntiAlias = true
            }
        }
        
        mapView.overlays.add(0, routePolyline) // Add below markers
        mapView.invalidate()
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type == Sensor.TYPE_ROTATION_VECTOR) {
            val rotationMatrix = FloatArray(9)
            SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
            
            val orientation = FloatArray(3)
            SensorManager.getOrientation(rotationMatrix, orientation)
            
            // Azimuth (rotation around z-axis)
            currentBearing = Math.toDegrees(orientation[0].toDouble()).toFloat()
            
            if (followMode) {
                mapView.mapOrientation = -currentBearing
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not needed
    }

    override fun onResume() {
        super.onResume()
        mapView.onResume()
        sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)?.let { sensor ->
            sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
        }
    }

    override fun onPause() {
        super.onPause()
        mapView.onPause()
        sensorManager.unregisterListener(this)
    }

    override fun onDestroyView() {
        super.onDestroyView()
        fusedLocationClient.removeLocationUpdates(object : LocationCallback() {})
    }

    companion object {
        private const val LOCATION_PERMISSION_REQUEST = 1001
    }
}
