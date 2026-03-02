// lib/features/worker/presentation/screens/worker_home_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/config/api_config.dart';
import 'worker_expenses_tab.dart';
import 'worker_profile_tab.dart';
import '../../../../widgets/shared_widgets.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/location_tracking_service.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/worker_provider.dart';
import '../../data/models/worker_models.dart';

final _locationTrackingProvider = StateProvider<bool>((ref) => false);

class WorkerHomeScreen extends ConsumerStatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  ConsumerState<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends ConsumerState<WorkerHomeScreen> {
  int _selectedIndex = 0;
  String? _viewOverride;

  @override
  void initState() {
    super.initState();
    _viewOverride = StorageService.getWorkerView();
  }

  @override
  Widget build(BuildContext context) {
    final username = StorageService.getUsername() ?? 'Worker';
    final profileAsync = ref.watch(workerProfileProvider);

    _setupListeners();

    return profileAsync.when(
      data: (profile) {
        String effectiveView = _viewOverride ?? '';

        if (effectiveView.isEmpty) {
          if (StorageService.isOnsiteWorker()) {
            effectiveView = 'onsite';
          } else {
            effectiveView = 'delivery';
          }
          StorageService.saveWorkerView(effectiveView);
        }

        if (effectiveView == 'delivery') {
          return _DeliveryWorkerHome(
            profile: profile,
            username: username,
            selectedIndex: _selectedIndex,
            onTabSelected: (i) => setState(() => _selectedIndex = i),
            onViewSwitch: _switchView,
            ref: ref,
          );
        } else {
          return _OnsiteWorkerHome(
            profile: profile,
            username: username,
            selectedIndex: _selectedIndex,
            onTabSelected: (i) => setState(() => _selectedIndex = i),
            onViewSwitch: _switchView,
            ref: ref,
          );
        }
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator.adaptive())),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)?.appTitle ?? 'Einhod Water')),
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _switchView(String view) async {
    await StorageService.saveWorkerView(view);
    setState(() {
      _viewOverride = view;
      _selectedIndex = 0;
    });
  }

  void _setupListeners() {
    ref.listen(workerOpsProvider, (previous, next) {
      if (next is AsyncError) {
        _showSnackBar('Operation failed: ${next.error}', isError: true);
      } else if (next is AsyncData && previous is AsyncLoading) {
        _showSnackBar('Update successful');
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (isError) {
      DialogUtils.showErrorDialog(context, message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppTheme.successGreen)
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DELIVERY WORKER HOME
// ─────────────────────────────────────────────────────────────────────────────
class _DeliveryWorkerHome extends StatelessWidget {
  final WorkerProfile profile;
  final String username;
  final int selectedIndex;
  final Function(int) onTabSelected;
  final Future<void> Function(String) onViewSwitch;
  final WidgetRef ref;

  const _DeliveryWorkerHome({
    required this.profile,
    required this.username,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onViewSwitch,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> tabs = [
      const DeliveryDashboardTab(),
      WorkerExpensesTab(),
      WorkerProfileTab(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: _buildWorkerAppBar(context, _getTitle(l10n), ref),
      drawer: _WorkerDrawer(
        username: username,
        profile: profile,
        currentView: 'delivery',
        onViewSwitch: onViewSwitch,
      ),
      body: tabs[selectedIndex.clamp(0, tabs.length - 1)],
      bottomNavigationBar: _WorkerBottomBar(
        selectedIndex: selectedIndex,
        onTap: onTabSelected,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.local_shipping_outlined), activeIcon: const Icon(Icons.local_shipping_rounded), label: l10n.deliveries),
          BottomNavigationBarItem(icon: const Icon(Icons.payments_outlined), activeIcon: const Icon(Icons.payments_rounded), label: l10n.expenses),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline_rounded), activeIcon: const Icon(Icons.person_rounded), label: l10n.profile),
        ],
      ),
      floatingActionButton: selectedIndex == 0 ? FloatingActionButton.extended(
        onPressed: () => _showQuickDeliveryDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Quick Delivery'),
        backgroundColor: AppTheme.primaryBlue,
      ) : null,
    );
  }

  String _getTitle(AppLocalizations l10n) {
    switch (selectedIndex) {
      case 0: return l10n.deliveries;
      case 1: return l10n.expenses;
      default: return l10n.profile;
    }
  }

  void _showQuickDeliveryDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => _QuickDeliveryDialog(ref: ref));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONSITE WORKER HOME
// ─────────────────────────────────────────────────────────────────────────────
class _OnsiteWorkerHome extends StatelessWidget {
  final WorkerProfile profile;
  final String username;
  final int selectedIndex;
  final Function(int) onTabSelected;
  final Future<void> Function(String) onViewSwitch;
  final WidgetRef ref;

  const _OnsiteWorkerHome({
    required this.profile,
    required this.username,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onViewSwitch,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> tabs = [
      const OnsiteDashboardTab(),
      const OnsiteFillLogTab(),
      WorkerExpensesTab(),
      WorkerProfileTab(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: _buildWorkerAppBar(context, _getTitle(l10n), ref),
      drawer: _WorkerDrawer(
        username: username,
        profile: profile,
        currentView: 'onsite',
        onViewSwitch: onViewSwitch,
      ),
      body: tabs[selectedIndex.clamp(0, tabs.length - 1)],
      bottomNavigationBar: _WorkerBottomBar(
        selectedIndex: selectedIndex,
        onTap: onTabSelected,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.factory_outlined), activeIcon: const Icon(Icons.factory_rounded), label: l10n.production),
          BottomNavigationBarItem(icon: const Icon(Icons.list_alt_rounded), activeIcon: const Icon(Icons.list_alt_rounded), label: l10n.fillLog),
          BottomNavigationBarItem(icon: const Icon(Icons.payments_outlined), activeIcon: const Icon(Icons.payments_rounded), label: l10n.expenses),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline_rounded), activeIcon: const Icon(Icons.person_rounded), label: l10n.profile),
        ],
      ),
    );
  }

  String _getTitle(AppLocalizations l10n) {
    switch (selectedIndex) {
      case 0: return l10n.production;
      case 1: return l10n.fillLog;
      case 2: return l10n.expenses;
      default: return l10n.profile;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED UI COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────
PreferredSizeWidget _buildWorkerAppBar(BuildContext context, String title, WidgetRef ref) {
  return AppBar(
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    backgroundColor: AppTheme.glassBg.withOpacity(0.8),
    elevation: 0,
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(color: Colors.transparent),
      ),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh_rounded),
        onPressed: () {
          ref.invalidate(workerProfileProvider);
          ref.invalidate(workerScheduleProvider);
          ref.invalidate(workerRequestsProvider);
        },
      ),
      Consumer(
        builder: (context, ref, _) {
          final unreadCount = ref.watch(unreadCountPollingProvider).asData?.value ?? 0;
          return IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          );
        },
      ),
      const SizedBox(width: 8),
    ],
  );
}

