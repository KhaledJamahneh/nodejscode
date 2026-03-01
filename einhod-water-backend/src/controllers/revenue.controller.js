const { query } = require('../config/database');

const getRevenueData = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    // Total revenue from actual payments
    const paymentQuery = await query(
      `SELECT 
        COALESCE(SUM(amount), 0) as payment_revenue,
        COALESCE(COUNT(*), 0) as total_payments
      FROM payments
      WHERE payment_date BETWEEN $1 AND $2
        AND payment_status = 'completed'`,
      [startDate, endDate]
    );

    // Get delivery stats just for count, not for revenue
    const deliveryQuery = await query(
      `SELECT 
        COALESCE(COUNT(*), 0) as total_deliveries
      FROM deliveries
      WHERE delivery_date BETWEEN $1 AND $2
        AND status = 'completed'`,
      [startDate, endDate]
    );

    const totalRevenue = parseFloat(paymentQuery.rows[0].payment_revenue) || 0;
    const paymentRevenue = totalRevenue;
    const deliveryRevenue = 0; // We don't count estimated revenue

    // Daily breakdown
    const dailyQuery = await query(
      `SELECT 
        DATE(payment_date) as date,
        SUM(amount) as revenue,
        COUNT(*) as payments
      FROM payments
      WHERE payment_date BETWEEN $1 AND $2
        AND payment_status = 'completed'
      GROUP BY DATE(payment_date)
      ORDER BY date ASC`,
      [startDate, endDate]
    );

    // Top clients by actual revenue
    const topClientsQuery = await query(
      `SELECT 
        cp.full_name as name,
        COALESCE(SUM(p.amount), 0) as revenue,
        COUNT(DISTINCT p.id) as orders
      FROM client_profiles cp
      JOIN users u ON cp.user_id = u.id
      JOIN payments p ON p.payer_id = u.id 
      WHERE p.payment_date BETWEEN $1 AND $2 
        AND p.payment_status = 'completed'
      GROUP BY cp.id, cp.full_name
      ORDER BY revenue DESC
      LIMIT 5`,
      [startDate, endDate]
    );

    res.json({
      totalRevenue,
      deliveryRevenue,
      paymentRevenue,
      totalDeliveries: parseInt(deliveryQuery.rows[0].total_deliveries),
      totalPayments: parseInt(paymentQuery.rows[0].total_payments),
      avgOrderValue: paymentQuery.rows[0].total_payments > 0 
        ? totalRevenue / paymentQuery.rows[0].total_payments 
        : 0,
      dailyData: dailyQuery.rows.map(row => ({
        date: row.date,
        revenue: parseFloat(row.revenue),
        deliveries: 0, // We don't mix daily deliveries here anymore
        payments: parseInt(row.payments),
      })),
      topClients: topClientsQuery.rows.map(row => ({
        name: row.name,
        revenue: parseFloat(row.revenue),
        orders: parseInt(row.orders),
      })),
      revenueByType: {
        delivery: 0,
        payment: paymentRevenue,
      },
    });
  } catch (error) {
    console.error('Error fetching revenue data:', error);
    res.status(getStatusCode(error)).json({ error: 'Failed to fetch revenue data' });
  }
};

module.exports = {
  getRevenueData,
};
