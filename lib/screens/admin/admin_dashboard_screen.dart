import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;

  List<(String, IconData, IconData)> _getNavItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      (l10n.overview, Icons.dashboard_outlined, Icons.dashboard),
      (l10n.clients, Icons.people_outlined, Icons.people),
      ('Workers', Icons.badge_outlined, Icons.badge),
      ('Deliveries', Icons.local_shipping_outlined, Icons.local_shipping),
      ('Scheduling', Icons.calendar_today_outlined, Icons.calendar_today),
      ('Dispensers', Icons.water_outlined, Icons.water),
      ('Finances', Icons.bar_chart_outlined, Icons.bar_chart),
      ('Reports', Icons.analytics_outlined, Icons.analytics),
      ('Settings', Icons.settings_outlined, Icons.settings),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final navItems = _getNavItems(context);

    final screens = [
      _OverviewTab(),
      const _ClientsTab(),
      const _WorkersTab(),
      const _DeliveriesTab(),
      const _SchedulingTab(),
      const _DispensersTab(),
      const _FinancesTab(),
      const _ReportsTab(),
      const _SettingsTab(),
    ];

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Sidebar
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _sidebarCollapsed ? 64 : 220,
              color: AppColors.white,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  // Logo
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              gradient: AppColors.heroGradient,
                              shape: BoxShape.circle),
                          child: const Center(
                              child:
                                  Text('💧', style: TextStyle(fontSize: 18))),
                        ),
                        if (!_sidebarCollapsed) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text('Einhod',
                                style: AppTypography.titleLarge
                                    .copyWith(color: AppColors.oceanBlue)),
                          ),
                        ],
                        GestureDetector(
                          onTap: () => setState(
                              () => _sidebarCollapsed = !_sidebarCollapsed),
                          child: Icon(
                            _sidebarCollapsed
                                ? Icons.chevron_right
                                : Icons.chevron_left,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),

                  // Nav items
                  Expanded(
                    child: ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      itemCount: navItems.length,
                      itemBuilder: (_, i) {
                        final item = navItems[i];
                        final isSelected = i == _selectedIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.oceanBlue.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Row(
                              children: [
                                Icon(isSelected ? item.$3 : item.$2,
                                    color: isSelected
                                        ? AppColors.oceanBlue
                                        : AppColors.textSecondary,
                                    size: 20),
                                if (!_sidebarCollapsed) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(item.$1,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: isSelected
                                            ? AppColors.oceanBlue
                                            : AppColors.textSecondary,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      )),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Admin user
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle),
                          child: const Center(
                              child:
                                  Text('👤', style: TextStyle(fontSize: 18))),
                        ),
                        if (!_sidebarCollapsed) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Admin User',
                                    style: AppTypography.bodySmall
                                        .copyWith(fontWeight: FontWeight.w600)),
                                Text('admin@einhod.com',
                                    style: AppTypography.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const VerticalDivider(width: 1),

            // Main content
            Expanded(
              child: screens[_selectedIndex],
            ),
          ],
        ),
      );
    }

    // Mobile admin (tabbed)
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: EinhodAppBar(
          title: navItems[_selectedIndex].$1, notificationCount: 3),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex > 3 ? 3 : _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: navItems
            .take(4)
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.$2),
                  activeIcon: Icon(item.$3),
                  label: item.$1,
                ))
            .toList(),
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.overview),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          const SizedBox(width: AppSpacing.sm),
        ],
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: const [
                KpiCard(
                    emoji: '👷',
                    value: '3',
                    label: 'Active Workers',
                    trend: '12%',
                    trendUp: true),
                KpiCard(
                    emoji: '🚛',
                    value: '17',
                    label: 'Pending Deliveries',
                    trend: '8%',
                    trendUp: false,
                    color: AppColors.warning),
                KpiCard(
                    emoji: '💰',
                    value: '₪12,450',
                    label: 'Monthly Revenue',
                    trend: '23%',
                    trendUp: true,
                    color: AppColors.success),
                KpiCard(
                    emoji: '⚠️',
                    value: '4',
                    label: 'Alerts',
                    trend: null,
                    color: AppColors.danger),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Live Workers Section
            SectionHeader(
                title: 'Live Worker Locations',
                actionLabel: 'View Map',
                onAction: () {}),
            const SizedBox(height: AppSpacing.md),
            ..._buildWorkerRows(),
            const SizedBox(height: AppSpacing.xl),

            // Delivery Queue
            SectionHeader(
                title: 'Delivery Queue',
                actionLabel: 'View All',
                onAction: () {}),
            const SizedBox(height: AppSpacing.md),
            ...MockData.workerDeliveries.take(3).map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: DeliveryCard(
                    clientName: d.clientName,
                    address: d.address,
                    gallons: d.gallons,
                    priority: _priorityStr(d.priority),
                    status: _statusStr(d.status),
                  ),
                )),
            const SizedBox(height: AppSpacing.xl),

            // Revenue Chart placeholder
            SectionHeader(title: 'Revenue vs Expenses'),
            const SizedBox(height: AppSpacing.md),
            _RevenueChartPlaceholder(),
            const SizedBox(height: AppSpacing.xl),

            // Expense Breakdown
            SectionHeader(title: 'Expense Breakdown'),
            const SizedBox(height: AppSpacing.md),
            _ExpenseBreakdownCard(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWorkerRows() {
    return MockData.workers
        .map((w) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: EinhodCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          shape: BoxShape.circle),
                      child: Center(
                          child: Text(
                              w.name.split(' ').map((n) => n[0]).take(2).join(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700))),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.name, style: AppTypography.titleMedium),
                          Text(
                              '${w.todayCompletedDeliveries}/${w.totalDeliveriesToday} deliveries',
                              style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: w.gpsActive
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(w.gpsActive ? l10n.gpsActive : l10n.gpsOff,
                              style: AppTypography.bodySmall.copyWith(
                                  color: w.gpsActive
                                      ? AppColors.success
                                      : AppColors.textSecondary)),
                        ]),
                        const SizedBox(height: 4),
                        Text('🪣 ${w.gallonsRemaining} gal',
                            style: AppTypography.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ))
        .toList();
  }

  String _priorityStr(DeliveryPriority p) {
    switch (p) {
      case DeliveryPriority.urgent:
        return 'urgent';
      case DeliveryPriority.midUrgent:
        return 'midUrgent';
      case DeliveryPriority.normal:
        return 'normal';
    }
  }

  String _statusStr(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.pending:
        return 'pending';
      case DeliveryStatus.inProgress:
        return 'inProgress';
      case DeliveryStatus.completed:
        return 'completed';
      case DeliveryStatus.skipped:
        return 'skipped';
    }
  }
}

