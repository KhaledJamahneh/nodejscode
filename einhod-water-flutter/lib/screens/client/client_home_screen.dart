import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:einhod_water/core/theme/app_theme.dart';
import 'package:einhod_water/core/widgets/widgets.dart';
import '../../models/models.dart';
import 'notifications_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  final ClientModel client;
  const ClientHomeScreen({super.key, required this.client});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _selectedTab = 0;
  late final _client = widget.client;
  final _deliveries = MockData.recentDeliveries;
  final _notifications = MockData.notifications;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _HomeTab(
          client: _client,
          deliveries: _deliveries,
          onRequestDelivery: _showDeliveryRequestSheet),
      const ClientRequestsTab(),
      NotificationsScreen(notifications: _notifications),
      ClientProfileTab(client: _client),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: EinhodAppBar(
        title: 'Einhod Pure Water',
        notificationCount: _notifications.where((n) => !n.isRead).length,
        onNotificationTap: () => setState(() => _selectedTab = 2),
      ),
      body: IndexedStack(index: _selectedTab, children: tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: AppShadows.elevated,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (i) => setState(() => _selectedTab = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.local_shipping_outlined),
                activeIcon: Icon(Icons.local_shipping),
                label: 'Requests'),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications_outlined),
                activeIcon: Icon(Icons.notifications),
                label: 'Notifications'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }

  void _showDeliveryRequestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryRequestSheet(client: _client),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final ClientModel client;
  final List<DeliveryModel> deliveries;
  final VoidCallback onRequestDelivery;

  const _HomeTab(
      {required this.client,
      required this.deliveries,
      required this.onRequestDelivery});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text('Good morning, ${client.name.split(' ').first} 👋',
              style: AppTypography.headlineLarge),
          const SizedBox(height: AppSpacing.base),

          // Hero Subscription Card
          _HeroSubscriptionCard(client: client),
          const SizedBox(height: AppSpacing.base),

          // Debt Alert Banner
          if (client.hasDebt) ...[
            _DebtAlertBanner(amount: client.outstandingDebt),
            const SizedBox(height: AppSpacing.base),
          ],

          // Quick Action Button
          GestureDetector(
            onTap: onRequestDelivery,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(AppRadius.base),
                boxShadow: AppShadows.button,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🚰', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Request Water Delivery',
                    style: AppTypography.headlineMedium
                        .copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Recent Deliveries
          SectionHeader(
            title: 'Recent Deliveries',
            actionLabel: 'View All',
            onAction: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          ...deliveries.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _DeliveryHistoryCard(delivery: d),
              )),

          const SizedBox(height: AppSpacing.xl),

          // Announcements
          SectionHeader(title: 'Announcements'),
          const SizedBox(height: AppSpacing.md),
          const _AnnouncementsCarousel(),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ─── Hero Subscription Card ───────────────────────────────────────────────────
class _HeroSubscriptionCard extends StatelessWidget {
  final ClientModel client;

  const _HeroSubscriptionCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final ratio = client.couponsRemaining / client.totalCoupons;
    final ringColor = client.couponsRemaining <= 10
        ? AppColors.danger
        : client.couponsRemaining <= 20
            ? AppColors.warning
            : AppColors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.elevated,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        client.subscriptionType,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Coupons Remaining',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${client.couponsRemaining}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              height: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Expanded(
                            // Added Expanded
                            child: Text(
                              '/ ${client.totalCoupons}',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 16),
                              maxLines: 1, // Added maxLines
                              overflow: TextOverflow.ellipsis, // Added overflow
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Circular Progress Ring
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(90, 90),
                      painter: _CircleProgressPainter(
                          progress: ratio, color: ringColor),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(ratio * 100).toInt()}%',
                          style: TextStyle(
                              color: ringColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          // Expiry chip
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: client.daysUntilExpiry <= 7
                  ? AppColors.danger.withOpacity(0.3)
                  : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: client.daysUntilExpiry <= 1
                  ? Border.all(color: Colors.white, width: 1)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, color: Colors.white70, size: 14),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Expires in ${client.daysUntilExpiry} days',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircleProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final strokeWidth = 6.0;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) => old.progress != progress;
}

// ─── Debt Alert Banner ────────────────────────────────────────────────────────
class _DebtAlertBanner extends StatelessWidget {
  final double amount;

