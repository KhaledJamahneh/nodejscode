import 'package:flutter/material.dart';
import 'package:einhod_water/core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';

class WorkerHomeScreen extends StatefulWidget {
  final WorkerModel worker;
  const WorkerHomeScreen({super.key, required this.worker});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  int _selectedTab = 0;
  late bool _gpsActive = widget.worker.gpsActive;
  late int _gallonsRemaining = widget.worker.gallonsRemaining;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _DeliveriesTab(
        gpsActive: _gpsActive,
        gallonsRemaining: _gallonsRemaining,
        onGpsToggle: (v) => setState(() => _gpsActive = v),
        onGallonsUpdate: () => _showGallonsUpdateSheet(),
      ),
      const _MapTab(),
      const _ExpensesTab(),
      _WorkerProfileTab(worker: widget.worker),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: EinhodAppBar(
        title: 'Deliveries',
        showNotificationBell: true,
        notificationCount: 2,
      ),
      body: IndexedStack(index: _selectedTab, children: tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            color: AppColors.white, boxShadow: AppShadows.elevated),
        child: BottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (i) => setState(() => _selectedTab = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.local_shipping_outlined),
                activeIcon: Icon(Icons.local_shipping),
                label: 'Deliveries'),
            BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'Map'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_outlined),
                activeIcon: Icon(Icons.receipt),
                label: 'Expenses'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }

  void _showGallonsUpdateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GallonsUpdateSheet(
        current: _gallonsRemaining,
        onUpdate: (v) => setState(() => _gallonsRemaining = v),
      ),
    );
  }
}

// ─── Deliveries Tab ───────────────────────────────────────────────────────────
class _DeliveriesTab extends StatefulWidget {
  final bool gpsActive;
  final int gallonsRemaining;
  final ValueChanged<bool> onGpsToggle;
  final VoidCallback onGallonsUpdate;

  const _DeliveriesTab({
    required this.gpsActive,
    required this.gallonsRemaining,
    required this.onGpsToggle,
    required this.onGallonsUpdate,
  });

  @override
  State<_DeliveriesTab> createState() => _DeliveriesTabState();
}

class _DeliveriesTabState extends State<_DeliveriesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _mainDeliveries = MockData.workerDeliveries
      .where((d) => d.priority == DeliveryPriority.normal)
      .toList();
  final _requestDeliveries = MockData.workerDeliveries
      .where((d) => d.priority != DeliveryPriority.normal)
      .toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // GPS Toggle
        GpsToggleBanner(
            isActive: widget.gpsActive, onToggle: widget.onGpsToggle),

        // Gallons indicator
        GallonsIndicator(
          current: widget.gallonsRemaining,
          max: 100,
          onTap: widget.onGallonsUpdate,
        ),

        // Tab bar
        Container(
          color: AppColors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.oceanBlue,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.oceanBlue,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: 'Main List (${_mainDeliveries.length})'),
              Tab(text: 'Requests (${_requestDeliveries.length})'),
            ],
          ),
        ),

        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _DeliveryList(deliveries: _mainDeliveries, showPriority: false),
              _DeliveryList(deliveries: _requestDeliveries, showPriority: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeliveryList extends StatelessWidget {
  final List<DeliveryModel> deliveries;
  final bool showPriority;

  const _DeliveryList({required this.deliveries, required this.showPriority});

  String _priorityString(DeliveryPriority p) {
    switch (p) {
      case DeliveryPriority.urgent:
        return 'urgent';
      case DeliveryPriority.midUrgent:
        return 'midUrgent';
      case DeliveryPriority.normal:
        return 'normal';
    }
  }

  String _statusString(DeliveryStatus s) {
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

  @override
  Widget build(BuildContext context) {
    if (deliveries.isEmpty) {
      return const EmptyState(
          emoji: '✅',
          title: 'No deliveries',
          subtitle: 'Looking good! No pending deliveries');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.base),
      itemCount: deliveries.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final d = deliveries[i];
        return DeliveryCard(
          clientName: d.clientName,
          address: d.address,
          gallons: d.gallons,
          priority: _priorityString(d.priority),
          status: _statusString(d.status),
          isDimmed: d.status == DeliveryStatus.completed,
          onRecord: d.status != DeliveryStatus.completed
              ? () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _RecordDeliverySheet(delivery: d),
                  )
              : null,
        );
      },
    );
  }
}