class _RevenueChartPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final months = ['Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan'];
    final revenue = [9800, 10500, 11200, 10900, 12100, 12450];
    final expenses = [6200, 6800, 7100, 6900, 7500, 7800];
    final maxVal = revenue.reduce((a, b) => a > b ? a : b).toDouble();

    return EinhodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.lastSixMonths, style: AppTypography.titleMedium),
              Row(
                children: [
                  _Legend('Revenue', AppColors.oceanBlue),
                  const SizedBox(width: AppSpacing.md),
                  _Legend('Expenses', AppColors.warning),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(months.length, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: (revenue[i] / maxVal) * 45,
                          decoration: BoxDecoration(
                            color: AppColors.oceanBlue,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: (expenses[i] / maxVal) * 45,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.7),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child:
                              Text(months[i], style: AppTypography.bodySmall),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;

  const _Legend(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }
}

class _ExpenseBreakdownCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = [
      ('Salaries', 0.45, AppColors.oceanBlue),
      ('Production', 0.25, AppColors.skyBlue),
      ('Dispensers', 0.12, AppColors.success),
      ('Operations', 0.10, AppColors.warning),
      ('Marketing', 0.08, AppColors.danger),
    ];

    return EinhodCard(
      child: Column(
        children: categories
            .map((cat) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: cat.$3, shape: BoxShape.circle)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                          child: Text(cat.$1, style: AppTypography.bodyMedium)),
                      Expanded(
                        flex: 2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: LinearProgressIndicator(
                            value: cat.$2,
                            backgroundColor: AppColors.divider,
                            valueColor: AlwaysStoppedAnimation<Color>(cat.$3),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 36,
                        child: Text('${(cat.$2 * 100).toInt()}%',
                            style: AppTypography.bodySmall
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Clients Tab ──────────────────────────────────────────────────────────────
class _ClientsTab extends StatefulWidget {
  const _ClientsTab();

  @override
  State<_ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<_ClientsTab> {
  String _searchQuery = '';
  String? _expandedId;

  final _clients = [
    MockData.sampleClient,
    ClientModel(
        id: 'c2',
        username: 'sara.hassan',
        name: 'Sara Hassan',
        phone: '+962799887766',
        address: '17 Zahran St',
        subscriptionType: 'Monthly',
        couponsRemaining: 0,
        totalCoupons: 0,
        subscriptionExpiry: DateTime.now().add(const Duration(days: 20)),
        outstandingDebt: 0),
    ClientModel(
        id: 'c3',
        username: 'omar.nasser',
        name: 'Omar Nasser',
        phone: '+962788776655',
        address: '8 Mecca St',
        subscriptionType: 'Coupon Book',
        couponsRemaining: 5,
        totalCoupons: 30,
        subscriptionExpiry: DateTime.now().subtract(const Duration(days: 2)),
        outstandingDebt: 45.0),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _clients
        .where((c) =>
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.phone.contains(_searchQuery))
        .toList();

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.clients),
        automaticallyImplyLeading: false,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showAddClientPanel(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Client'),
            style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm)),
          ),
          const SizedBox(width: AppSpacing.base),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Search by name or phone...',
                      prefixIcon:
                          Icon(Icons.search, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 13),
                  decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.inputBorder)),
                  child: Row(children: [
                    const Icon(Icons.filter_list,
                        color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Text(l10n.filter, style: AppTypography.bodyMedium),
                  ]),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) {
                final c = filtered[i];
                final isExpanded = _expandedId == c.id;
                return _ClientRow(
                  client: c,
                  isExpanded: isExpanded,
                  onTap: () =>
                      setState(() => _expandedId = isExpanded ? null : c.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddClientPanel(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.addNewClient, style: AppTypography.headlineLarge),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                  decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                  decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                  decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                decoration:
                    const InputDecoration(labelText: 'Subscription Type'),
                items: ['Coupon Book', 'Monthly', 'Annual']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancel))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.createUser))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  final ClientModel client;
  final bool isExpanded;
  final VoidCallback onTap;

  const _ClientRow(
      {required this.client, required this.isExpanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return EinhodCard(
      onTap: onTap,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.oceanBlue,
                  child: Text(
                      client.name.split(' ').map((n) => n[0]).take(2).join(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client.name, style: AppTypography.titleMedium),
                      Text(client.phone, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusChip(
                      label: client.isExpired
                          ? 'Expired'
                          : client.isExpiringSoon
                              ? 'Expiring Soon'
                              : 'Active',
                      color: client.isExpired
                          ? AppColors.danger
                          : client.isExpiringSoon
                              ? AppColors.warning
                              : AppColors.success,
                    ),
                    if (client.hasDebt) ...[
                      const SizedBox(height: 4),
                      StatusChip(
                          label:
                              '₪${client.outstandingDebt.toStringAsFixed(0)} Debt',
                          color: AppColors.danger),
                    ],
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
            if (isExpanded) ...[
              const Divider(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow('Subscription', client.subscriptionType),
                        _InfoRow('Expiry',
                            '${client.subscriptionExpiry.day}/${client.subscriptionExpiry.month}/${client.subscriptionExpiry.year}'),
                        if (client.couponsRemaining > 0)
                          _InfoRow('Coupons',
                              '${client.couponsRemaining}/${client.totalCoupons}'),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _ActionButton(
                          'View', AppColors.oceanBlue, Icons.visibility_outlined),
                      const SizedBox(width: AppSpacing.sm),
                      _ActionButton(
                          'Edit', AppColors.success, Icons.edit_outlined),
                      const SizedBox(width: AppSpacing.sm),
                      _ActionButton(
                          'Suspend', AppColors.warning, Icons.block_outlined),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: AppTypography.bodySmall),
          Text(value,
              style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _ActionButton(this.label, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Workers Tab ──────────────────────────────────────────────────────────────
class _WorkersTab extends StatelessWidget {
  const _WorkersTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('Workers'), automaticallyImplyLeading: false),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.base),
        itemCount: MockData.workers.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) {
          final w = MockData.workers[i];
          return EinhodCard(
            child: SingleChildScrollView(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        gradient: AppColors.heroGradient, shape: BoxShape.circle),
                    child: Center(
                        child: Text(
                            w.name.split(' ').map((n) => n[0]).take(2).join(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.name, style: AppTypography.titleMedium),
                        Text(w.jobTitle, style: AppTypography.bodySmall),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            StatusChip(
                                label: w.isOnShift ? 'On Shift' : 'Off',
                                color: w.isOnShift
                                    ? AppColors.success
                                    : AppColors.textSecondary),
                            const SizedBox(width: AppSpacing.sm),
                            Row(children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: w.gpsActive
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              Text(w.gpsActive ? l10n.gpsOn : l10n.gpsOff,
                                  style: AppTypography.bodySmall),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          '${w.todayCompletedDeliveries}/${w.totalDeliveriesToday}',
                          style: AppTypography.titleMedium
                              .copyWith(color: AppColors.oceanBlue)),
                      Text(l10n.deliveries.toLowerCase(), style: AppTypography.bodySmall),
                      if (w.pendingExpenses > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full)),
                          child: Text('${w.pendingExpenses} exp',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Deliveries Tab ───────────────────────────────────────────────────────────
class _DeliveriesTab extends StatelessWidget {
  const _DeliveriesTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('Deliveries'), automaticallyImplyLeading: false),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.base),
        itemCount: MockData.workerDeliveries.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) {
          final d = MockData.workerDeliveries[i];
          String priority = d.priority == DeliveryPriority.urgent
              ? 'urgent'
              : d.priority == DeliveryPriority.midUrgent
                  ? 'midUrgent'
                  : 'normal';
          String status = d.status == DeliveryStatus.completed
              ? 'completed'
              : d.status == DeliveryStatus.inProgress
                  ? 'inProgress'
                  : 'pending';
          return DeliveryCard(
            clientName: d.clientName,
            address: d.address,
            gallons: d.gallons,
            priority: priority,
            status: status,
            isDimmed: d.status == DeliveryStatus.completed,
          );
        },
      ),
    );
  }
}

// ─── Scheduling Tab ───────────────────────────────────────────────────────────
class _SchedulingTab extends StatefulWidget {
  const _SchedulingTab();

  @override
  State<_SchedulingTab> createState() => _SchedulingTabState();
}

class _SchedulingTabState extends State<_SchedulingTab> {
  final _schedules = <Map<String, dynamic>>[];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.scheduledDeliveries),
        automaticallyImplyLeading: false,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showAddScheduleDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.addSchedule),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            ),
          ),
          const SizedBox(width: AppSpacing.base),
        ],
      ),
      body: _schedules.isEmpty
          ? EmptyState(
              emoji: '📅',
              title: l10n.noSchedules,
              subtitle: l10n.noSchedulesDesc)
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.base),
              itemCount: _schedules.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) => _ScheduleCard(schedule: _schedules[i]),
            ),
    );
  }

  void _showAddScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddScheduleDialog(
        onSave: (schedule) {
          setState(() => _schedules.add(schedule));
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> schedule;

  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final scheduleType = schedule['scheduleType'] as String;
    final isActive = schedule['isActive'] as bool;
    final l10n = AppLocalizations.of(context)!;

    return EinhodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.oceanBlue.withOpacity(0.1)
                      : AppColors.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: isActive ? AppColors.oceanBlue : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(schedule['clientName'] as String,
                        style: AppTypography.titleMedium),
                    Text('${schedule['gallons']} ${l10n.gallons}',
                        style: AppTypography.bodySmall),
                  ],
                ),
              ),
              StatusChip(
                label: isActive ? l10n.active : l10n.inactive,
                color: isActive ? AppColors.success : AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ScheduleInfoItem(
                  icon: Icons.repeat,
                  label: _formatScheduleType(scheduleType, l10n),
                ),
              ),
              Expanded(
                child: _ScheduleInfoItem(
                  icon: Icons.access_time,
                  label: schedule['scheduleTime'] as String,
                ),
              ),
            ],
          ),
          if (scheduleType == 'weekly' || scheduleType == 'biweekly') ...[
            const SizedBox(height: AppSpacing.sm),
            _ScheduleInfoItem(
              icon: Icons.calendar_view_week,
              label: _formatDays(schedule['scheduleDays'] as List<int>, l10n),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(l10n.edit),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    isActive ? Icons.pause : Icons.play_arrow,
                    size: 16,
                  ),
                  label: Text(isActive ? l10n.pause : l10n.resume),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatScheduleType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'daily':
        return l10n.daily;
      case 'weekly':
        return l10n.weekly;
      case 'biweekly':
        return l10n.biweekly;
      case 'monthly':
        return l10n.monthly;
      default:
        return type;
    }
  }

  String _formatDays(List<int> days, AppLocalizations l10n) {
    final dayNames = [l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat, l10n.sun];
    return days.map((d) => dayNames[d - 1]).join(', ');
  }
}

