// lib/features/admin/presentation/screens/admin_home_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../worker/presentation/providers/worker_provider.dart';
import '../../../worker/data/models/worker_models.dart';
import '../providers/admin_provider.dart';
import '../providers/requests_provider.dart';
import '../providers/deliveries_provider.dart';
import '../providers/users_provider.dart';
import '../providers/analytics_provider.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/admin_service.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  bool _isScheduleExpanded = false;
  bool _notificationsSeen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh dashboard whenever this screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(dashboardProvider);
        // Reset notification seen state when dashboard refreshes
        setState(() => _notificationsSeen = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final username = StorageService.getUsername() ?? 'Admin';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showPageInfo(context, l10n.dashboard, l10n.dashboardDesc),
          child: Text(l10n.dashboard),
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
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(dashboardProvider),
            tooltip: l10n.refresh,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {
                  setState(() => _notificationsSeen = true);
                  context.push('/notifications');
                },
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
      ),
      drawer: _buildDrawer(context, ref, username),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: dashboardAsync.when(
          data: (dashboard) => _buildDashboard(context, dashboard, ref),
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 64, color: AppTheme.iosRed),
                const SizedBox(height: 24),
                Text(l10n.connectionIssue,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(l10n.unableToLoadDashboard,
                    style: TextStyle(color: AppTheme.iosGray)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => ref.invalidate(dashboardProvider),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 50)),
                  child: Text(l10n.retry.toUpperCase()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref, String username) {
    final roles = StorageService.getRoles();
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
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                  ),
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
                        child: Image.asset(
                          'assets/images/ein-logo.png',
                          height: 40,
                          width: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        username,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        roles.map((r) => _getRoleName(context, r)).join(', '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  title: l10n.dashboard,
                  selected: true,
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.assignment_rounded,
                  title: l10n.requests,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/requests');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.local_shipping_rounded,
                  title: l10n.deliveries,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/deliveries');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people_rounded,
                  title: l10n.users,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/users');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.account_balance_wallet_rounded,
                  title: l10n.expenses,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/expenses');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.style_rounded,
                  title: l10n.couponSettings,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/coupon-settings');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics_rounded,
                  title: l10n.analytics,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/analytics');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.attach_money_rounded,
                  title: l10n.revenues,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/revenues');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.schedule_rounded),
                  title: Text(l10n.schedules, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: AnimatedRotation(
                    turns: _isScheduleExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  onTap: () => setState(() => _isScheduleExpanded = !_isScheduleExpanded),
                ),
                if (_isScheduleExpanded) ...[
                  ListTile(
                    leading: const SizedBox(width: 24),
                    title: Row(
                      children: [
                        Icon(Icons.event_repeat, size: 20, color: Colors.grey[700]),
                        const SizedBox(width: 12),
                        Text(l10n.scheduledDeliveries, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                      ],
                    ),
                    contentPadding: const EdgeInsets.only(left: 48, right: 24),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/schedules');
                    },
                  ),
                  ListTile(
                    leading: const SizedBox(width: 24),
                    title: Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 20, color: Colors.grey[700]),
                        const SizedBox(width: 12),
                        Text(l10n.workShifts, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                      ],
                    ),
                    contentPadding: const EdgeInsets.only(left: 48, right: 24),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/schedules/shifts');
                    },
                  ),
                ],
                _buildDrawerItem(
                  icon: Icons.inventory_2_rounded,
                  title: l10n.dispensers,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/assets');
                  },
                ),
                if (roles.contains('delivery_worker') ||
                    roles.contains('onsite_worker') ||
                    roles.contains('client')) ...[
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
                  if (roles.contains('delivery_worker') ||
                      roles.contains('onsite_worker'))
                    _buildDrawerItem(
                      icon: Icons.local_shipping_outlined,
                      title: l10n.workerView,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/worker/home');
                      },
                    ),
                  if (roles.contains('client'))
                    _buildDrawerItem(
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
                  child: Divider(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildDrawerItem(
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? AppTheme.iosRed
            : (selected ? AppTheme.primary : null),
      ),
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

  String _getRoleName(BuildContext context, String role) {
    final l10n = AppLocalizations.of(context)!;
    switch (role) {
      case 'client':
        return l10n.client;
      case 'delivery_worker':
        return l10n.deliveryWorker;
      case 'onsite_worker':
        return l10n.onsiteWorker;
      case 'administrator':
        return l10n.administrator;
      case 'owner':
        return l10n.owner;
      default:
        return role;
    }
  }

  Widget _buildDashboard(
      BuildContext context, DashboardData dashboard, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context),
          const SizedBox(height: 40),

          _buildSectionHeader(l10n.overview),
          _buildMetricsGrid(context, dashboard),
          const SizedBox(height: 40),

          _buildSectionHeader(l10n.revenue),
          _buildRevenueSection(context, dashboard.revenue),
          const SizedBox(height: 40),

          _buildSectionHeader(l10n.quickActions),
          _buildQuickActions(context, dashboard.metrics),
          const SizedBox(height: 40),

          _buildSectionHeader(l10n.stationStatus),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStationStatus(context, ref)),
              const SizedBox(width: 12),
              FloatingActionButton.small(
                onPressed: () => _showAddStationDialog(context, ref),
                backgroundColor: AppTheme.primary,
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
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

  Widget _buildWelcomeSection(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final hour = DateTime.now().hour;
    final l10n = AppLocalizations.of(context)!;
    final greeting = hour < 12
        ? l10n.goodMorning
        : hour < 17
            ? l10n.goodAfternoon
            : l10n.goodEvening;

    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.iosGray,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                userAsync.when(
                  data: (user) {
                    final fullName = user['client_profile']?['full_name'] ?? 
                                   user['worker_profile']?['full_name'] ?? 
                                   StorageService.getFullName() ?? 
                                   user['username'] ?? 
                                   'Admin';
                    return Text(
                      fullName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    );
                  },
                  loading: () => Text(
                    StorageService.getFullName() ?? StorageService.getUsername() ?? 'Admin',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  error: (_, __) => Text(
                    StorageService.getFullName() ?? StorageService.getUsername() ?? 'Admin',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, DashboardData dashboard) {
    final l10n = AppLocalizations.of(context)!;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: [
        _buildMetricCard(
          context: context,
          label: l10n.totalDeliveries,
          value: '${dashboard.metrics.todayDeliveries}',
          icon: Icons.local_shipping_rounded,
          color: AppTheme.primary,
          subtitle: l10n.today,
          onTap: () {
            final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
            ref.read(deliveriesFilterProvider.notifier).state = DeliveriesFilter(startDate: today, endDate: today);
            context.push('/admin/deliveries');
          },
        ),
        _buildMetricCard(
          context: context,
          label: l10n.pendingRequests,
          value: '${dashboard.metrics.pendingRequests + dashboard.metrics.pendingCouponRequests}',
          icon: Icons.assignment_rounded,
          color: AppTheme.midUrgentOrange,
          subtitle: '${dashboard.metrics.pendingRequests} ${l10n.water}, ${dashboard.metrics.pendingCouponRequests} ${l10n.coupons}',
          onTap: () {
            ref.read(requestsFilterProvider.notifier).state = RequestsFilter(status: 'pending');
            context.push('/admin/requests');
          },
        ),
        _buildMetricCard(
          context: context,
          label: l10n.onShiftWorkers,
          value: '${dashboard.metrics.onShiftWorkers}',
          icon: Icons.people_rounded,
          color: AppTheme.successGreen,
          subtitle: l10n.currentlyWorking,
          onTap: () {
            ref.read(usersFilterProvider.notifier).state = UsersFilter(onShift: true);
            context.push('/admin/users');
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color:
                isDark ? Colors.white.withOpacity(0.07) : color.withOpacity(0.15),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppTheme.iosGray),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.iosGray)),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueSection(BuildContext context, DashboardRevenue revenue) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => context.push('/admin/analytics'),
      child: ModernCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.today,
                    style: const TextStyle(color: AppTheme.iosGray, fontSize: 13)),
                Text(
                  '₪${revenue.today.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.successGreen),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(l10n.thisMonth,
                    style: const TextStyle(color: AppTheme.iosGray, fontSize: 13)),
                Text(
                  '₪${revenue.thisMonth.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, dynamic metrics) {
    final l10n = AppLocalizations.of(context)!;
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildQuickActionRow(
            context: context,
            icon: Icons.assignment_rounded,
            label: l10n.requests,
            badge: metrics.pendingRequests > 0
                ? '${metrics.pendingRequests}'
                : null,
            badgeColor: AppTheme.midUrgentOrange,
            onTap: () => context.push('/admin/requests'),
          ),
          const Divider(height: 1),
          _buildQuickActionRow(
            context: context,
            icon: Icons.menu_book_rounded,
            label: l10n.couponRequests,
            badge: metrics.pendingCouponRequests > 0
                ? '${metrics.pendingCouponRequests}'
                : null,
            badgeColor: AppTheme.iosIndigo,
            onTap: () {
              context.push('/admin/requests?index=2');
            },
          ),
          const Divider(height: 1),
          _buildQuickActionRow(
            context: context,
            icon: Icons.local_shipping_rounded,
            label: l10n.deliveries,
            badge: metrics.pendingDeliveries > 0
                ? '${metrics.pendingDeliveries}'
                : null,
            badgeColor: AppTheme.primary,
            onTap: () => context.push('/admin/deliveries'),
          ),
          const Divider(height: 1),
          _buildQuickActionRow(
            context: context,
            icon: Icons.people_rounded,
            label: l10n.workers,
            onTap: () => context.push('/admin/users'),
          ),
          const Divider(height: 1),
          _buildQuickActionRow(
            context: context,
            icon: Icons.bar_chart_rounded,
            label: l10n.analytics,
            onTap: () => context.push('/admin/analytics'),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 22),
            const SizedBox(width: 16),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15))),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppTheme.primary).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: badgeColor ?? AppTheme.primary),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.iosGray3, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildStationStatus(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(fillingStationsProvider);
    final l10n = AppLocalizations.of(context)!;

    return stationsAsync.when(
      data: (stations) {
        if (stations.isEmpty) {
          return ModernCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                l10n.noStationsConfigured,
                style: TextStyle(color: AppTheme.iosGray),
              ),
            ),
          );
        }

        return SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final station = stations[index];
              final l10n = AppLocalizations.of(context)!;

              // ── Elegant, premium station status indicator ─────────────
              final String statusText;
              final Color statusColor;
              final IconData statusIcon;

              switch (station.currentStatus) {
                case StationStatus.open:
                  statusText = l10n.open.toUpperCase();
                  statusColor = AppTheme.successGreen;
                  statusIcon = Icons.check_circle_rounded;
                  break;
                case StationStatus.temporarilyClosed:
                  statusText = l10n.tempClosed.toUpperCase();
                  statusColor = AppTheme.midUrgentOrange;
                  statusIcon = Icons.pause_circle_rounded;
                  break;
                case StationStatus.closedUntilTomorrow:
                  // ── Replaced aggressive red cancel icon with subtle lock ──
                  statusText = l10n.closedUntilTomorrow.toUpperCase();
                  statusColor = const Color(0xFF64748B); // Neutral slate
                  statusIcon = Icons.lock_outline_rounded;
                  break;
              }

              return Container(
                width: 220,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showStationDetails(context, station, ref),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(statusIcon, color: statusColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  station.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (station.address != null &&
                              station.address!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded,
                                    size: 12,
                                    color: statusColor.withOpacity(0.6)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    station.address!,
                                    style: TextStyle(
                                        color: statusColor.withOpacity(0.6),
                                        fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (err, _) {
        final l10n = AppLocalizations.of(context)!;
        return ModernCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.iosRed),
              const SizedBox(width: 12),
              Expanded(child: Text('${l10n.couldNotLoadStationStatus}: $err')),
            ],
          ),
        );
      },
    );
  }

  void _showStationDetails(
      BuildContext context, FillingStation station, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.stationManagement,
                    style: Theme.of(context).textTheme.headlineMedium),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditStationDialog(context, ref, station);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListTile(
              leading:
                  const Icon(Icons.factory_rounded, color: AppTheme.primary),
              title: Text(station.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
              subtitle: Text(station.address ?? l10n.noAddress,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader(l10n.updateStatus),
            const SizedBox(height: 12),
            Row(
              children: [
                _statusActionButton(
                  context,
                  ref,
                  station.id,
                  'open',
                  'Open',
                  AppTheme.successGreen,
                  Icons.check_circle_outline_rounded,
                  station.currentStatus == StationStatus.open,
                ),
                const SizedBox(width: 8),
                _statusActionButton(
                  context,
                  ref,
                  station.id,
                  'temporarilyClosed',
                  'Temp. Close',
                  AppTheme.midUrgentOrange,
                  Icons.pause_circle_outline_rounded,
                  station.currentStatus == StationStatus.temporarilyClosed,
                ),
                const SizedBox(width: 8),
                _statusActionButton(
                  context,
                  ref,
                  station.id,
                  'closedUntilTomorrow',
                  'Full Close',
                  const Color(0xFF64748B),
                  Icons.lock_outline_rounded,
                  station.currentStatus == StationStatus.closedUntilTomorrow,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDeleteStation(context, ref, station),
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.iosRed),
                    label: Text(l10n.delete, style: const TextStyle(color: AppTheme.iosRed)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.iosRed),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.close),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStation(
      BuildContext context, WidgetRef ref, FillingStation station) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.delete),
        content: Text('${l10n.deleteConfirmation} "${station.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await AdminService().deleteStation(station.id);
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                  ref.invalidate(fillingStationsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.stationDeleted),
                      backgroundColor: AppTheme.iosGreen,
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: $e'),
                      backgroundColor: AppTheme.iosRed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.iosRed,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Widget _statusActionButton(
    BuildContext context,
    WidgetRef ref,
    int stationId,
    String status,
    String label,
    Color color,
    IconData icon,
    bool isActive,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: isActive
            ? null
            : () async {
                final l10n = AppLocalizations.of(context)!;
                try {
                  await ref
                      .read(workerOpsProvider.notifier)
                      .updateStationStatus(stationId, status);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${l10n.stationStatusUpdatedTo} ${label.toUpperCase()}'),
                        backgroundColor: AppTheme.iosGreen,
                      ),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Failed to update: $e'),
                          backgroundColor: AppTheme.iosRed),
                    );
                  }
                }
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.12) : Colors.transparent,
            border: Border.all(color: color, width: isActive ? 2 : 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: color, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddStationDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addStation),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.stationName,
                hintText: l10n.enterStationName,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: l10n.stationAddress,
                hintText: l10n.enterStationAddress,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              try {
                await AdminService().createStation(
                  name: nameController.text.trim(),
                  address: addressController.text.trim().isEmpty
                      ? null
                      : addressController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(fillingStationsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.stationAdded),
                      backgroundColor: AppTheme.iosGreen,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: $e'),
                      backgroundColor: AppTheme.iosRed,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showEditStationDialog(
      BuildContext context, WidgetRef ref, FillingStation station) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: station.name);
    final addressController = TextEditingController(text: station.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editStation),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.stationName,
                hintText: l10n.enterStationName,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: l10n.stationAddress,
                hintText: l10n.enterStationAddress,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              try {
                await AdminService().updateStation(
                  stationId: station.id,
                  name: nameController.text.trim(),
                  address: addressController.text.trim().isEmpty
                      ? null
                      : addressController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(fillingStationsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.stationUpdated),
                      backgroundColor: AppTheme.iosGreen,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: $e'),
                      backgroundColor: AppTheme.iosRed,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.read(dashboardProvider);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
            const SizedBox(height: 24),
            Text(
              l10n.notifications,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 24),
            dashboardAsync.when(
              data: (dashboard) {
                final metrics = dashboard.metrics;
                final notifications = [
                  if (metrics.pendingCouponRequests > 0)
                    _NotificationItem(
                      title: l10n.couponRequests,
                      subtitle: '${metrics.pendingCouponRequests} ${l10n.pendingApproval.toLowerCase()}',
                      icon: Icons.menu_book_rounded,
                      color: AppTheme.iosIndigo,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/admin/requests?index=2');
                      },
                    ),
                  if (metrics.pendingRequests > 0)
                    _NotificationItem(
                      title: l10n.pendingRequests,
                      subtitle: '${metrics.pendingRequests} ${l10n.awaitingAction.toLowerCase()}',
                      icon: Icons.assignment_rounded,
                      color: AppTheme.midUrgentOrange,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/admin/requests');
                      },
                    ),
                  if (metrics.urgentRequests > 0)
                    _NotificationItem(
                      title: l10n.urgent,
                      subtitle: '${metrics.urgentRequests} ${l10n.highPriority.toLowerCase()}',
                      icon: Icons.priority_high_rounded,
                      color: AppTheme.criticalRed,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/admin/requests');
                      },
                    ),
                  if (metrics.lowInventoryWorkers > 0)
                    _NotificationItem(
                      title: l10n.lowInventory,
                      subtitle: '${metrics.lowInventoryWorkers} ${l10n.workers.toLowerCase()}',
                      icon: Icons.inventory_2_rounded,
                      color: AppTheme.iosOrange,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/admin/users');
                      },
                    ),
                ];

                if (notifications.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 48, color: AppTheme.iosGray.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(l10n.noActivity, style: TextStyle(color: AppTheme.iosGray, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }

                return Column(children: notifications);
              },
              loading: () => const Center(child: CircularProgressIndicator.adaptive()),
              error: (err, _) => Text('${l10n.error}: $err'),
            ),
          ],
        ),
      ),
    );
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

class _NotificationItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: AppTheme.iosGray, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.iosGray3),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COLLAPSIBLE SECTION HEADER WIDGET (shared)
// ─────────────────────────────────────────────────────────────────────────────
class _CollapsibleSectionHeader extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final Animation<double> chevronAnimation;
  final int itemCount;
  final VoidCallback onToggle;

  const _CollapsibleSectionHeader({
    required this.title,
    required this.isExpanded,
    required this.chevronAnimation,
    required this.itemCount,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.iosGray,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            if (itemCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.iosGray.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$itemCount',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.iosGray),
                ),
              ),
            RotationTransition(
              turns: chevronAnimation,
              child: const Icon(Icons.expand_more_rounded,
                  size: 20, color: AppTheme.iosGray),
            ),
          ],
        ),
      ),
    );
  }
}