// ─── Record Delivery Sheet ────────────────────────────────────────────────────
class _RecordDeliverySheet extends StatefulWidget {
  final DeliveryModel delivery;

  const _RecordDeliverySheet({required this.delivery});

  @override
  State<_RecordDeliverySheet> createState() => _RecordDeliverySheetState();
}

class _RecordDeliverySheetState extends State<_RecordDeliverySheet> {
  int _gallons = 2;
  bool _locationCaptured = true;
  bool _notesExpanded = false;
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppRadius.full)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(l10n.recordDelivery, style: AppTypography.headlineLarge),
            const SizedBox(height: AppSpacing.xs),

            EinhodCard(
              color: AppColors.oceanBlue.withOpacity(0.06),
              child: Text(widget.delivery.clientName,
                  style: AppTypography.headlineMedium
                      .copyWith(color: AppColors.oceanBlue)),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Gallons
            Text(l10n.gallonsDelivered, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _gallons > 1 ? setState(() => _gallons--) : null,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.inputBorder)),
                    child: const Icon(Icons.remove, size: 24),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Text('$_gallons',
                      style: AppTypography.displayLarge
                          .copyWith(color: AppColors.oceanBlue, fontSize: 48)),
                ),
                GestureDetector(
                  onTap: () => setState(() => _gallons++),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: AppColors.oceanBlue,
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),

            // GPS indicator
            Row(
              children: [
                Icon(Icons.location_on,
                    color: _locationCaptured
                        ? AppColors.success
                        : AppColors.textSecondary,
                    size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _locationCaptured
                      ? 'Location captured ✓'
                      : 'Capturing location...',
                  style: AppTypography.bodySmall.copyWith(
                    color: _locationCaptured
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Notes (collapsible)
            GestureDetector(
              onTap: () => setState(() => _notesExpanded = !_notesExpanded),
              child: Row(
                children: [
                  Icon(
                      _notesExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size: 18),
                  Text(l10n.addNotes,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (_notesExpanded) ...[
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Any notes...')),
            ],
            const SizedBox(height: AppSpacing.xl),

            // Photo & Submit row
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.inputBorder)),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: 'Confirm Delivery / تأكيد التوصيل',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Delivery confirmed!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gallons Update Sheet ─────────────────────────────────────────────────────
class _GallonsUpdateSheet extends StatefulWidget {
  final int current;
  final ValueChanged<int> onUpdate;

  const _GallonsUpdateSheet({required this.current, required this.onUpdate});

  @override
  State<_GallonsUpdateSheet> createState() => _GallonsUpdateSheetState();
}

class _GallonsUpdateSheetState extends State<_GallonsUpdateSheet> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.updateGallonsRemaining, style: AppTypography.headlineLarge),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _value > 0 ? setState(() => _value--) : null,
                child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.inputBorder)),
                    child: const Icon(Icons.remove)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Text('$_value', style: AppTypography.displayLarge),
              ),
              GestureDetector(
                onTap: () => setState(() => _value++),
                child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: AppColors.oceanBlue,
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: const Icon(Icons.add, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Update',
            onTap: () {
              widget.onUpdate(_value);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Map Tab ──────────────────────────────────────────────────────────────────
class _MapTab extends StatelessWidget {
  const _MapTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        // Placeholder map
        Container(
          color: const Color(0xFFE8F0F7),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map, size: 80, color: AppColors.oceanBlue),
                const SizedBox(height: AppSpacing.base),
                Text(l10n.liveMap, style: AppTypography.headlineLarge),
                Text('(flutter_map integration)',
                    style: AppTypography.bodyMedium),
              ],
            ),
          ),
        ),
        // Bottom panel
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: AppShadows.elevated,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl))),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.nextStops, style: AppTypography.headlineMedium),
                const SizedBox(height: AppSpacing.md),
                ...MockData.workerDeliveries.take(3).map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                                color: AppColors.oceanBlue,
                                shape: BoxShape.circle),
                            child: Center(
                                child: Text('📍',
                                    style: const TextStyle(fontSize: 14))),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                  d.clientName,
                                  style: AppTypography.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  d.address,
                                  style: AppTypography.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ])),
                          Text(
                              '~${1 + MockData.workerDeliveries.indexOf(d) * 3} km',
                              style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.oceanBlue,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Expenses Tab ─────────────────────────────────────────────────────────────
class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _ExpenseFormSheet(),
        ),
        backgroundColor: AppColors.oceanBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(l10n.submitExpense,
            style: AppTypography.labelLarge.copyWith(color: Colors.white)),
      ),
      body: const EmptyState(
        emoji: '🧾',
        title: 'No expenses submitted yet',
        subtitle: 'Tap the button below to submit an expense',
      ),
    );
  }
}