class _WorkerBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;

  const _WorkerBottomBar({required this.selectedIndex, required this.onTap, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.glassBg.withOpacity(0.95),
        border: Border(top: BorderSide(color: AppTheme.glassBorder)),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex.clamp(0, items.length - 1),
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.textSecondary,
        items: items,
      ),
    );
  }
}

class _WorkerDrawer extends ConsumerWidget {
  final String username;
  final WorkerProfile profile;
  final String currentView;
  final Future<void> Function(String) onViewSwitch;

  const _WorkerDrawer({
    required this.username,
    required this.profile,
    required this.currentView,
    required this.onViewSwitch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      backgroundColor: AppTheme.surfaceColor,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(currentView == 'delivery' ? l10n.deliveryWorker : l10n.onsiteWorker),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, color: AppTheme.primaryBlue, size: 40),
            ),
            decoration: const BoxDecoration(color: AppTheme.primaryBlue),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: Text(l10n.dashboard),
            onTap: () => Navigator.pop(context),
          ),
          if (StorageService.isAdmin())
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded, color: Colors.orange),
              title: Text(l10n.adminView),
              onTap: () => context.push('/admin/home'),
            ),
          if (StorageService.isClient())
            ListTile(
              leading: const Icon(Icons.water_drop_rounded, color: AppTheme.primaryBlue),
              title: Text(l10n.clientView),
              onTap: () => context.push('/client/home'),
            ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.criticalRed),
            title: Text(l10n.signOut, style: const TextStyle(color: AppTheme.criticalRed)),
            onTap: () async {
              await ref.read(loginProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DELIVERY DASHBOARD TAB
// ─────────────────────────────────────────────────────────────────────────────
class DeliveryDashboardTab extends ConsumerStatefulWidget {
  const DeliveryDashboardTab({super.key});
  @override
  ConsumerState<DeliveryDashboardTab> createState() => _DeliveryDashboardTabState();
}

class _DeliveryDashboardTabState extends ConsumerState<DeliveryDashboardTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(workerProfileProvider).asData?.value;

    return Column(
      children: [
        _buildGpsStatusCard(context),
        if (profile != null) _buildInventoryCard(context, profile.vehicleCurrentGallons),
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryBlue,
          tabs: [
            Tab(text: l10n.mainList),
            Tab(text: l10n.secondaryList),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const WorkerMainList(),
              const WorkerSecondaryList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGpsStatusCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTracking = ref.watch(_locationTrackingProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTracking ? AppTheme.successGreen.withOpacity(0.1) : AppTheme.iosGray.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isTracking ? AppTheme.successGreen.withOpacity(0.3) : AppTheme.iosGray.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isTracking ? AppTheme.successGreen : AppTheme.iosGray,
              shape: BoxShape.circle,
            ),
            child: Icon(isTracking ? Icons.my_location_rounded : Icons.location_off_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.locationSharing, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(isTracking ? l10n.activeAdminSeeYou : l10n.gpsCurrentlyDisabled, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: isTracking,
            activeColor: AppTheme.successGreen,
            onChanged: (val) async {
              if (val) {
                final success = await LocationTrackingService.startTracking();
                if (success) {
                  ref.read(_locationTrackingProvider.notifier).state = true;
                  await ref.read(workerOpsProvider.notifier).toggleGPS(true);
                } else {
                  if (context.mounted) DialogUtils.showErrorDialog(context, l10n.enableGpsPermission);
                }
              } else {
                LocationTrackingService.stopTracking();
                ref.read(_locationTrackingProvider.notifier).state = false;
                await ref.read(workerOpsProvider.notifier).toggleGPS(false);
              }
            },
          )
        ],
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, int remaining) {
    final l10n = AppLocalizations.of(context)!;
    Color color = AppTheme.primaryBlue;
    if (remaining <= 10) color = AppTheme.criticalRed;
    else if (remaining <= 20) color = AppTheme.midUrgentOrange;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.water_drop_rounded, color: color, size: 24),
          const SizedBox(width: 12),
          Text(l10n.gallonsRemaining, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('$remaining', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryBlue),
            onPressed: () => _showUpdateInventoryDialog(context, ref, remaining),
          )
        ],
      ),
    );
  }

  void _showUpdateInventoryDialog(BuildContext context, WidgetRef ref, int current) {
    final controller = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Inventory'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current Gallons')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newValue = int.tryParse(controller.text) ?? current;
              await ref.read(workerServiceProvider).updateInventory(newValue);
              ref.invalidate(workerProfileProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class WorkerMainList extends ConsumerWidget {
  const WorkerMainList({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(workerScheduleProvider);
    return scheduleAsync.when(
      data: (deliveries) => deliveries.isEmpty 
        ? const Center(child: Text('No deliveries scheduled for today'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deliveries.length,
            itemBuilder: (context, index) => _DeliveryCard(delivery: deliveries[index]),
          ),
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

class _DeliveryCard extends ConsumerWidget {
  final WorkerDelivery delivery;
  const _DeliveryCard({required this.delivery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.glassBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(delivery.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(delivery.clientAddress, style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(delivery.isCouponRequest ? Icons.confirmation_number_rounded : Icons.water_drop_rounded, size: 16, color: AppTheme.primaryBlue),
                const SizedBox(width: 4),
                Text(delivery.isCouponRequest ? l10n.coupon : '${delivery.scheduledGallons} ${l10n.gallons}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            )
          ],
        ),
        trailing: delivery.isCompleted 
          ? const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 32)
          : ElevatedButton(
              onPressed: () => _showRecordDeliverySheet(context, ref, delivery),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(l10n.recordDelivery),
            ),
      ),
    );
  }
}

class WorkerSecondaryList extends ConsumerWidget {
  const WorkerSecondaryList({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(workerRequestsProvider);
    return requestsAsync.when(
      data: (requests) => requests.isEmpty
        ? const Center(child: Text('No pending requests available'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) => _RequestCard(request: requests[index]),
          ),
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final WorkerRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final color = request.priority == 'urgent' ? AppTheme.criticalRed : (request.priority == 'mid_urgent' ? AppTheme.midUrgentOrange : AppTheme.successGreen);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.glassBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                Text(request.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(request.priority.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            subtitle: Text(request.clientAddress),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Text('${request.requestedGallons} Gallons', style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (request.assignedToMe)
                  ElevatedButton(
                    onPressed: () => _showRecordDeliverySheet(context, ref, request.toDelivery()),
                    child: Text(l10n.recordDelivery),
                  )
                else
                  ElevatedButton(
                    onPressed: () => ref.read(workerOpsProvider.notifier).acceptRequest(request.id),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white),
                    child: const Text('ACCEPT'),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONSITE DASHBOARD TAB
// ─────────────────────────────────────────────────────────────────────────────
class OnsiteDashboardTab extends ConsumerWidget {
  const OnsiteDashboardTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final status = ref.watch(stationStatusProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.glassBg, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppTheme.glassBorder)),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.factory_rounded, color: AppTheme.primaryBlue, size: 28),
                    const SizedBox(width: 12),
                    Text(l10n.stationStatus, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildStatusBtn(context, ref, StationStatus.open, status),
                    const SizedBox(width: 12),
                    _buildStatusBtn(context, ref, StationStatus.temporarilyClosed, status),
                    const SizedBox(width: 12),
                    _buildStatusBtn(context, ref, StationStatus.closedUntilTomorrow, status),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.productionOverview, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildProductionGrid(context, ref),
          const SizedBox(height: 32),
          PrimaryButton(
            label: l10n.newFillingSession,
            icon: Icons.add_circle_outline,
            onTap: () => _showNewFillingSessionDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBtn(BuildContext context, WidgetRef ref, StationStatus target, StationStatus current) {
    final active = target == current;
    final l10n = AppLocalizations.of(context)!;
    final color = target == StationStatus.open ? AppTheme.successGreen : (target == StationStatus.temporarilyClosed ? AppTheme.midUrgentOrange : AppTheme.iosGray);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(workerOpsProvider.notifier).updateStationStatus(1, target.name),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.1) : Colors.transparent,
            border: Border.all(color: color, width: active ? 2 : 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(target == StationStatus.open ? Icons.check_circle : (target == StationStatus.temporarilyClosed ? Icons.pause_circle : Icons.lock), color: color),
              const SizedBox(height: 8),
              Text(target.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductionGrid(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(recentFillingSessionsProvider);
    return sessionsAsync.when(
      data: (sessions) {
        final total = sessions.fold(0, (sum, s) => sum + s.gallonsFilled);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _StatCard(label: 'Total Gallons', value: '$total', icon: Icons.water_drop, color: AppTheme.primaryBlue),
            _StatCard(label: 'Sessions', value: '${sessions.length}', icon: Icons.history, color: Colors.purple),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (_, __) => const Text('Error loading stats'),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.glassBg, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.glassBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECORD DELIVERY SHEET
// ─────────────────────────────────────────────────────────────────────────────
void _showRecordDeliverySheet(BuildContext context, WidgetRef ref, WorkerDelivery delivery) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RecordDeliverySheetContent(delivery: delivery, ref: ref),
  );
}

class _RecordDeliverySheetContent extends StatefulWidget {
  final WorkerDelivery delivery;
  final WidgetRef ref;
  const _RecordDeliverySheetContent({required this.delivery, required this.ref});
  @override
  State<_RecordDeliverySheetContent> createState() => _RecordDeliverySheetContentState();
}

class _RecordDeliverySheetContentState extends State<_RecordDeliverySheetContent> {
  late int gallons;
  late int emptyGallons;
  final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    gallons = widget.delivery.scheduledGallons;
    emptyGallons = 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
      decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.iosGray4, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text(widget.delivery.clientName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(widget.delivery.clientAddress, style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          _buildCounter(l10n.gallons, gallons, (v) => setState(() => gallons = v)),
          const SizedBox(height: 24),
          _buildCounter(l10n.emptyGallons, emptyGallons, (v) => setState(() => emptyGallons = v)),
          const SizedBox(height: 32),
          PrimaryButton(
            label: l10n.complete.toUpperCase(),
            onTap: () async {
              if (widget.delivery.isCouponRequest) {
                await widget.ref.read(workerOpsProvider.notifier).completeCouponRequest({
                  'request_id': widget.delivery.id,
                  'notes': notesController.text,
                });
              } else if (widget.delivery.isRequest) {
                await widget.ref.read(workerOpsProvider.notifier).completeRequest({
                  'request_id': widget.delivery.id,
                  'gallons_delivered': gallons,
                  'empty_gallons_returned': emptyGallons,
                  'notes': notesController.text,
                });
              } else {
                await widget.ref.read(workerOpsProvider.notifier).completeDelivery({
                  'delivery_id': widget.delivery.id,
                  'gallons_delivered': gallons,
                  'empty_gallons_returned': emptyGallons,
                  'notes': notesController.text,
                });
              }
              if (mounted) Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  Widget _buildCounter(String label, int value, Function(int) onChange) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline, size: 32), onPressed: () => value > 0 ? onChange(value - 1) : null),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Text('$value', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
            IconButton(icon: const Icon(Icons.add_circle_outline, size: 32), onPressed: () => onChange(value + 1)),
          ],
        )
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOGS & UTILS
// ─────────────────────────────────────────────────────────────────────────────
void _showNewFillingSessionDialog(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New Filling Session'),
      content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gallons Filled')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final g = int.tryParse(controller.text) ?? 0;
            if (g > 0) {
              await ref.read(workerOpsProvider.notifier).startFillingSession(1);
              final sid = ref.read(activeFillingSessionProvider);
              if (sid != null) await ref.read(workerOpsProvider.notifier).completeFillingSession(sid, g);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Submit'),
        )
      ],
    ),
  );
}

class _QuickDeliveryDialog extends StatelessWidget {
  final WidgetRef ref;
  const _QuickDeliveryDialog({required this.ref});
  @override
  Widget build(BuildContext context) {
    return const AlertDialog(title: Text('Quick Delivery'), content: Text('Quick delivery form placeholder'));
  }
}

class OnsiteFillLogTab extends ConsumerWidget {
  const OnsiteFillLogTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(recentFillingSessionsProvider);
    return history.when(
      data: (sessions) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        itemBuilder: (context, index) => Card(child: ListTile(title: Text('${sessions[index].gallonsFilled} Gallons'), subtitle: Text(sessions[index].completionTime))),
      ),
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (_, __) => const Center(child: Text('Error loading log')),
    );
  }
}