class _ScheduleInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ScheduleInfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(label,
              style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _AddScheduleDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const _AddScheduleDialog({required this.onSave});

  @override
  State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClient;
  String? _selectedWorker;
  String _scheduleType = 'weekly';
  TimeOfDay _scheduleTime = const TimeOfDay(hour: 9, minute: 0);
  final _gallonsController = TextEditingController(text: '20');
  final _notesController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final Set<int> _selectedDays = {1, 3, 5}; // Mon, Wed, Fri

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.calendar_today,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(l10n.addDeliverySchedule,
                          style: AppTypography.headlineLarge),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Client Selection
                Text(l10n.client, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  value: _selectedClient,
                  decoration: InputDecoration(
                    hintText: l10n.selectClient,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  items: ['Ahmed Khalil', 'Sara Hassan', 'Omar Nasser']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedClient = v),
                  validator: (v) => v == null ? l10n.selectClient : null,
                ),
                const SizedBox(height: AppSpacing.base),

                // Worker Assignment
                Text(l10n.assignWorkerOptional,
                    style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  value: _selectedWorker,
                  decoration: InputDecoration(
                    hintText: l10n.autoAssignOrSelectWorker,
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  items: [l10n.autoAssign, 'Mahmoud Ali', 'Fatima Nasser']
                      .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedWorker = v),
                ),
                const SizedBox(height: AppSpacing.base),

                // Gallons
                Text(l10n.gallons, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _gallonsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: l10n.enterGallons,
                    prefixIcon: const Icon(Icons.water_drop_outlined),
                    suffixText: 'gal',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? l10n.enterGallons : null,
                ),
                const SizedBox(height: AppSpacing.base),

                // Schedule Type
                Text(l10n.scheduleType, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    _ScheduleTypeChip(
                      label: l10n.daily,
                      value: 'daily',
                      selected: _scheduleType == 'daily',
                      onTap: () => setState(() => _scheduleType = 'daily'),
                    ),
                    _ScheduleTypeChip(
                      label: l10n.weekly,
                      value: 'weekly',
                      selected: _scheduleType == 'weekly',
                      onTap: () => setState(() => _scheduleType = 'weekly'),
                    ),
                    _ScheduleTypeChip(
                      label: l10n.biweekly,
                      value: 'biweekly',
                      selected: _scheduleType == 'biweekly',
                      onTap: () => setState(() => _scheduleType = 'biweekly'),
                    ),
                    _ScheduleTypeChip(
                      label: l10n.monthly,
                      value: 'monthly',
                      selected: _scheduleType == 'monthly',
                      onTap: () => setState(() => _scheduleType = 'monthly'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),

                // Days Selection (for weekly/biweekly)
                if (_scheduleType == 'weekly' || _scheduleType == 'biweekly') ...[
                  Text(l10n.deliveryDays, style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      _DayChip(
                        label: l10n.mon,
                        value: 1,
                        selected: _selectedDays.contains(1),
                        onTap: () => _toggleDay(1),
                      ),
                      _DayChip(
                        label: l10n.tue,
                        value: 2,
                        selected: _selectedDays.contains(2),
                        onTap: () => _toggleDay(2),
                      ),
                      _DayChip(
                        label: l10n.wed,
                        value: 3,
                        selected: _selectedDays.contains(3),
                        onTap: () => _toggleDay(3),
                      ),
                      _DayChip(
                        label: l10n.thu,
                        value: 4,
                        selected: _selectedDays.contains(4),
                        onTap: () => _toggleDay(4),
                      ),
                      _DayChip(
                        label: l10n.fri,
                        value: 5,
                        selected: _selectedDays.contains(5),
                        onTap: () => _toggleDay(5),
                      ),
                      _DayChip(
                        label: l10n.sat,
                        value: 6,
                        selected: _selectedDays.contains(6),
                        onTap: () => _toggleDay(6),
                      ),
                      _DayChip(
                        label: l10n.sun,
                        value: 7,
                        selected: _selectedDays.contains(7),
                        onTap: () => _toggleDay(7),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.base),
                ],

                // Time Selection
                Text(l10n.deliveryTime, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _scheduleTime,
                    );
                    if (time != null) {
                      setState(() => _scheduleTime = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.md),
                        Text(_scheduleTime.format(context),
                            style: AppTypography.bodyMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),

                // Date Range
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.startDate, style: AppTypography.titleMedium),
                          const SizedBox(height: AppSpacing.sm),
                          GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime.now(),
                                lastDate:
                                    DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => _startDate = date);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.inputBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                      style: AppTypography.bodyMedium),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.endDateOptional,
                              style: AppTypography.titleMedium),
                          const SizedBox(height: AppSpacing.sm),
                          GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? _startDate,
                                firstDate: _startDate,
                                lastDate:
                                    DateTime.now().add(const Duration(days: 365)),
                              );
                              setState(() => _endDate = date);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.inputBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                      _endDate == null
                                          ? l10n.noEndDate
                                          : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                                      style: AppTypography.bodyMedium),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),

                // Notes
                Text(l10n.notesOptional, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.addSpecialInstructions,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveSchedule,
                        child: Text(l10n.createSchedule),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  void _saveSchedule() {
    if (_formKey.currentState!.validate()) {
      if ((_scheduleType == 'weekly' || _scheduleType == 'biweekly') &&
          _selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.selectAtLeastOneDay)),
        );
        return;
      }

      widget.onSave({
        'clientName': _selectedClient!,
        'workerName': _selectedWorker ?? AppLocalizations.of(context)!.autoAssign,
        'gallons': int.parse(_gallonsController.text),
        'scheduleType': _scheduleType,
        'scheduleTime': _scheduleTime.format(context),
        'scheduleDays': _selectedDays.toList()..sort(),
        'startDate': _startDate,
        'endDate': _endDate,
        'notes': _notesController.text,
        'isActive': true,
      });
    }
  }

  @override
  void dispose() {
    _gallonsController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class _ScheduleTypeChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _ScheduleTypeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.oceanBlue
              : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? AppColors.oceanBlue : AppColors.inputBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: selected ? AppColors.oceanBlue : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.oceanBlue : AppColors.inputBorder,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dispensers Tab ───────────────────────────────────────────────────────────
class _DispensersTab extends StatelessWidget {
  const _DispensersTab();

  final _dispensers = const [
    ('WD-2200-A4B1', 'Water Dispenser WD-2200', 'Ahmed Khalil', 'Active', true),
    ('WD-3100-B2C3', 'Water Dispenser WD-3100', 'Sara Hassan', 'Active', true),
    ('WD-1500-D4E5', 'Water Dispenser WD-1500', 'Warehouse', 'Disabled', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dispensers'),
        automaticallyImplyLeading: false,
        actions: [
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Register'),
            style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm)),
          ),
          const SizedBox(width: AppSpacing.base),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.base),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.85,
        ),
        itemCount: _dispensers.length,
        itemBuilder: (_, i) {
          final d = _dispensers[i];
          return EinhodCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Center(
                      child: Text('🫧', style: TextStyle(fontSize: 40))),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(d.$1, style: AppTypography.bodySmall),
                Text(d.$2,
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Row(children: [
                  const Icon(Icons.person_outline,
                      size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(d.$3,
                          style: AppTypography.bodySmall,
                          overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: AppSpacing.sm),
                StatusChip(
                    label: d.$4,
                    color: d.$5 ? AppColors.success : AppColors.textSecondary),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Finances Tab ─────────────────────────────────────────────────────────────
class _FinancesTab extends StatelessWidget {
  const _FinancesTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Finances'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Income'),
              Tab(text: 'Expenses'),
              Tab(text: 'P&L'),
              Tab(text: 'Budget'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FinanceSummary(
                title: 'Total Income',
                value: '₪12,450',
                trend: '+23%',
                color: AppColors.success),
            _FinanceSummary(
                title: 'Total Expenses',
                value: '₪7,800',
                trend: '+8%',
                color: AppColors.warning),
            _PnLView(),
            _BudgetView(),
          ],
        ),
      ),
    );
  }
}

