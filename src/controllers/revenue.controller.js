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

    // Cash revenue
    const cashQuery = await query(
      `SELECT 
        COALESCE(SUM(amount), 0) as cash_revenue,
        COALESCE(COUNT(*), 0) as cash_transactions
      FROM payments
      WHERE payment_date BETWEEN $1 AND $2
        AND payment_status = 'completed'
        AND payment_method = 'cash'`,
      [startDate, endDate]
    );

    // Coupon revenue (coupons_collected)
    const couponQuery = await query(
      `SELECT 
        COALESCE(SUM(coupons_collected), 0) as total_coupons,
        COALESCE(SUM(coupons_collected * cs.price), 0) as coupon_revenue
      FROM deliveries d
      LEFT JOIN coupon_sizes cs ON d.coupon_size_id = cs.id
      WHERE d.delivery_date BETWEEN $1 AND $2
        AND d.status = 'completed'
        AND d.coupons_collected > 0`,
      [startDate, endDate]
    );

    // Get delivery stats
    const deliveryQuery = await query(
      `SELECT 
        COALESCE(COUNT(*), 0) as total_deliveries
      FROM deliveries
      WHERE delivery_date BETWEEN $1 AND $2
        AND status = 'completed'`,
      [startDate, endDate]
    );

    const paymentRevenue = parseFloat(paymentQuery.rows[0].payment_revenue) || 0;
    const cashRevenue = parseFloat(cashQuery.rows[0].cash_revenue) || 0;
    const couponRevenue = parseFloat(couponQuery.rows[0].coupon_revenue) || 0;
    const totalRevenue = paymentRevenue + couponRevenue;

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
      deliveryRevenue: 0,
      paymentRevenue,
      cashRevenue,
      couponRevenue,
      totalDeliveries: parseInt(deliveryQuery.rows[0].total_deliveries),
      totalPayments: parseInt(paymentQuery.rows[0].total_payments),
      cashTransactions: parseInt(cashQuery.rows[0].cash_transactions),
      totalCoupons: parseInt(couponQuery.rows[0].total_coupons),
      avgOrderValue: paymentQuery.rows[0].total_payments > 0 
        ? totalRevenue / paymentQuery.rows[0].total_payments 
        : 0,
      dailyData: dailyQuery.rows.map(row => ({
        date: row.date,
        revenue: parseFloat(row.revenue),
        deliveries: 0,
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
        cash: cashRevenue,
        coupon: couponRevenue,
      },
    });
  } catch (error) {
    console.error('Error fetching revenue data:', error);
    res.status(500).json({ error: 'Failed to fetch revenue data' });
  }
};

module.exports = {
  getRevenueData,
};
