// src/controllers/location.controller.js
const { query } = require('../config/database');
const { sendNotification } = require('../services/notification.service');

// Update worker location
exports.updateLocation = async (req, res) => {
  try {
    const { latitude, longitude, accuracy } = req.body;
    const userId = req.user.id;

    await query(
      `INSERT INTO worker_locations (user_id, latitude, longitude, accuracy)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id) 
       DO UPDATE SET latitude = $2, longitude = $3, accuracy = $4, updated_at = CURRENT_TIMESTAMP`,
      [userId, latitude, longitude, accuracy]
    );

    // Check for nearby clients
    const nearbyClients = await query(
      'SELECT * FROM get_nearby_clients($1, 500)',
      [userId]
    );

    // Send notifications to nearby clients
    if (nearbyClients.rows.length > 0) {
      const workerInfo = await query(
        'SELECT full_name FROM worker_profiles WHERE user_id = $1',
        [userId]
      );
      const workerName = workerInfo.rows[0]?.full_name || 'Your delivery worker';

      for (const client of nearbyClients.rows) {
        await sendNotification(client.client_id, {
          title: 'Delivery Worker Nearby',
          body: `${workerName} is approaching your location`,
          data: { type: 'worker_nearby', worker_id: userId }
        });
      }
    }

    // Check for nearby stations (if delivery worker)
    const nearbyStations = await query(
      `SELECT s.id, s.name, 
        calculate_distance($1, $2, s.latitude, s.longitude) as distance
       FROM stations s
       WHERE calculate_distance($1, $2, s.latitude, s.longitude) <= 500
       ORDER BY distance`,
      [latitude, longitude]
    );

    res.json({
      success: true,
      nearby_clients: nearbyClients.rows,
      nearby_stations: nearbyStations.rows,
    });
  } catch (error) {
    console.error('Error updating location:', error);
    res.status(getStatusCode(error)).json({ message: 'Failed to update location' });
  }
};

// Get worker location
exports.getWorkerLocation = async (req, res) => {
  try {
    const { workerId } = req.params;

    const result = await query(
      `SELECT wl.*, u.username
       FROM worker_locations wl
       JOIN users u ON wl.user_id = u.id
       WHERE wl.user_id = $1
       AND wl.updated_at > NOW() - INTERVAL '5 minutes'`,
      [workerId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Location not found or outdated' });
    }

    res.json({ location: result.rows[0] });
  } catch (error) {
    console.error('Error fetching location:', error);
    res.status(getStatusCode(error)).json({ message: 'Failed to fetch location' });
  }
};

// Get all active worker locations
exports.getActiveWorkerLocations = async (req, res) => {
  try {
    const result = await query(
      `SELECT wl.*, u.username, wp.full_name
       FROM worker_locations wl
       JOIN users u ON wl.user_id = u.id
       JOIN worker_profiles wp ON u.id = wp.user_id
       WHERE wl.updated_at > NOW() - INTERVAL '5 minutes'
       AND u.is_active = true
       ORDER BY wl.updated_at DESC`
    );

    res.json({ locations: result.rows });
  } catch (error) {
    console.error('Error fetching locations:', error);
    res.status(getStatusCode(error)).json({ message: 'Failed to fetch locations' });
  }
};
