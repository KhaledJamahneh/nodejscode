// lib/features/admin/presentation/screens/admin_analytics_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/double_utils.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../providers/analytics_provider.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final filter = ref.watch(analyticsFilterProvider);
    final currencyFormat =
        NumberFormat.currency(symbol: '₪', decimalDigits: 2);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showPageInfo(context, l10n.overview, l10n.overviewDesc),
          child: Text(l10n.overview),
        ),
        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeProvider) == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              size: 22,
            ),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          IconButton(
            icon: Text(
              ref.watch(localeProvider).languageCode == 'en' ? 'ع' : 'En',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
          ),
          IconButton(
            icon: Icon(
              filter.hasFilter
                  ? Icons.date_range_rounded
                  : Icons.calendar_today_rounded,
              color: filter.hasFilter ? AppTheme.primary : null,
            ),
            onPressed: () => _selectDateRange(context, ref, filter),
            tooltip: l10n.selectPeriod,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(analyticsProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: analyticsAsync.when(
        data: (data) =>
            _buildAnalyticsContent(context, ref, data, filter, currencyFormat),
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 64, color: AppTheme.iosRed),
              const SizedBox(height: 16),
              Text('${l10n.error}: $error',
                  style: const TextStyle(color: AppTheme.iosGray)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(analyticsProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange(
      BuildContext context, WidgetRef ref, AnalyticsFilter filter) async {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today),
              title: Text(l10n.today),
              onTap: () {
                final today = DateTime.now();
                ref.read(analyticsFilterProvider.notifier).state = AnalyticsFilter(startDate: today, endDate: today);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.singleDate),
              onTap: () async {
                Navigator.pop(context);
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: filter.startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (selectedDate != null) {
                  ref.read(analyticsFilterProvider.notifier).state = AnalyticsFilter(startDate: selectedDate, endDate: selectedDate);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: Text(l10n.dateRange),
              onTap: () async {
                Navigator.pop(context);
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (range != null) {
                  ref.read(analyticsFilterProvider.notifier).state = AnalyticsFilter(startDate: range.start, endDate: range.end);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(
      BuildContext context,
      WidgetRef ref,
      Map<String, dynamic> data,
      AnalyticsFilter filter,
      NumberFormat currencyFormat) {
    final deliveries = data['deliveries'] ?? {};
    final revenue = data['revenue'] ?? {};
    final expenses = data['expenses'] ?? {};
    final financialSummary = data['financial_summary'] ?? {};
    final salaryAdvances = data['salary_advances'] ?? {};
    final clients = data['clients'] ?? {};
    final topWorkers = data['top_workers'] as List? ?? [];
    final l10n = AppLocalizations.of(context)!;

    String dateRangeText;
    if (filter.hasFilter) {
      final today = DateTime.now();
      final isToday = filter.startDate!.year == today.year &&
          filter.startDate!.month == today.month &&
          filter.startDate!.day == today.day &&
          filter.endDate!.year == today.year &&
          filter.endDate!.month == today.month &&
          filter.endDate!.day == today.day;
      
      if (isToday) {
        dateRangeText = l10n.today;
      } else {
        dateRangeText = '${DateFormat('MMM d').format(filter.startDate!)} - ${DateFormat('MMM d, y').format(filter.endDate!)}';
      }
    } else {
      dateRangeText = l10n.last30Days;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Premium Overview Card (High Level)
          _buildPremiumOverview(context, ref, data, filter, dateRangeText, currencyFormat, l10n),
          const SizedBox(height: 28),

          // 2. Performance Section (Charts)
          _buildSectionHeader(l10n.deliveryPerformance, Icons.analytics_rounded),
          const SizedBox(height: 12),
          _buildChartCard(
            context,
            l10n.deliveryPerformance,
            Icons.show_chart,
            _buildDeliveryChart(deliveries),
          ),
          const SizedBox(height: 28),

          // 3. Financial Health Section
          _buildSectionHeader(l10n.financialOverview, Icons.account_balance_rounded),
          const SizedBox(height: 12),
          _buildFinancialDashboard(context, financialSummary, revenue, expenses, salaryAdvances, currencyFormat, l10n),
          const SizedBox(height: 28),

          // 4. Operational Efficiency Section
          _buildSectionHeader('Operational Efficiency', Icons.speed_rounded),
          const SizedBox(height: 12),
          _buildMetricsGrid([
            _buildStatItem(
              context,
              l10n.gallons,
              '${deliveries['total_gallons'] ?? 0}${l10n.gallons}',
              Icons.water_drop_rounded,
              AppTheme.iosTeal,
            ),
            _buildStatItem(
              context,
              l10n.avgPerDelivery,
              '${DoubleUtils.toDouble(deliveries['avg_gallons']).toStringAsFixed(1)}${l10n.gallons}',
              Icons.auto_graph_rounded,
              AppTheme.iosIndigo,
            ),
            _buildStatItem(
              context,
              l10n.uniqueClients,
              '${deliveries['unique_clients'] ?? 0}',
              Icons.people_alt_rounded,
              AppTheme.iosPurple,
            ),
            _buildStatItem(
              context,
              l10n.totalDebt,
              currencyFormat.format(DoubleUtils.toDouble(clients['total_debt'])),
              Icons.money_off_rounded,
              AppTheme.iosRed,
            ),
          ]),
          const SizedBox(height: 28),

          // 5. Workforce Leaderboard
          _buildSectionHeader(l10n.topDeliveryWorkers, Icons.stars_rounded),
          const SizedBox(height: 12),
          _buildTopWorkersList(context, topWorkers),
          const SizedBox(height: 28),

          // 6. On-site Production
          _buildSectionHeader(l10n.onsitePerformance, Icons.factory_rounded),
          const SizedBox(height: 12),
          _buildOnsiteWorkersList(context, data['onsite_workers'] as List? ?? []),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.iosGray),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.iosGray,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumOverview(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
    AnalyticsFilter filter,
    String dateRangeText,
    NumberFormat currencyFormat,
    AppLocalizations l10n,
  ) {
    final financial = data['financial_summary'] ?? {};
    final netIncome = DoubleUtils.toDouble(financial['net_income']);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.payments_rounded,
              size: 150,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateRangeText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.netBalance,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _selectDateRange(context, ref, filter),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  currencyFormat.format(netIncome),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildHeaderMiniStat(
                        l10n.revenue,
                        currencyFormat.format(DoubleUtils.toDouble(financial['total_income'])),
                        Icons.trending_up_rounded,
                        AppTheme.successGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildHeaderMiniStat(
                        l10n.outcome,
                        currencyFormat.format(DoubleUtils.toDouble(financial['total_outcome'])),
                        Icons.trending_down_rounded,
                        AppTheme.criticalRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMiniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialDashboard(
    BuildContext context,
    Map<String, dynamic> summary,
    Map<String, dynamic> revenue,
    Map<String, dynamic> expenses,
    Map<String, dynamic> advances,
    NumberFormat currencyFormat,
    AppLocalizations l10n,
  ) {
    return ModernCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildFinancialRow(
            context,
            l10n.totalRevenue,
            summary['total_income'],
            Icons.payments_rounded,
            AppTheme.successGreen,
            currencyFormat,
            onTap: () => _showFinancialDetails(context, l10n.totalRevenue, summary, revenue, currencyFormat, l10n),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          _buildFinancialRow(
            context,
            l10n.expenses,
            summary['total_expenses'],
            Icons.receipt_long_rounded,
            AppTheme.iosOrange,
            currencyFormat,
            onTap: () => _showExpenseDetails(context, l10n.expenses, summary, expenses, advances, currencyFormat, l10n, 'paid'),
            subtitle: '${l10n.paid}: ${currencyFormat.format(DoubleUtils.toDouble(summary['paid_expenses']))}',
          ),
          const SizedBox(height: 16),
          _buildFinancialRow(
            context,
            l10n.salaryAdvance,
            summary['total_salary_advances'],
            Icons.account_balance_wallet_rounded,
            AppTheme.iosPink,
            currencyFormat,
            onTap: () => _showExpenseDetails(context, l10n.salaryAdvance, summary, expenses, advances, currencyFormat, l10n, 'advances'),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
    BuildContext context,
    String label,
    dynamic value,
    IconData icon,
    Color color,
    NumberFormat currencyFormat, {
    VoidCallback? onTap,
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.iosGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(DoubleUtils.toDouble(value)),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.iosGray4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(List<Widget> children) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: children,
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value,
      IconData icon, Color color,
      {VoidCallback? onTap}) {
    return ModernCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.iosGray,
                    fontWeight: FontWeight.w600,
                    height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, String title, IconData icon, Widget chart) {
    return ModernCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.more_horiz_rounded, color: AppTheme.iosGray),
            ],
          ),
          const SizedBox(height: 24),
          chart,
        ],
      ),
    );
  }

  Widget _buildDeliveryChart(Map<String, dynamic> deliveries) {
    final completed = DoubleUtils.toDouble(deliveries['completed_deliveries'] ?? 0);
    final pending = DoubleUtils.toDouble(deliveries['pending_deliveries'] ?? 0);
    final inProgress = DoubleUtils.toDouble(deliveries['in_progress_deliveries'] ?? 0);
    final cancelled = DoubleUtils.toDouble(deliveries['cancelled_deliveries'] ?? 0);
    
    final total = completed + pending + inProgress + cancelled;
    
    if (total == 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No deliveries data')),
      );
    }

    final completionRate = total > 0 ? (completed / total) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Completion Rate',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.iosGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${completionRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.successGreen,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.iosGray6,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Total: ${total.toInt()}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.iosGray,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: total > 0 ? (total * 1.1) : 10,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => AppTheme.primary,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String status;
                    switch (group.x.toInt()) {
                      case 0: status = 'Completed'; break;
                      case 1: status = 'Pending'; break;
                      case 2: status = 'In Progress'; break;
                      case 3: status = 'Cancelled'; break;
                      default: status = '';
                    }
                    return BarTooltipItem(
                      '$status\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: '${rod.toY.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      String text;
                      switch (value.toInt()) {
                        case 0: text = 'Done'; break;
                        case 1: text = 'Wait'; break;
                        case 2: text = 'Run'; break;
                        case 3: text = 'Fail'; break;
                        default: text = '';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: AppTheme.iosGray,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                _buildBarGroup(0, completed, AppTheme.successGreen),
                _buildBarGroup(1, pending, AppTheme.midUrgentOrange),
                _buildBarGroup(2, inProgress, AppTheme.primaryBlue),
                _buildBarGroup(3, cancelled, AppTheme.criticalRed),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildChartLegendItem('Completed', AppTheme.successGreen),
            _buildChartLegendItem('Pending', AppTheme.midUrgentOrange),
            _buildChartLegendItem('In Progress', AppTheme.primaryBlue),
            _buildChartLegendItem('Cancelled', AppTheme.criticalRed),
          ],
        ),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 0,
            color: AppTheme.iosGray6,
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppTheme.iosGray,
          ),
        ),
      ],
    );
  }

  Widget _buildTopWorkersList(BuildContext context, List<dynamic> workers) {
    final l10n = AppLocalizations.of(context)!;
    if (workers.isEmpty) {
      return ModernCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
              child: Text(l10n.noDeliveryWorkerData,
                  style: TextStyle(color: AppTheme.iosGray))),
        ),
      );
    }

    return ModernCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: workers.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
        itemBuilder: (context, index) {
          final worker = workers[index];
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text('${index + 1}',
                  style: const TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(worker['full_name'] ?? l10n.unknownWorker,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
                '${l10n.completed}: ${worker['deliveries_completed'] ?? 0} ${l10n.deliveries}',
                style: const TextStyle(fontSize: 13)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.iosTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${worker['total_gallons'] ?? 0}${l10n.gallons}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.iosTeal,
                    fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOnsiteWorkersList(BuildContext context, List<dynamic> workers) {
    final l10n = AppLocalizations.of(context)!;
    if (workers.isEmpty) {
      return ModernCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
              child: Text(l10n.noOnsiteWorkerData,
                  style: TextStyle(color: AppTheme.iosGray))),
        ),
      );
    }

    return ModernCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: workers.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
        itemBuilder: (context, index) {
          final worker = workers[index];
          final totalFilled = worker['total_gallons_filled'] ?? 0;
          final avgRate = DoubleUtils.toDouble(worker['avg_filling_rate'])
              .toStringAsFixed(1);

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.iosOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.water_drop_rounded,
                  color: AppTheme.iosOrange, size: 20),
            ),
            title: Text(worker['full_name'] ?? l10n.unknownWorker,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
                '${l10n.sessions}: ${worker['sessions_completed'] ?? 0} • ${l10n.avg}: $avgRate ${l10n.gallons}',
                style: const TextStyle(fontSize: 13)),
            trailing: Text(
              '$totalFilled ${l10n.gallons}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.iosOrange),
            ),
          );
        },
      ),
    );
  }

  void _showFinancialDetails(BuildContext context, String title, Map<String, dynamic> summary, Map<String, dynamic> revenue, NumberFormat currencyFormat, AppLocalizations l10n) {
    final paymentLogs = summary['payment_logs'] as List? ?? [];
    Navigator.push(context, MaterialPageRoute(builder: (context) => _FinancialDetailsPage(
      title: title, total: summary['total_income'], items: paymentLogs, currencyFormat: currencyFormat, type: 'revenue',
    )));
  }

  void _showExpenseDetails(BuildContext context, String title, Map<String, dynamic> summary, Map<String, dynamic> expenses, Map<String, dynamic> advances, NumberFormat currencyFormat, AppLocalizations l10n, String filterType) {
    final expenseList = summary['expense_list'] as List? ?? [];
    final advanceDetails = advances['advance_details'] as List? ?? [];
    
    List items;
    if (filterType == 'paid') {
      items = expenseList.where((e) => e['payment_status'] == 'paid').toList();
    } else if (filterType == 'unpaid') {
      items = expenseList.where((e) => e['payment_status'] == 'unpaid').toList();
    } else {
      items = advanceDetails;
    }
    
    Navigator.push(context, MaterialPageRoute(builder: (context) => _FinancialDetailsPage(
      title: title, total: filterType == 'paid' ? summary['paid_expenses'] : (filterType == 'unpaid' ? summary['unpaid_expenses'] : summary['total_salary_advances']), items: items, currencyFormat: currencyFormat, type: filterType,
    )));
  }

  void _showPageInfo(BuildContext context, String title, String description) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.iosGray4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FinancialDetailsPage extends StatelessWidget {
  final String title;
  final dynamic total;
  final List? items;
  final NumberFormat currencyFormat;
  final String type;

  const _FinancialDetailsPage({required this.title, required this.total, this.items, required this.currencyFormat, required this.type});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.total, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(currencyFormat.format(DoubleUtils.toDouble(total)), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: type == 'revenue' ? AppTheme.iosGreen : (type == 'paid' ? AppTheme.iosGreen : (type == 'unpaid' ? AppTheme.iosRed : AppTheme.iosOrange)))),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items?.length ?? 0,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items![index];
                if (type == 'revenue') {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: Icon(item['payment_method'] == 'cash' ? Icons.money : Icons.credit_card, color: AppTheme.iosGreen),
                    title: Text(item['client_name'] ?? item['username'] ?? 'N/A'),
                    subtitle: Text(item['payment_date']?.toString().split('T')[0] ?? ''),
                    trailing: Text(currencyFormat.format(DoubleUtils.toDouble(item['amount'])), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  );
                } else if (type == 'advances') {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: const Icon(Icons.account_balance_wallet, color: AppTheme.iosOrange),
                    title: Text(item['worker_name'] ?? item['username'] ?? 'N/A'),
                    subtitle: Text(l10n.salaryAdvance),
                    trailing: Text(currencyFormat.format(DoubleUtils.toDouble(item['advance_amount'])), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.iosOrange)),
                  );
                } else {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: Icon(item['payment_method'] == 'my_pocket' ? Icons.account_balance_wallet : Icons.business, color: type == 'paid' ? AppTheme.iosGreen : AppTheme.iosRed),
                    title: Text(item['worker_name'] ?? item['username'] ?? 'N/A'),
                    subtitle: Text('${item['destination'] ?? ''} - ${item['notes'] ?? ''}'),
                    trailing: Text(currencyFormat.format(DoubleUtils.toDouble(item['amount'])), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: type == 'paid' ? AppTheme.iosGreen : AppTheme.iosRed)),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