class _FinanceSummary extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final Color color;

  const _FinanceSummary(
      {required this.title,
      required this.value,
      required this.trend,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        children: [
          EinhodCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(value,
                    style: AppTypography.displayLarge.copyWith(color: color)),
                Text('$trend vs last month',
                    style: AppTypography.bodySmall.copyWith(color: color)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          ...List.generate(
              5,
              (i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: EinhodCard(
                      child: Row(
                        children: [
                          Expanded(
                              child: Text('Transaction ${i + 1}',
                                  style: AppTypography.titleMedium)),
                          Text('₪${(200 + i * 150)}',
                              style: AppTypography.titleMedium
                                  .copyWith(color: color)),
                        ],
                      ),
                    ),
                  )),
        ],
      ),
    );
  }
}

class _PnLView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        children: [
          EinhodCard(
            child: Column(
              children: [
                _PnLRow('Total Revenue', '₪12,450', AppColors.success),
                const Divider(height: AppSpacing.xl),
                _PnLRow('Total Expenses', '₪7,800', AppColors.danger),
                const Divider(height: AppSpacing.xl),
                _PnLRow('Net Profit', '₪4,650', AppColors.oceanBlue,
                    bold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PnLRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _PnLRow(this.label, this.value, this.color, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: bold ? AppTypography.titleLarge : AppTypography.bodyMedium),
        Text(value,
            style:
                (bold ? AppTypography.headlineLarge : AppTypography.titleMedium)
                    .copyWith(color: color)),
      ],
    );
  }
}

class _BudgetView extends StatelessWidget {
  final _categories = [
    ('Salaries', 0.90, '\$4,500/\$5,000'),
    ('Production', 0.65, '\$1,625/\$2,500'),
    ('Dispensers', 0.40, '\$400/\$1,000'),
    ('Operations', 0.75, '\$750/\$1,000'),
    ('Marketing', 0.55, '\$275/\$500'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: _categories
          .map((cat) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: EinhodCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(cat.$1, style: AppTypography.titleMedium),
                          Text(cat.$3, style: AppTypography.bodySmall),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: cat.$2,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              cat.$2 > 0.85
                                  ? AppColors.danger
                                  : AppColors.oceanBlue),
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('${(cat.$2 * 100).toInt()}% used',
                          style: AppTypography.bodySmall.copyWith(
                              color: cat.$2 > 0.85
                                  ? AppColors.danger
                                  : AppColors.textSecondary)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ─── Reports & Settings Tabs ──────────────────────────────────────────────────
class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('Reports'), automaticallyImplyLeading: false),
      body: const EmptyState(
          emoji: '📊',
          title: 'Reports',
          subtitle: 'Generate and export financial and operational reports'),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final sections = [
      ('🔔', 'Notification Server', 'Configure push notifications'),
      ('💳', 'Payment Gateway', 'Payment credentials and settings'),
      ('📍', 'GPS Settings', 'Update interval: 30s'),
      ('🔵', 'Geofence Radius', '1 km proximity alerts'),
      ('🪣', 'Low Inventory Alert', 'Threshold: 10 gallons'),
      ('📅', 'Subscription Reminders', '7 days and 1 day before expiry'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('System Settings'),
          automaticallyImplyLeading: false),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.base),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) {
          final s = sections[i];
          return EinhodCard(
            onTap: () {},
            child: Row(
              children: [
                Text(s.$1, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$2, style: AppTypography.titleMedium),
                      Text(s.$3, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          );
        },
      ),
    );
  }
}