class _ExpenseFormSheet extends StatefulWidget {
  const _ExpenseFormSheet();

  @override
  State<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<_ExpenseFormSheet> {
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _descController = TextEditingController();
  String _paymentMethod = 'myPocket';
  bool _hasReceipt = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(AppRadius.full))),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.submitExpense, style: AppTypography.headlineLarge),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Amount  (₪)',
                    prefixIcon: Icon(Icons.attach_money_outlined,
                        color: AppColors.textSecondary))),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                    labelText: 'Merchant Name',
                    prefixIcon: Icon(Icons.store_outlined,
                        color: AppColors.textSecondary))),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: AppSpacing.base),
            Text(l10n.paymentMethod, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                ('myPocket', 'My Pocket'),
                ('company', 'Company'),
                ('unpaid', 'Unpaid'),
              ]
                  .map((opt) => Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _paymentMethod = opt.$1),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: _paymentMethod == opt.$1
                                  ? AppColors.oceanBlue
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                  color: _paymentMethod == opt.$1
                                      ? AppColors.oceanBlue
                                      : AppColors.inputBorder),
                            ),
                            child: Text(opt.$2,
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall.copyWith(
                                    color: _paymentMethod == opt.$1
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.base),
            GestureDetector(
              onTap: () => setState(() => _hasReceipt = !_hasReceipt),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: _hasReceipt
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: _hasReceipt
                          ? AppColors.success
                          : AppColors.inputBorder,
                      width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        _hasReceipt
                            ? Icons.check_circle
                            : Icons.camera_alt_outlined,
                        color: _hasReceipt
                            ? AppColors.success
                            : AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                        _hasReceipt
                            ? 'Receipt captured ✓'
                            : 'Scan Receipt (Required)',
                        style: AppTypography.bodyMedium.copyWith(
                            color: _hasReceipt
                                ? AppColors.success
                                : AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Submit / إرسال',
              onTap: _hasReceipt
                  ? () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(l10n.expenseSubmitted),
                          backgroundColor: AppColors.success));
                    }
                  : null,
              backgroundColor: _hasReceipt ? null : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Worker Profile ───────────────────────────────────────────────────────────
class _WorkerProfileTab extends StatelessWidget {
  final WorkerModel worker;
  const _WorkerProfileTab({required this.worker});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        children: [
          EinhodCard(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      gradient: AppColors.heroGradient, shape: BoxShape.circle),
                  child: Center(
                      child: Text(
                          worker.name
                              .split(' ')
                              .map((n) => n[0])
                              .take(2)
                              .join(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(worker.name, style: AppTypography.headlineMedium),
                      Text(worker.jobTitle, style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.xs),
                      StatusChip(
                          label: worker.isOnShift ? 'On Shift' : 'Off Shift',
                          color: worker.isOnShift
                              ? AppColors.success
                              : AppColors.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          EinhodCard(
            child: Column(
              children: [
                _StatRow('Today\'s Deliveries',
                    '${worker.todayCompletedDeliveries}/${worker.totalDeliveriesToday}'),
                const Divider(height: AppSpacing.xl),
                _StatRow('Pending Expenses', '${worker.pendingExpenses}'),
                const Divider(height: AppSpacing.xl),
                _StatRow('Phone', worker.phone),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Text(value,
            style:
                AppTypography.titleMedium.copyWith(color: AppColors.oceanBlue)),
      ],
    );
  }
}
