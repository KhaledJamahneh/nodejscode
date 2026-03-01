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
import 'package:einhod_water/core/widgets/widgets.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/location_tracking_service.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../../core/utils/error_handler.dart';
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
          } else if (StorageService.isDeliveryWorker()) {
            effectiveView = 'delivery';
          } else if (profile.isOnsite) {
            effectiveView = 'onsite';
          } else if (profile.isDelivery) {
            effectiveView = 'delivery';
          } else {
            effectiveView = 'delivery';
          }
          StorageService.saveWorkerView(effectiveView);
        }

        debugPrint(
            'WorkerHome → Effective view: $effectiveView (roles: ${profile.roles}, workerType: ${profile.workerType})');

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
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator.adaptive())),
      error: (err, stack) => Scaffold(
        appBar: AppBar(
            title:
                Text(AppLocalizations.of(context)?.appTitle ?? 'Einhod Water')),
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
        _showSnackBar(ErrorHandler.getMessage(next.error), isError: true);
      } else if (next is AsyncData && previous is AsyncLoading) {
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar(l10n.updateSuccessful);
      }
    });

    ref.listen(changePasswordProvider, (previous, next) {
      if (next is AsyncError) {
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar('${l10n.failedToChangePassword}: ${ErrorHandler.getMessage(next.error)}',
            isError: true);
      } else if (next is AsyncData && previous is AsyncLoading) {
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar(l10n.passwordChangedSuccessfully);
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (isError) {
      DialogUtils.showErrorDialog(context, message);
    } else {
      DialogUtils.showMessageDialog(context, 'Success', message);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DELIVERY WORKER VIEW
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      appBar: _buildWorkerAppBar(context, _getTitle(l10n), ref),
      drawer: _WorkerDrawer(
        username: username,
        profile: profile,
        currentView: 'delivery',
        onViewSwitch: onViewSwitch,
      ),
      body: SafeArea(
          bottom: false, child: tabs[selectedIndex.clamp(0, tabs.length - 1)]),
      bottomNavigationBar: _WorkerBottomBar(
        selectedIndex: selectedIndex,
        onTap: onTabSelected,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.local_shipping_outlined),
              activeIcon: const Icon(Icons.local_shipping_rounded),
              label: l10n.deliveries),
          BottomNavigationBarItem(
              icon: const Icon(Icons.payments_outlined),
              activeIcon: const Icon(Icons.payments_rounded),
              label: l10n.expenses),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: l10n.profile),
        ],
      ),
      floatingActionButton: selectedIndex == 0 ? FloatingActionButton.extended(
        onPressed: () => _showQuickDeliveryDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Quick Delivery'),
        backgroundColor: AppTheme.primary,
      ) : null,
    );
  }

  String _getTitle(AppLocalizations l10n) {
    switch (selectedIndex) {
      case 0:
        return l10n.deliveries;
      case 1:
        return l10n.expenses;
      default:
        return l10n.profile;
    }
  }

  void _showQuickDeliveryDialog(BuildContext context, WidgetRef ref) async {
    final gallonsController = TextEditingController(text: '50');
    final emptyGallonsController = TextEditingController(text: '0');
    final notesController = TextEditingController();
    int? selectedClientId;
    final workerProfile = ref.read(workerProfileProvider).value;
    final workerId = workerProfile?.profileId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Quick Delivery'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder(
                  future: DioClient.instance.get('${ApiEndpoints.adminUsers}?role=client&limit=1000'),
                  builder: (context, AsyncSnapshot snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final allUsersData = snapshot.data.data['data'];
                    final List<dynamic> users = allUsersData is List ? allUsersData : allUsersData['users'] ?? [];
                    final clients = users.where((c) => c['profile'] != null).toList();
                    return DropdownButtonFormField<int>(
                      value: selectedClientId,
                      decoration: const InputDecoration(labelText: 'Client *'),
                      items: clients.map<DropdownMenuItem<int>>((c) => DropdownMenuItem<int>(
                        value: c['profile']['id'],
                        child: Text(c['username']),
                      )).toList(),
                      onChanged: (v) => setState(() => selectedClientId = v),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: gallonsController,
                  decoration: const InputDecoration(labelText: 'Gallons Delivered *'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emptyGallonsController,
                  decoration: const InputDecoration(labelText: 'Empty Gallons Returned'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedClientId == null) {
                  DialogUtils.showErrorDialog(context, 'Please select a client');
                  return;
                }
                try {
                  await DioClient.instance.post('workers/deliveries/quick', data: {
                    'client_id': selectedClientId,
                    'worker_id': workerId,
                    'gallons_delivered': int.parse(gallonsController.text),
                    'empty_gallons_returned': int.parse(emptyGallonsController.text),
                    'notes': notesController.text.isEmpty ? null : notesController.text,
                  });
                  ref.invalidate(workerProfileProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    DialogUtils.showMessageDialog(context, 'Success', 'Delivery created successfully');
                  }
                } catch (e) {
                  if (context.mounted) {
                    DialogUtils.showErrorDialog(context, e);
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONSITE WORKER VIEW
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      appBar: _buildWorkerAppBar(context, _getTitle(l10n), ref),
      drawer: _WorkerDrawer(
        username: username,
        profile: profile,
        currentView: 'onsite',
        onViewSwitch: onViewSwitch,
      ),
      body: SafeArea(
          bottom: false, child: tabs[selectedIndex.clamp(0, tabs.length - 1)]),
      bottomNavigationBar: _WorkerBottomBar(
        selectedIndex: selectedIndex,
        onTap: onTabSelected,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.factory_outlined),
              activeIcon: const Icon(Icons.factory_rounded),
              label: l10n.production),
          BottomNavigationBarItem(
              icon: const Icon(Icons.list_alt_rounded),
              activeIcon: const Icon(Icons.list_alt_rounded),
              label: l10n.fillLog),
          BottomNavigationBarItem(
              icon: const Icon(Icons.payments_outlined),
              activeIcon: const Icon(Icons.payments_rounded),
              label: l10n.expenses),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: l10n.profile),
        ],
      ),
    );
  }

  String _getTitle(AppLocalizations l10n) {
    switch (selectedIndex) {
      case 0:
        return l10n.production;
      case 1:
        return l10n.fillLog;
      case 2:
        return l10n.expenses;
      default:
        return l10n.profile;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED UI COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────
PreferredSizeWidget _buildWorkerAppBar(
    BuildContext context, String title, WidgetRef ref) {
  return AppBar(
    title: Text(title),
    backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
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
        icon: const Icon(Icons.refresh_rounded),
        onPressed: () => ref.invalidate(workerProfileProvider),
        tooltip: 'Refresh',
      ),
      Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push('/notifications'),
          ),
          Consumer(
            builder: (context, ref, _) {
              final unreadCountAsync = ref.watch(unreadCountPollingProvider);
              return unreadCountAsync.when(
                data: (count) => count > 0
                    ? Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.criticalRed,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
      const SizedBox(width: 8),
    ],
  );
}

class _WorkerBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;

  const _WorkerBottomBar(
      {required this.selectedIndex, required this.onTap, required this.items});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(24),
      blur: 20,
      opacity: 0.85,
      child: BottomNavigationBar(
        currentIndex: selectedIndex.clamp(0, items.length - 1),
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
    final locale = ref.watch(localeProvider);

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration:
                      BoxDecoration(color: AppTheme.primary.withOpacity(0.05)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Image.asset('assets/images/ein-logo.png',
                            height: 40, width: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(username,
                          style: Theme.of(context).textTheme.headlineMedium),
                      Text(
                        currentView == 'delivery'
                            ? l10n.deliveryWorker
                            : l10n.onsiteWorker,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                _buildDrawerItem(
                  context,
                  icon: currentView == 'delivery'
                      ? Icons.local_shipping_rounded
                      : Icons.factory_rounded,
                  title: l10n.workerView,
                  selected: true,
                  onTap: () => Navigator.pop(context),
                ),
                if (StorageService.isAdmin() ||
                    StorageService.isClient() ||
                    (currentView == 'delivery' &&
                        StorageService.hasRole('onsite_worker')) ||
                    (currentView == 'onsite' &&
                        StorageService.hasRole('delivery_worker'))) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Text(
                      l10n.switchView.toUpperCase(),
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: AppTheme.iosGray),
                    ),
                  ),
                  if (currentView == 'delivery' &&
                      StorageService.hasRole('onsite_worker'))
                    _buildDrawerItem(
                      context,
                      icon: Icons.factory_rounded,
                      title: l10n.onsiteWorker,
                      onTap: () {
                        Navigator.pop(context);
                        onViewSwitch('onsite');
                      },
                    ),
                  if (currentView == 'onsite' &&
                      StorageService.hasRole('delivery_worker'))
                    _buildDrawerItem(
                      context,
                      icon: Icons.local_shipping_rounded,
                      title: l10n.deliveryWorker,
                      onTap: () {
                        Navigator.pop(context);
                        onViewSwitch('delivery');
                      },
                    ),
                  if (StorageService.isAdmin())
                    _buildDrawerItem(
                      context,
                      icon: Icons.admin_panel_settings_rounded,
                      title: l10n.adminView,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/admin/home');
                      },
                    ),
                  if (StorageService.isClient())
                    _buildDrawerItem(
                      context,
                      icon: Icons.water_drop_rounded,
                      title: l10n.clientView,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/client/home');
                      },
                    ),
                ],
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Divider()),
                ListTile(
                  leading: const Icon(Icons.language_rounded,
                      color: AppTheme.primary),
                  title: Text(l10n.language),
                  trailing: Text(
                    locale.languageCode == 'en' ? 'English' : 'العربية',
                    style: const TextStyle(
                        color: AppTheme.iosGray, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => ref.read(localeProvider.notifier).toggleLocale(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildDrawerItem(
              context,
              icon: Icons.logout_rounded,
              title: l10n.signOut,
              isDestructive: true,
              onTap: () async {
                Navigator.pop(context);
                await ref.read(loginProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon,
          color: isDestructive
              ? AppTheme.iosRed
              : (selected ? AppTheme.primary : null)),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive
              ? AppTheme.iosRed
              : (selected ? AppTheme.primary : null),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      selected: selected,
      selectedTileColor: AppTheme.primary.withOpacity(0.08),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 12),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppTheme.iosGray,
          letterSpacing: 1.2),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DELIVERY DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────
class DeliveryDashboardTab extends ConsumerStatefulWidget {
  const DeliveryDashboardTab({super.key});

  @override
  ConsumerState<DeliveryDashboardTab> createState() =>
      _DeliveryDashboardTabState();
}

class _DeliveryDashboardTabState extends ConsumerState<DeliveryDashboardTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final profileAsync = ref.watch(workerProfileProvider);
    final l10n = AppLocalizations.of(context)!;

    return profileAsync.when(
      data: (profile) => Column(
        children: [
          Container(
            width: double.infinity,
            color: ref.watch(_locationTrackingProvider) ? AppTheme.successGreen : AppTheme.iosGray4,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  ref.watch(_locationTrackingProvider) ? Icons.my_location_rounded : Icons.location_off_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.locationSharing,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.locationSharing),
                        content: Text(l10n.locationSharingDescription),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.close),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Switch(
                  value: ref.watch(_locationTrackingProvider),
                  onChanged: (value) async {
                    if (value) {
                      final success = await LocationTrackingService.startTracking();
                      if (success) {
                        ref.read(_locationTrackingProvider.notifier).state = true;
                        await ref.read(workerOpsProvider.notifier).toggleGPS(true);
                      } else {
                        if (context.mounted) {
                          DialogUtils.showErrorDialog(context, l10n.enableGpsPermission);
                        }
                      }
                    } else {
                      LocationTrackingService.stopTracking();
                      ref.read(_locationTrackingProvider.notifier).state = false;
                      await ref.read(workerOpsProvider.notifier).toggleGPS(false);
                    }
                  },
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white24,
                ),
              ],
            ),
          ),
          _buildInventoryIndicator(context, profile.vehicleCurrentGallons),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.mainList),
              Tab(text: l10n.secondaryList),
            ],
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.iosGray,
            indicatorColor: AppTheme.primary,
          ),
          if (!profile.isOnsite) ...[
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                final stationsAsync = ref.watch(fillingStationsProvider);
                return stationsAsync.when(
                  data: (stations) {
                    if (stations.isEmpty) return const SizedBox.shrink();
                    final station = stations.first;
                    Color statusColor;
                    String statusText;

                    switch (station.currentStatus) {
                      case StationStatus.open:
                        statusColor = AppTheme.successGreen;
                        statusText = l10n.open.toUpperCase();
                        break;
                      case StationStatus.temporarilyClosed:
                        statusColor = AppTheme.midUrgentOrange;
                        statusText = l10n.tempClosed.toUpperCase();
                        break;
                      case StationStatus.closedUntilTomorrow:
                        statusColor = const Color(0xFF64748B);
                        statusText = l10n.closedUntilTomorrow.toUpperCase();
                        break;
                    }

                    return GestureDetector(
                      onTap: () => _showStationQuickInfo(context, station),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: statusColor.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.factory_rounded,
                                color: statusColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    station.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                  Text(
                                    "${l10n.stationIs} $statusText",
                                    style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: statusColor),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
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
      ),
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  void _showStationQuickInfo(BuildContext context, FillingStation station) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(24),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.iosGray4,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.stationInformation,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            ListTile(
              leading:
                  const Icon(Icons.factory_rounded, color: AppTheme.primary),
              title: Text(station.name, overflow: TextOverflow.ellipsis),
              subtitle: Text(station.address ?? l10n.noAddress, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStationStatusColor(station.currentStatus)
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.currentStatus,
                    style: TextStyle(color: AppTheme.iosGray, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStationStatusLabel(context, station.currentStatus),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _getStationStatusColor(station.currentStatus),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close.toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGPSToggleBar(BuildContext context, bool enabled) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      color: enabled ? AppTheme.successGreen : AppTheme.iosGray4,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          if (enabled)
            const _PulsingDot()
          else
            const Icon(Icons.location_off_rounded,
                color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.locationSharing,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                ),
                Text(
                  enabled
                      ? l10n.activeAdminSeeYou
                      : l10n.gpsCurrentlyDisabled,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (val) =>
                ref.read(workerOpsProvider.notifier).toggleGPS(val),
            activeColor: Colors.white,
            activeTrackColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryIndicator(BuildContext context, int remaining) {
    final l10n = AppLocalizations.of(context)!;
    Color color = AppTheme.primaryBlue;
    if (remaining <= 10)
      color = AppTheme.criticalRed;
    else if (remaining <= 20) color = AppTheme.midUrgentOrange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border:
            Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Icon(Icons.water_drop_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            '${l10n.gallonsRemaining}: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            '$remaining',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: color, fontSize: 18),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20),
            onPressed: () =>
                _showUpdateInventoryDialog(context, ref, remaining),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showUpdateInventoryDialog(BuildContext context, WidgetRef ref, int currentGallons) {
    final controller = TextEditingController(text: currentGallons.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Inventory'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Current Gallons'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = int.tryParse(controller.text) ?? currentGallons;
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

Color _getStationStatusColor(StationStatus status) {
  switch (status) {
    case StationStatus.open:
      return AppTheme.successGreen;
    case StationStatus.temporarilyClosed:
      return AppTheme.midUrgentOrange;
    case StationStatus.closedUntilTomorrow:
      return const Color(0xFF64748B);
  }
}

String _getStationStatusLabel(BuildContext context, StationStatus status) {
  final l10n = AppLocalizations.of(context)!;
  switch (status) {
    case StationStatus.open:
      return l10n.open.toUpperCase();
    case StationStatus.temporarilyClosed:
      return l10n.tempClosed.toUpperCase();
    case StationStatus.closedUntilTomorrow:
      return l10n.closedUntilTomorrow.toUpperCase();
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(1 - _controller.value),
              blurRadius: 8 * _controller.value,
              spreadRadius: 4 * _controller.value,
            )
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONSITE DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────
class OnsiteDashboardTab extends ConsumerWidget {
  const OnsiteDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentStatusEnum = ref.watch(stationStatusProvider);
    final currentStatus = currentStatusEnum == StationStatus.open
        ? 'open'
        : currentStatusEnum == StationStatus.temporarilyClosed
            ? 'temporarilyClosed'
            : 'closedUntilTomorrow';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModernCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.factory_rounded,
                        size: 28, color: AppTheme.primary),
                    SizedBox(width: 12),
                    Text(l10n.stationStatus,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _statusButton(context, ref, 'open', currentStatus),
                    const SizedBox(width: 12),
                    _statusButton(
                        context, ref, 'temporarilyClosed', currentStatus),
                    const SizedBox(width: 12),
                    _statusButton(
                        context, ref, 'closedUntilTomorrow', currentStatus),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionHeader(l10n.productionOverview),
          _buildProductionStats(context, ref),
          const SizedBox(height: 12),
          ModernCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(l10n.quickActions,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: l10n.newFillingSession,
                  icon: Icons.add_circle_outline,
                  onTap: () => _showNewFillingSessionDialog(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusButton(
      BuildContext context, WidgetRef ref, String status, String current) {
    final isActive = status == current;
    final l10n = AppLocalizations.of(context)!;
    final display = status == 'open'
        ? l10n.open
        : status == 'temporarilyClosed'
            ? l10n.tempClosed
            : l10n.closedUntilTomorrow;
    final Color color;
    final IconData icon;
    if (status == 'open') {
      color = AppTheme.successGreen;
      icon = Icons.check_circle_outline_rounded;
    } else if (status == 'temporarilyClosed') {
      color = AppTheme.midUrgentOrange;
      icon = Icons.pause_circle_outline_rounded;
    } else {
      color = const Color(0xFF64748B);
      icon = Icons.lock_outline_rounded;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          try {
            await ref
                .read(workerOpsProvider.notifier)
                .updateStationStatus(1, status);
          } catch (e) {
            if (context.mounted) {
              DialogUtils.showErrorDialog(context, AppLocalizations.of(context)!.backendNotImplemented);
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.12) : Colors.transparent,
            border: Border.all(color: color, width: isActive ? 2 : 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(display,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: color, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductionStats(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sessionsAsync = ref.watch(recentFillingSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        // FIX #6: safe DateTime parsing
        final today = sessions
            .where((s) {
              final dt = DateTime.tryParse(s.completionTime ?? '');
              return dt != null && dt.day == DateTime.now().day;
            })
            .fold(0, (sum, s) => sum + s.gallonsFilled);
        final month = sessions.fold(0, (sum, s) => sum + s.gallonsFilled);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.37,
          children: [
            _buildStatCard(l10n.today, '${l10n.gallonsUnit(today)}', Icons.today_rounded,
                AppTheme.successGreen),
            _buildStatCard(l10n.thisMonth, '${l10n.gallonsUnit(month)}',
                Icons.calendar_month_rounded, AppTheme.primary),
            _buildStatCard(l10n.sessions, '${sessions.length}',
                Icons.list_alt_rounded, AppTheme.iosBlue),
            _buildStatCard(
                l10n.avgPerSession,
                sessions.isEmpty
                    ? '0'
                    : (month / sessions.length).toStringAsFixed(0),
                Icons.trending_up_rounded,
                AppTheme.midUrgentOrange),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, stack) => Center(child: Text(l10n.noData)),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return ModernCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppTheme.iosGray),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  void _showNewFillingSessionDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final stations = ref.read(fillingStationsProvider);
    int? selectedStationId = stations.value?.isNotEmpty == true ? stations.value!.first.id : null;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.newFillingSession),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (stations.value?.isNotEmpty == true)
                DropdownButtonFormField<int>(
                  value: selectedStationId,
                  decoration: InputDecoration(labelText: l10n.stationName),
                  items: stations.value!.map((station) {
                    return DropdownMenuItem(
                      value: station.id,
                      child: Text(station.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => selectedStationId = val);
                  },
                ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.gallonsFilled),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () async {
                final gallons = int.tryParse(controller.text) ?? 0;
                if (gallons > 0 && selectedStationId != null) {
                  // Start session first
                  await ref.read(workerOpsProvider.notifier).startFillingSession(selectedStationId!);
                  // Get the session ID
                  final sessionId = ref.read(activeFillingSessionProvider);
                  if (sessionId != null) {
                    // Complete it immediately
                    await ref.read(workerOpsProvider.notifier).completeFillingSession(sessionId, gallons);
                  }
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONSITE FILL LOG
// ─────────────────────────────────────────────────────────────────────────────
class OnsiteFillLogTab extends ConsumerWidget {
  const OnsiteFillLogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(recentFillingSessionsProvider);

    return historyAsync.when(
      data: (sessions) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return ModernCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            onTap: () => _showEditSessionDialog(context, ref, session),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.sessionNumber(session.id),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.iosGray,
                            fontWeight: FontWeight.bold)),
                    Text(l10n.gallonsUnit(session.gallonsFilled),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('h:mm a')
                          .format(DateTime.parse(session.completionTime)),
                      style: const TextStyle(
                          color: AppTheme.iosGray, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.edit_rounded, size: 16, color: AppTheme.iosGray),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => Center(child: Text(l10n.noSessionsYet)),
    );
  }

  void _showEditSessionDialog(BuildContext context, WidgetRef ref, FillingSession session) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: session.gallonsFilled.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.edit),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.gallonsFilled),
        ),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.delete),
                  content: Text('${l10n.deleteConfirmation} ${l10n.session.toLowerCase()}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(workerOpsProvider.notifier).deleteFillingSession(session.id);
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.criticalRed,
                      ),
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );
            },
            child: Text(l10n.delete, style: const TextStyle(color: AppTheme.criticalRed)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final gallons = int.tryParse(controller.text) ?? 0;
              if (gallons > 0) {
                ref.read(workerOpsProvider.notifier).updateFillingSession(session.id, gallons);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DELIVERY LISTS
// ─────────────────────────────────────────────────────────────────────────────
class WorkerMainList extends ConsumerWidget {
  const WorkerMainList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(workerScheduleProvider);
    final l10n = AppLocalizations.of(context)!;

    return scheduleAsync.when(
      data: (deliveries) {
        if (deliveries.isEmpty) {
          return Center(child: Text(l10n.noActivity));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: deliveries.length,
          itemBuilder: (context, index) =>
              _buildDeliveryCard(context, ref, deliveries[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildDeliveryCard(
      BuildContext context, WidgetRef ref, WorkerDelivery delivery) {
    final l10n = AppLocalizations.of(context)!;

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      onTap: delivery.isCompleted
          ? null
          : () => _showRecordDeliverySheet(context, ref, delivery),
      child: Opacity(
        opacity: delivery.isCompleted ? 0.6 : 1.0,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(delivery.clientName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(delivery.clientAddress,
                      style: const TextStyle(
                          color: AppTheme.iosGray, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text('${delivery.scheduledGallons} ${l10n.gallons}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            if (delivery.isCompleted)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.successGreen)
            else
              ElevatedButton(
                onPressed: () =>
                    _showRecordDeliverySheet(context, ref, delivery),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 0),
                  backgroundColor: AppTheme.primary,
                ),
                child: Text(l10n.recordDelivery),
              ),
          ],
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
    final l10n = AppLocalizations.of(context)!;

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(child: Text(l10n.noActivity));
        }
        final sorted = List<WorkerRequest>.from(requests);
        // FIX #5: stable, transitive priority sort
        int priorityOrder(String p) =>
            p == 'urgent' ? 0 : p == 'mid_urgent' ? 1 : 2;
        sorted.sort((a, b) =>
            priorityOrder(a.priority).compareTo(priorityOrder(b.priority)));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: sorted.length,
          itemBuilder: (context, index) =>
              _buildRequestCard(context, ref, sorted[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildRequestCard(
      BuildContext context, WidgetRef ref, WorkerRequest request) {
    final l10n = AppLocalizations.of(context)!;
    final priorityColor = _getPriorityColor(request.priority);

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(20)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            request.priority.toUpperCase(),
                            style: TextStyle(
                                color: priorityColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(request.requestDate,
                            style: const TextStyle(
                                color: AppTheme.iosGray, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(request.clientName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(request.clientAddress,
                        style: const TextStyle(
                            color: AppTheme.iosGray, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${request.requestedGallons} ${l10n.gallons}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        if (request.assignedToMe)
                          ElevatedButton(
                            onPressed: () => _showRecordDeliverySheet(
                                context, ref, request.toDelivery()),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              minimumSize: const Size(0, 0),
                              backgroundColor: AppTheme.primary,
                            ),
                            child: Text(l10n.recordDelivery),
                          )
                        else
                          ElevatedButton(
                            onPressed: () => ref
                                .read(workerOpsProvider.notifier)
                                .acceptRequest(request.id),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              minimumSize: const Size(0, 0),
                              backgroundColor: AppTheme.successGreen,
                            ),
                            child: const Text('ACCEPT REQUEST'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return AppTheme.criticalRed;
      case 'mid_urgent':
        return AppTheme.midUrgentOrange;
      default:
        return AppTheme.successGreen;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECORD DELIVERY SHEET (UPDATED)
// ─────────────────────────────────────────────────────────────────────────────
void _showRecordDeliverySheet(
    BuildContext context, WidgetRef ref, WorkerDelivery delivery) {
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
  late int paidCoupons;
  late double paidAmount;
  late final TextEditingController priceController;
  final notesController = TextEditingController();
  
  double? capturedLat;
  double? capturedLng;
  bool isCapturingLocation = true;

  @override
  void initState() {
    super.initState();
    gallons = widget.delivery.scheduledGallons;
    emptyGallons = 0;
    paidCoupons = widget.delivery.scheduledGallons;
    paidAmount = (gallons * widget.delivery.pricePerGallon);
    priceController = TextEditingController(text: paidAmount.toStringAsFixed(2));
    
    _captureLocation();
  }

  Future<void> _captureLocation() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          capturedLat = pos.latitude;
          capturedLng = pos.longitude;
          isCapturingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCapturingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return GlassCard(
      color: Theme.of(context).scaffoldBackgroundColor,
      opacity: 0.98,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      margin: EdgeInsets.zero,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
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
                    color: AppTheme.iosGray4,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.delivery.clientName,
              style: Theme.of(context).textTheme.headlineMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.delivery.clientAddress,
              style: const TextStyle(color: AppTheme.iosGray, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),

            // ── Gallons Delivered ─────────────────────────────────────────
            Text(l10n.gallons,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepButton(
                    Icons.remove,
                    () => setState(() {
                          if (gallons > 0) {
                            gallons--;
                            if (!widget.delivery.isCouponBook) {
                              paidAmount = (gallons * widget.delivery.pricePerGallon);
                              priceController.text = paidAmount.toStringAsFixed(2);
                            }
                          }
                        })),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text('$gallons',
                      style: const TextStyle(
                          fontSize: 48, fontWeight: FontWeight.w800)),
                ),
                _buildStepButton(
                    Icons.add, () => setState(() {
                      gallons++;
                      if (!widget.delivery.isCouponBook) {
                        paidAmount = (gallons * widget.delivery.pricePerGallon);
                        priceController.text = paidAmount.toStringAsFixed(2);
                      }
                    })),
              ],
            ),
            const SizedBox(height: 24),

            // ── Empty Gallons Returned ────────────────────────────────────
            Text(l10n.emptyGallons,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepButton(
                    Icons.remove,
                    () => setState(() {
                          if (emptyGallons > 0) emptyGallons--;
                        })),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text('$emptyGallons',
                      style: const TextStyle(
                          fontSize: 48, fontWeight: FontWeight.w800)),
                ),
                _buildStepButton(
                    Icons.add, () => setState(() => emptyGallons++)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Paid Coupons (coupon_book clients only) ───────────────────
            if (widget.delivery.isCouponBook) ...[
              Row(
                children: [
                  const Text(
                    'Paid Coupons (قسائم مدفوعة)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.delivery.remainingCoupons} remaining',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepButton(
                      Icons.remove,
                      () => setState(() {
                            if (paidCoupons > 0) paidCoupons--;
                          })),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text('$paidCoupons',
                        style: const TextStyle(
                            fontSize: 48, fontWeight: FontWeight.w800)),
                  ),
                  _buildStepButton(
                      Icons.add,
                      () => setState(() {
                            if (paidCoupons < widget.delivery.remainingCoupons)
                              paidCoupons++;
                          })),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'After this delivery: ${(widget.delivery.remainingCoupons - paidCoupons).clamp(0, 999)} coupons left',
                  style: TextStyle(
                    fontSize: 13,
                    color: (widget.delivery.remainingCoupons - paidCoupons) < 5
                        ? AppTheme.criticalRed
                        : AppTheme.iosGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              // ── Cash Details (price & paid) ──────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Price (السعر الإجمالي)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            prefixText: '₪ ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Amount Paid (المبلغ المدفوع)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        TextField(
                          onChanged: (v) => paidAmount = double.tryParse(v) ?? 0,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: paidAmount.toStringAsFixed(2),
                            prefixText: '₪ ',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            Row(
              children: [
                Icon(
                  capturedLat != null ? Icons.location_on_rounded : Icons.location_searching_rounded,
                  color: capturedLat != null ? AppTheme.successGreen : AppTheme.iosGray, 
                  size: 20
                ),
                const SizedBox(width: 8),
                Text(
                  capturedLat != null ? l10n.locationCaptured : (isCapturingLocation ? 'Capturing location...' : 'Location not captured'),
                  style: TextStyle(
                    color: capturedLat != null ? AppTheme.successGreen : AppTheme.iosGray,
                    fontWeight: FontWeight.bold
                  )
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(labelText: l10n.notes),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final totalPriceValue = double.tryParse(priceController.text) ?? (gallons * widget.delivery.pricePerGallon);

                if (widget.delivery.isRequest) {
                  widget.ref.read(workerOpsProvider.notifier).completeRequest({
                    'request_id': widget.delivery.id,
                    'gallons_delivered': gallons,
                    'empty_gallons_returned': emptyGallons,
                    'latitude': capturedLat,
                    'longitude': capturedLng,
                    'notes': notesController.text,
                    if (widget.delivery.isCouponBook)
                      'paid_coupons_count': paidCoupons,
                    if (!widget.delivery.isCouponBook) ...{
                      'paid_amount': paidAmount,
                      'total_price': totalPriceValue,
                    },
                  });
                } else {
                  widget.ref.read(workerOpsProvider.notifier).completeDelivery({
                    'delivery_id': widget.delivery.id,
                    'gallons_delivered': gallons,
                    'empty_gallons_returned': emptyGallons,
                    'latitude': capturedLat,
                    'longitude': capturedLng,
                    'notes': notesController.text,
                    if (widget.delivery.isCouponBook)
                      'paid_coupons_count': paidCoupons,
                    if (!widget.delivery.isCouponBook) ...{
                      'paid_amount': paidAmount,
                      'total_price': totalPriceValue,
                    },
                  });
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52)),
              child: Text(l10n.confirmDelivery.toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildStepButton(IconData icon, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: AppTheme.primary),
    ),
  );
}