  const _DebtAlertBanner({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:
            Border.all(color: AppColors.danger.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_rounded,
                color: AppColors.danger, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outstanding Balance',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.danger),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₪${amount.toStringAsFixed(2)}',
                  style: AppTypography.displayMedium
                      .copyWith(color: AppColors.danger),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'Pay Now',
                style: AppTypography.bodySmall
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Delivery History Card ────────────────────────────────────────────────────
class _DeliveryHistoryCard extends StatefulWidget {
  final DeliveryModel delivery;

  const _DeliveryHistoryCard({required this.delivery});

  @override
  State<_DeliveryHistoryCard> createState() => _DeliveryHistoryCardState();
}

class _DeliveryHistoryCardState extends State<_DeliveryHistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.delivery;
    return EinhodCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Center(
                    child: Text('✓',
                        style: TextStyle(
                            color: AppColors.success,
                            fontSize: 20,
                            fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${d.gallons} Gallons Delivered',
                      style: AppTypography.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${d.date.day}/${d.date.month}/${d.date.year}',
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusChip(label: '✓ Delivered', color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
          if (_expanded) ...[
            const Divider(height: AppSpacing.xl),
            _DetailRow(label: 'Address', value: d.address),
            _DetailRow(label: 'Priority', value: d.priority.name),
            _DetailRow(label: 'Delivery ID', value: d.id.toUpperCase()),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Expanded(
              // Added Expanded
              child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )),
        ],
      ),
    );
  }
}

// ─── Announcements Carousel ───────────────────────────────────────────────────
class _AnnouncementsCarousel extends StatefulWidget {
  const _AnnouncementsCarousel();

  @override
  State<_AnnouncementsCarousel> createState() => _AnnouncementsCarouselState();
}

class _AnnouncementsCarouselState extends State<_AnnouncementsCarousel> {
  final _controller = PageController(viewportFraction: 0.88);
  int _current = 0;

  final _items = [
    (
      '🎉',
      'Summer Promotion',
      'Get 10% off your next subscription renewal this month!',
      AppColors.skyBlue
    ),
    (
      '💧',
      'New Dispenser Models',
      'Check out our latest smart dispensers with UV purification',
      AppColors.oceanBlue
    ),
    (
      '🌿',
      'Eco Initiative',
      'We\'ve reduced plastic by 40% — thank you for your support!',
      AppColors.success
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _controller,
            itemCount: _items.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final item = _items[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [item.$4, item.$4.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.base),
                ),
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Row(
                  children: [
                    Text(item.$1, style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.$2,
                              style: AppTypography.titleMedium
                                  .copyWith(color: Colors.white)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(item.$3,
                              style: AppTypography.bodySmall
                                  .copyWith(color: Colors.white70),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              _items.length,
              (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _current ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _current
                          ? AppColors.oceanBlue
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  )),
        ),
      ],
    );
  }
}

// ─── Requests Tab ─────────────────────────────────────────────────────────────
class ClientRequestsTab extends StatelessWidget {
  const ClientRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      emoji: '🚰',
      title: 'No pending requests',
      subtitle: 'Your delivery requests will appear here',
      actionLabel: 'Request Delivery',
      onAction: () {},
    );
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────
class ClientProfileTab extends StatelessWidget {
  final ClientModel client;
  const ClientProfileTab({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          EinhodCard(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      client.name.split(' ').map((n) => n[0]).take(2).join(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: AppTypography.headlineMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        client.phone,
                        style: AppTypography.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.lock_outline,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(
                            client.username,
                            style: AppTypography.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.oceanBlue),
                    onPressed: () {}),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          // Subscription details
          EinhodCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subscription', style: AppTypography.titleLarge),
                const Divider(height: AppSpacing.xl),
                _DetailRow(label: 'Type', value: client.subscriptionType),
                _DetailRow(
                    label: 'Expires',
                    value:
                        '${client.subscriptionExpiry.day}/${client.subscriptionExpiry.month}/${client.subscriptionExpiry.year}'),
                _DetailRow(
                    label: 'Remaining Coupons',
                    value: '${client.couponsRemaining}/${client.totalCoupons}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          // Assets
          EinhodCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Company Assets', style: AppTypography.titleLarge),
                const Divider(height: AppSpacing.xl),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Center(
                        child: Text('🫧', style: TextStyle(fontSize: 24))),
                  ),
                  title: Text('Water Dispenser WD-2200',
                      style: AppTypography.titleMedium),
                  subtitle: Text('Serial: WD-2200-A4B1',
                      style: AppTypography.bodySmall),
                  trailing:
                      StatusChip(label: 'Active', color: AppColors.success),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Delivery Request Sheet ───────────────────────────────────────────────────
class DeliveryRequestSheet extends StatefulWidget {
  final ClientModel client;

  const DeliveryRequestSheet({super.key, required this.client});

  @override
  State<DeliveryRequestSheet> createState() => _DeliveryRequestSheetState();
}

class _DeliveryRequestSheetState extends State<DeliveryRequestSheet> {
  int _step = 0;
  String? _selectedPriority;
  int _gallons = 2;
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: AppSpacing.base),
          StepIndicator(totalSteps: 3, currentStep: _step),
          const SizedBox(height: AppSpacing.xl),
          if (_step == 0)
            _PriorityStep(
              selected: _selectedPriority,
              onSelect: (p) => setState(() => _selectedPriority = p),
              onNext: () =>
                  _selectedPriority != null ? setState(() => _step = 1) : null,
            ),
          if (_step == 1)
            _DetailsStep(
              address: widget.client.address ?? '',
              gallons: _gallons,
              notesController: _notesController,
              onGallonsChanged: (v) => setState(() => _gallons = v),
              onNext: () => setState(() => _step = 2),
              onBack: () => setState(() => _step = 0),
            ),
          if (_step == 2)
            _ConfirmStep(
              priority: _selectedPriority!,
              address: widget.client.address ?? '',
              gallons: _gallons,
              onSubmit: () {
                Navigator.pop(context);
                _showSuccess(context);
              },
              onBack: () => setState(() => _step = 1),
            ),
        ],
      ),
    );
  }

  void _showSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💧', style: TextStyle(fontSize: 64)),
              const SizedBox(height: AppSpacing.base),
              Text('Request Received!',
                  style: AppTypography.headlineLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text('تم استلام الطلب',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.skyBlue)),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: 'Done', onTap: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback? onNext;

  const _PriorityStep(
      {required this.selected, required this.onSelect, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final options = [
      (
        'urgent',
        '🔴',
        'Urgent',
        'I need water today, as soon as possible',
        AppColors.urgent
      ),
      (
        'midUrgent',
        '🟡',
        'Mid-Urgent',
        'I need water today',
        AppColors.midUrgent
      ),
      ('normal', '🟢', 'Non-Urgent', 'Whenever available', AppColors.normal),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Priority', style: AppTypography.headlineLarge),
          const SizedBox(height: AppSpacing.sm),
          Text('How urgently do you need water?',
              style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          ...options.map((opt) {
            final isSelected = selected == opt.$1;
            return GestureDetector(
              onTap: () => onSelect(opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: isSelected ? opt.$5.withOpacity(0.08) : AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected ? opt.$5 : AppColors.inputBorder,
                    width: isSelected ? 2 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(opt.$2, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(opt.$3,
                              style: AppTypography.titleMedium
                                  .copyWith(color: opt.$5)),
                          Text(opt.$4, style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    if (isSelected) Icon(Icons.check_circle, color: opt.$5),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.base),
          PrimaryButton(
              label: 'Next',
              onTap: onNext,
              backgroundColor: selected == null ? AppColors.divider : null),
        ],
      ),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  final String address;
  final int gallons;
  final TextEditingController notesController;
  final ValueChanged<int> onGallonsChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _DetailsStep({
    required this.address,
    required this.gallons,
    required this.notesController,
    required this.onGallonsChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delivery Details', style: AppTypography.headlineLarge),
          const SizedBox(height: AppSpacing.xl),
          EinhodCard(
            color: AppColors.background,
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: AppColors.oceanBlue),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(address, style: AppTypography.bodyMedium)),
                TextButton(onPressed: () {}, child: const Text('Change')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text('Quantity (gallons)', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => gallons > 1 ? onGallonsChanged(gallons - 1) : null,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: const Icon(Icons.remove),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text('$gallons',
                    style: AppTypography.displayLarge
                        .copyWith(color: AppColors.oceanBlue)),
              ),
              GestureDetector(
                onTap: () => onGallonsChanged(gallons + 1),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.oceanBlue,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          TextFormField(
            controller: notesController,
            decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any special instructions?'),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: onBack, child: const Text('Back'))),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: ElevatedButton(
                      onPressed: onNext, child: const Text('Next'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  final String priority;
  final String address;
  final int gallons;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _ConfirmStep({
    required this.priority,
    required this.address,
    required this.gallons,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirm Request', style: AppTypography.headlineLarge),
          const SizedBox(height: AppSpacing.xl),
          EinhodCard(
            color: AppColors.background,
            child: Column(
              children: [
                _DetailRow(
                    label: 'Priority',
                    value: priority
                        .replaceAll('midUrgent', 'Mid-Urgent')
                        .replaceAll('normal', 'Non-Urgent')
                        .replaceAll('urgent', 'Urgent')),
                const Divider(height: AppSpacing.xl),
                _DetailRow(label: 'Address', value: address),
                const Divider(height: AppSpacing.xl),
                _DetailRow(label: 'Quantity', value: '$gallons gallons'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: 'Submit Request / إرسال الطلب', onTap: onSubmit),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}
