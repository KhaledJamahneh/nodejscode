import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/revenue_service.dart';

final revenueDataProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, DateTimeRange>((ref, dateRange) async {
  return await RevenueService.getRevenueData(dateRange.start, dateRange.end);
});

class AdminRevenuesScreen extends ConsumerStatefulWidget {
  const AdminRevenuesScreen({super.key});

  @override
  ConsumerState<AdminRevenuesScreen> createState() => _AdminRevenuesScreenState();
}

class _AdminRevenuesScreenState extends ConsumerState<AdminRevenuesScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int _selectedPeriod = 30;

  void _setPeriod(int days) {
    setState(() {
      _selectedPeriod = days;
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateRange = DateTimeRange(start: _startDate, end: _endDate);
    final revenueAsync = ref.watch(revenueDataProvider(dateRange));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.revenues),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: revenueAsync.when(
        data: (data) => _buildContent(context, l10n, data),
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n, Map<String, dynamic> data) {
    final currencyFormat = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    final dateFormat = DateFormat('MMM dd');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(revenueDataProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            _buildPeriodSelector(l10n),
            const SizedBox(height: 16),

            // Date Range Picker
            _buildDateRangePicker(context, l10n),
            const SizedBox(height: 24),

            // Total Revenue Card
            _buildTotalRevenueCard(data, currencyFormat, l10n),
            const SizedBox(height: 16),

            // Quick Stats Grid
            _buildQuickStatsGrid(data, currencyFormat, l10n),
            const SizedBox(height: 24),

            // Revenue Chart
            _buildRevenueChart(data, dateFormat, l10n),
            const SizedBox(height: 24),

            // Revenue Breakdown
            _buildRevenueBreakdown(data, currencyFormat, l10n),
            const SizedBox(height: 24),

            // Top Clients
            _buildTopClients(data, currencyFormat, l10n),
            const SizedBox(height: 24),

            // Daily Breakdown Table
            _buildDailyBreakdown(data, currencyFormat, dateFormat, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPeriodButton('7D', 7),
          _buildPeriodButton('30D', 30),
          _buildPeriodButton('90D', 90),
          _buildPeriodButton('1Y', 365),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, int days) {
    final isSelected = _selectedPeriod == days;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setPeriod(days),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangePicker(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDateButton(
              context,
              l10n.startDate,
              _startDate,
              () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _startDate = date);
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, color: AppTheme.iosGray),
          ),
          Expanded(
            child: _buildDateButton(
              context,
              l10n.endDate,
              _endDate,
              () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: _startDate,
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _endDate = date);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(BuildContext context, String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRevenueCard(Map<String, dynamic> data, NumberFormat currencyFormat, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+12.5%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.totalRevenue,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(data['totalRevenue']),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid(Map<String, dynamic> data, NumberFormat currencyFormat, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_shipping_rounded,
            label: l10n.deliveries,
            value: '${data['totalDeliveries']}',
            subtitle: currencyFormat.format(data['deliveryRevenue']),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.payment_rounded,
            label: l10n.payments,
            value: '${data['totalPayments']}',
            subtitle: currencyFormat.format(data['paymentRevenue']),
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(Map<String, dynamic> data, DateFormat dateFormat, AppLocalizations l10n) {
    final dailyData = data['dailyData'] as List;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Revenue Trend',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₪${(value / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: dailyData.length / 5,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= dailyData.length) return const SizedBox();
                        final date = DateTime.parse(dailyData[value.toInt()]['date']);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dateFormat.format(date),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: dailyData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), (e.value['revenue'] as num).toDouble());
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final date = DateTime.parse(dailyData[spot.x.toInt()]['date']);
                        return LineTooltipItem(
                          '${dateFormat.format(date)}\n₪${spot.y.toStringAsFixed(0)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdown(Map<String, dynamic> data, NumberFormat currencyFormat, AppLocalizations l10n) {
    final breakdown = data['revenueByType'] as Map<String, dynamic>;
    final total = data['totalRevenue'] as num;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Revenue Breakdown',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildBreakdownItem(
            label: l10n.deliveries,
            amount: currencyFormat.format(breakdown['delivery']),
            percentage: ((breakdown['delivery'] / total) * 100).toStringAsFixed(1),
            color: Colors.blue,
            progress: (breakdown['delivery'] / total).toDouble(),
          ),
          const SizedBox(height: 16),
          _buildBreakdownItem(
            label: l10n.payments,
            amount: currencyFormat.format(breakdown['payment']),
            percentage: ((breakdown['payment'] / total) * 100).toStringAsFixed(1),
            color: Colors.green,
            progress: (breakdown['payment'] / total).toDouble(),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem({
    required String label,
    required String amount,
    required String percentage,
    required Color color,
    required double progress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            Text(
              '$amount ($percentage%)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildTopClients(Map<String, dynamic> data, NumberFormat currencyFormat, AppLocalizations l10n) {
    final topClients = data['topClients'] as List;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Top Clients',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topClients.asMap().entries.map((entry) {
            final index = entry.key;
            final client = entry.value;
            return _buildTopClientItem(
              rank: index + 1,
              name: client['name'],
              revenue: currencyFormat.format(client['revenue']),
              orders: client['orders'],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopClientItem({
    required int rank,
    required String name,
    required String revenue,
    required int orders,
  }) {
    Color rankColor;
    if (rank == 1) rankColor = Colors.amber;
    else if (rank == 2) rankColor = Colors.grey.shade400;
    else if (rank == 3) rankColor = Colors.brown.shade300;
    else rankColor = Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '$orders orders',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            revenue,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdown(Map<String, dynamic> data, NumberFormat currencyFormat, DateFormat dateFormat, AppLocalizations l10n) {
    final dailyData = (data['dailyData'] as List).reversed.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Daily Breakdown',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                children: [
                  _buildTableHeader('Date'),
                  _buildTableHeader('Revenue'),
                  _buildTableHeader('Orders'),
                  _buildTableHeader('Payments'),
                ],
              ),
              ...dailyData.map((day) {
                return TableRow(
                  children: [
                    _buildTableCell(dateFormat.format(DateTime.parse(day['date']))),
                    _buildTableCell(currencyFormat.format(day['revenue'])),
                    _buildTableCell('${day['deliveries']}'),
                    _buildTableCell('${day['payments']}'),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
