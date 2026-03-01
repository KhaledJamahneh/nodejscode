import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../core/utils/double_utils.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/auth_service.dart';
import '../../../worker/presentation/providers/worker_provider.dart';
import '../../../worker/data/models/worker_models.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../location/presentation/widgets/proximity_alert_banner.dart';
import '../providers/client_provider.dart';
import '../../data/models/client_request.dart';
import '../../data/models/client_models.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  int _selectedIndex = 0;
  bool _notificationsSeen = false;
  bool _proximityNotificationSeen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncHomeLocationFromProfile();
    });
  }

  void _syncHomeLocationFromProfile() {
    final profileAsync = ref.read(clientProfileProvider);
    profileAsync.whenData((profile) {
      if (profile.hasHomeLocation) {
        ref.read(clientHomeLocationProvider.notifier).setManually(
              lat: profile.homeLatitude!,
              lng: profile.homeLongitude!,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _setupListeners();

    final List<Widget> tabs = [
      ClientDashboardTab(
        onSeeAll: () => setState(() => _selectedIndex = 1),
        onNotificationTap: () {
          setState(() {
            _selectedIndex = 2;
            _notificationsSeen = true;
            _proximityNotificationSeen = true;
          });
        },
        notificationsSeen: _notificationsSeen,
        proximityNotificationSeen: _proximityNotificationSeen,
        onProximityNotificationSeen: () => setState(() => _proximityNotificationSeen = true),
      ),
      const ClientRequestsTab(),
      const ClientNotificationsTab(),
      const ClientProfileTab(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      appBar: AppBar(
        title: Text(_getAppBarTitle(context)),
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
            onPressed: () async {
              final locale = ref.read(localeProvider);
              final newLang = locale.languageCode == 'en' ? 'ar' : 'en';
              
              try {
                // Update in database
                final authService = ref.read(authServiceProvider);
                await authService.updateLanguage(newLang);
                
                // Update UI
                ref.read(localeProvider.notifier).setLocale(Locale(newLang));
              } catch (e) {
                // Silently fail, just update UI
                ref.read(localeProvider.notifier).setLocale(Locale(newLang));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(loginProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            tooltip: 'Logout',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshCurrentTab,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: tabs[_selectedIndex],
      ),
      bottomNavigationBar: GlassCard(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(24),
        blur: 20,
        opacity: 0.85,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              if (index == 2) {
                _notificationsSeen = true;
                _proximityNotificationSeen = true;
              }
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded),
              label: l10n.overview,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assignment_outlined),
              activeIcon: const Icon(Icons.assignment_rounded),
              label: l10n.requests,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.notifications_none_rounded),
              activeIcon: const Icon(Icons.notifications_rounded),
              label: l10n.notifications,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: l10n.profile,
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 1
          ? Container(
              margin: const EdgeInsets.only(bottom: 90),
              child: FloatingActionButton.extended(
                onPressed: () => _showCreateRequestFlow(context),
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 8,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.submit),
              ),
            )
          : null,
    );
  }

  String _getAppBarTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_selectedIndex) {
      case 0: return l10n.overview;
      case 1: return l10n.requests;
      case 2: return l10n.notifications;
      case 3: return l10n.profile;
      default: return l10n.appTitle;
    }
  }

  void _refreshCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        ref.invalidate(clientProfileProvider);
        ref.invalidate(clientUsageProvider);
        ref.invalidate(clientRequestsProvider);
        break;
      case 1:
        ref.invalidate(clientRequestsProvider);
        break;
      case 2:
        break;
      case 3:
        ref.invalidate(clientProfileProvider);
        break;
    }
  }

  void _setupListeners() {
    ref.listen(cancelRequestProvider, (previous, next) {
      if (next is AsyncError) {
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar(context, '${l10n.failedToCancelRequest}: ${ErrorHandler.getMessage(next.error)}', isError: true);
      } else if (next is AsyncData && previous is AsyncLoading) {
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar(context, l10n.requestCancelledSuccessfully);
      }
    });

    ref.listen(updateClientProfileProvider, (previous, next) {
      if (next is AsyncError) {
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar(context, '${l10n.failedToUpdateProfile}: ${ErrorHandler.getMessage(next.error)}', isError: true);
      } else if (next is AsyncData && previous is AsyncLoading) {
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar(context, l10n.profileUpdatedSuccessfully);
      }
    });

    ref.listen(changePasswordProvider, (previous, next) {
      if (next is AsyncError) {
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar(context, '${l10n.failedToChangePassword}: ${ErrorHandler.getMessage(next.error)}', isError: true);
      } else if (next is AsyncData && previous is AsyncLoading) {
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar(context, l10n.passwordChangedSuccessfully);
      }
    });

    ref.listen(proximityMonitorProvider, (previous, next) {
      if (next.isNear && !(previous?.isNear ?? false)) {
        if (mounted) {
          _showSnackBar(
            context,
            next.isVeryClose
                ? '🚰 Your delivery worker is arriving now!'
                : '🚚 Your delivery worker is nearby — ${LocationService.formatDistance(next.distanceMeters!)} away',
          );
        }
      }
    });
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppTheme.iosRed : AppTheme.iosGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 10,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final roles = StorageService.getRoles();
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final username = StorageService.getUsername() ?? 'Client';

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05)),
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
                        child: Image.asset('assets/images/ein-logo.png', height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.water_drop, color: AppTheme.primary, size: 40)),
                      ),
                      const SizedBox(height: 12),
                      Text(username, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      Text(l10n.clientView, style: const TextStyle(color: AppTheme.iosGray, fontSize: 13)),
                    ],
                  ),
                ),
                if (roles.contains('delivery_worker') || roles.contains('onsite_worker'))
                  _buildDrawerItem(
                    icon: Icons.work_rounded,
                    title: l10n.workerView,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/worker/home');
                    },
                  ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: Divider()),
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppTheme.primary),
                  title: Text(l10n.language),
                  trailing: Text(
                    locale.languageCode == 'en' ? 'English' : 'العربية',
                    style: const TextStyle(color: AppTheme.iosGray, fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    final newLang = locale.languageCode == 'en' ? 'ar' : 'en';
                    
                    // Show loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Updating language...'), duration: Duration(seconds: 1)),
                    );
                    
                    try {
                      print('🌐 Updating language to: $newLang');
                      
                      // Update in database
                      final authService = ref.read(authServiceProvider);
                      await authService.updateLanguage(newLang);
                      
                      print('✅ Language updated in database');
                      
                      // Update UI
                      ref.read(localeProvider.notifier).setLocale(Locale(newLang));
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.languageUpdated)),
                        );
                      }
                    } catch (e) {
                      print('❌ Language update error: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update language: $e')),
                        );
                      }
                    }
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
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
      leading: Icon(icon, color: isDestructive ? AppTheme.iosRed : (selected ? AppTheme.primary : null)),
      title: Text(title, style: TextStyle(color: isDestructive ? AppTheme.iosRed : (selected ? AppTheme.primary : null), fontWeight: selected ? FontWeight.w700 : FontWeight.w600)),
      selected: selected,
      selectedTileColor: AppTheme.primary.withOpacity(0.08),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// ─── Dashboard Tab ─────────────────────────────────────────────────────────────

class ClientDashboardTab extends ConsumerStatefulWidget {
  final VoidCallback onSeeAll;
  final VoidCallback onNotificationTap;
  final bool notificationsSeen;
  final bool proximityNotificationSeen;
  final VoidCallback onProximityNotificationSeen;
  const ClientDashboardTab({
    super.key, 
    required this.onSeeAll, 
    required this.onNotificationTap, 
    required this.notificationsSeen,
    required this.proximityNotificationSeen,
    required this.onProximityNotificationSeen,
  });

  @override
  ConsumerState<ClientDashboardTab> createState() => _ClientDashboardTabState();
}

class _ClientDashboardTabState extends ConsumerState<ClientDashboardTab> {
  bool _proximityDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryStartMonitoring());
  }

  void _tryStartMonitoring() {
    final profileAsync = ref.read(clientProfileProvider);
    final activeRequest = ref.read(activeInProgressRequestProvider);

    profileAsync.whenData((profile) {
      if (!profile.hasHomeLocation) return;
      if (activeRequest == null) return;

      ref.read(proximityMonitorProvider.notifier).startMonitoring(
            deliveryId: activeRequest.id,
            homeLat: profile.homeLatitude!,
            homeLng: profile.homeLongitude!,
            isRequest: true,
          );
    });
  }

  String _getGreeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(clientProfileProvider);
    final usageAsync = ref.watch(clientUsageProvider);
    final proximityState = ref.watch(proximityMonitorProvider);
    final l10n = AppLocalizations.of(context)!;

    ref.listen(clientProfileProvider, (_, __) => _tryStartMonitoring());
    ref.listen(activeInProgressRequestProvider, (_, __) => _tryStartMonitoring());

    ref.listen(proximityMonitorProvider, (prev, next) {
      if (next.isNear && !(prev?.isNear ?? false)) {
        setState(() {
          _proximityDismissed = false;
        });
        widget.onProximityNotificationSeen();
      }
    });

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, profileAsync, proximityState),
          const SizedBox(height: 24),

          if (!_proximityDismissed && proximityState.isNear)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: ProximityAlertBanner(
                state: proximityState,
                onDismiss: () => setState(() => _proximityDismissed = true),
              ),
            ),

          profileAsync.when(
            data: (profile) => Column(
              children: [
                _buildPremiumHeroCard(context, profile),
                if (profile.currentDebt > 0) ...[
                  const SizedBox(height: 16),
                  _buildDebtBanner(context, profile.currentDebt),
                ],
              ],
            ),
            loading: () => const _Skeleton(height: 160),
            error: (err, _) => ModernCard(child: Text('${l10n.error}: $err')),
          ),

          const SizedBox(height: 32),
          _buildSectionHeader(l10n.quickActions),
          _buildModernQuickActions(context),

          const SizedBox(height: 32),
          _buildSectionHeader(l10n.stationStatus),
          _buildStationStatusCard(context),

          const SizedBox(height: 32),
          _buildRecentDeliveriesSection(context, usageAsync, l10n),
          
          const SizedBox(height: 32),
          _buildSectionHeader(l10n.announcements),
          _buildAnnouncementsCarousel(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<ClientProfile> profileAsync, ProximityState proximityState) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profileAsync.when(
                data: (profile) => Text(
                  '${_getGreeting(context)}, ${profile.fullName.split(' ')[0]}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                loading: () => Text(_getGreeting(context), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                error: (_, __) => Text(_getGreeting(context), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat.yMMMMd(Localizations.localeOf(context).languageCode).format(DateTime.now()),
                style: const TextStyle(color: AppTheme.iosGray, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            widget.onNotificationTap();
            widget.onProximityNotificationSeen();
          },
          child: _buildNotificationBadge(proximityState),
        ),
      ],
    );
  }

  Widget _buildPremiumHeroCard(BuildContext context, ClientProfile profile) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Icon(Icons.water_drop_rounded, size: 180, color: Colors.white.withOpacity(0.1)),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getSubscriptionTypeDisplay(context, profile.subscriptionType),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                      ),
                      if (profile.subscriptionExpiryDate != null)
                        Text(
                          l10n.expiresIn(7),
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.remainingCoupons.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text('${profile.remainingCoupons}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 1)),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: (profile.remainingCoupons / 50.0).clamp(0.0, 1.0),
                              strokeWidth: 6,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernQuickActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            context,
            title: l10n.requestWaterDelivery,
            icon: Icons.local_shipping_rounded,
            color: AppTheme.primaryBlue,
            onTap: () => _showCreateRequestFlow(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildQuickActionButton(
            context,
            title: l10n.requestCouponBook,
            icon: Icons.style_rounded,
            color: AppTheme.iosIndigo,
            onTap: () => _showCouponBookFlow(context),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppTheme.textPrimary, height: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildStationStatusCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stationsAsync = ref.watch(fillingStationsProvider);
    return stationsAsync.when(
      data: (stations) {
        if (stations.isEmpty) return const SizedBox.shrink();
        final station = stations.first;
        String statusText;
        Color statusColor;
        IconData statusIcon;
        switch (station.currentStatus) {
          case StationStatus.open:
            statusText = l10n.stationIsOpen;
            statusColor = AppTheme.successGreen;
            statusIcon = Icons.check_circle_rounded;
            break;
          case StationStatus.temporarilyClosed:
            statusText = l10n.temporarilyClosed;
            statusColor = AppTheme.midUrgentOrange;
            statusIcon = Icons.pause_circle_rounded;
            break;
          case StationStatus.closedUntilTomorrow:
            statusText = l10n.closedUntilTomorrow;
            statusColor = AppTheme.criticalRed;
            statusIcon = Icons.lock_outline_rounded;
            break;
          default:
            statusText = l10n.unknownStatus;
            statusColor = AppTheme.iosGray;
            statusIcon = Icons.help_rounded;
        }
        return ModernCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: Icon(statusIcon, color: statusColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(station.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 2),
                    Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: statusColor.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)]),
              ),
            ],
          ),
        );
      },
      loading: () => const _Skeleton(height: 80),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRecentDeliveriesSection(BuildContext context, AsyncValue<UsageHistory> usageAsync, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(l10n.recentDeliveries),
            TextButton(
              onPressed: widget.onSeeAll,
              child: Row(children: [Text(l10n.seeAll, style: const TextStyle(fontWeight: FontWeight.w700)), const Icon(Icons.chevron_right_rounded, size: 18)]),
            ),
          ],
        ),
        usageAsync.when(
          data: (usage) {
            if (usage.recentDeliveries.isEmpty) return _buildEmptyDeliveries(context);
            return Column(children: usage.recentDeliveries.take(3).map((d) => _buildDeliveryCard(context, d)).toList());
          },
          loading: () => const _Skeleton(height: 100),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildNotificationBadge(ProximityState ps) {
    final unreadCountAsync = ref.watch(unreadCountPollingProvider);
    final unreadCount = unreadCountAsync.value ?? 0;
    final hasUnread = unreadCount > 0;
    final showBadge = (ps.isNear && !widget.proximityNotificationSeen) || hasUnread;
    
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (ps.isNear ? AppTheme.primaryBlue : AppTheme.primary).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            ps.isNear ? Icons.local_shipping_rounded : Icons.notifications_none_rounded,
            color: ps.isNear ? AppTheme.primaryBlue : AppTheme.primary,
          ),
        ),
        if (showBadge)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: EdgeInsets.all(hasUnread ? 4 : 6),
              decoration: const BoxDecoration(
                color: AppTheme.criticalRed,
                shape: BoxShape.circle,
              ),
              child: hasUnread 
                ? Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  )
                : null,
            ),
          ),
      ],
    );
  }

  Widget _buildDebtBanner(BuildContext context, double debt) {
    final l10n = AppLocalizations.of(context)!;
    return ModernCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      color: AppTheme.criticalRed.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.criticalRed, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.debt, style: const TextStyle(color: AppTheme.criticalRed, fontWeight: FontWeight.w800, fontSize: 14)),
                Text('₪$debt', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.criticalRed, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), minimumSize: const Size(0, 0)),
            child: Text(l10n.payNow),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDeliveries(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.water_drop_outlined, size: 48, color: AppTheme.iosGray.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(l10n.noActivity, style: TextStyle(color: AppTheme.iosGray.withOpacity(0.6), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context, dynamic delivery) {
    final l10n = AppLocalizations.of(context)!;
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.water_drop_rounded, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${delivery['gallons_delivered']} ${l10n.gallons}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                Text(DateFormat('MMMM d, yyyy').format(DateTime.parse(delivery['delivery_date'])), style: const TextStyle(color: AppTheme.iosGray, fontSize: 14)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 24),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsCarousel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: 300,
          margin: const EdgeInsets.only(right: 16),
          child: ModernCard(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(color: AppTheme.accentSkyBlue.withOpacity(0.2), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                  child: const Center(child: Icon(Icons.image, color: Colors.white, size: 48)),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.specialOffer, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(l10n.summerOfferDesc, style: const TextStyle(fontSize: 12, color: AppTheme.iosGray)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  final double? width;
  const _Skeleton({required this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

// ─── Requests Tab ──────────────────────────────────────────────────────────────

class ClientRequestsTab extends ConsumerWidget {
  const ClientRequestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(clientRequestsProvider);
    final couponRequestsAsync = ref.watch(couponBookRequestsProvider);
    final l10n = AppLocalizations.of(context)!;

    return requestsAsync.when(
      data: (requests) {
        return couponRequestsAsync.when(
          data: (couponRequests) {
            if (requests.isEmpty && couponRequests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: AppTheme.iosGray.withOpacity(0.05), shape: BoxShape.circle), child: Icon(Icons.assignment_rounded, size: 80, color: AppTheme.iosGray.withOpacity(0.2))),
                    const SizedBox(height: 24),
                    Text(l10n.noActivity, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.iosGray)),
                    const SizedBox(height: 8),
                    Text(l10n.yourRequestsAppearHere, style: const TextStyle(fontSize: 15, color: AppTheme.iosGray)),
                  ],
                ),
              );
            }
            final activeRequests = requests.where((r) => r.status != 'completed' && r.status != 'cancelled').toList();
            final historyRequests = requests.where((r) => r.status == 'completed' || r.status == 'cancelled').toList();
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                if (activeRequests.isNotEmpty || couponRequests.isNotEmpty) ...[
                  _buildSectionHeader('Active Requests'),
                  const SizedBox(height: 12),
                  ...activeRequests.map((r) => _buildRequestCard(context, ref, r)),
                  ...couponRequests.map((cr) => _buildCouponBookRequestCard(context, cr)),
                  const SizedBox(height: 24),
                ],
                if (historyRequests.isNotEmpty) ...[
                  _buildSectionHeader('Order History'),
                  const SizedBox(height: 12),
                  ...historyRequests.map((r) => _buildRequestCard(context, ref, r)),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (_, __) => const Center(child: Icon(Icons.error_outline_rounded)),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => Center(child: Text('${l10n.error}: $err')),
    );
  }

  Widget _buildCouponBookRequestCard(BuildContext context, Map<String, dynamic> request) {
    final l10n = AppLocalizations.of(context)!;
    final status = request['status'] ?? 'pending';
    final statusColor = status == 'pending' ? AppTheme.midUrgentOrange : status == 'approved' ? AppTheme.successGreen : status == 'delivered' ? AppTheme.primaryBlue : AppTheme.iosGray;
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(status.toUpperCase(), statusColor),
              Text(_formatDateShort(request['created_at']), style: const TextStyle(fontSize: 13, color: AppTheme.iosGray, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(request['book_type'] == 'physical' ? Icons.menu_book_rounded : Icons.qr_code_2_rounded, size: 28, color: AppTheme.primaryBlue)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${request['book_size']} ${l10n.pages}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(request['book_type'] == 'physical' ? 'Physical Coupon Book' : 'Digital Coupons', style: const TextStyle(fontSize: 14, color: AppTheme.iosGray, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Text('₪${request['total_price']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, WidgetRef ref, ClientRequest request) {
    final statusColor = StatusColors.getColor(request.status);
    final statusIcon = StatusColors.getIcon(request.status);
    final l10n = AppLocalizations.of(context)!;
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(request.statusDisplay.toUpperCase(), statusColor, icon: statusIcon),
              Text(_formatDateShort(request.requestDate), style: const TextStyle(fontSize: 13, color: AppTheme.iosGray, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.water_drop_rounded, size: 28, color: AppTheme.primaryBlue)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${request.requestedGallons} ${l10n.gallons}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    if (request.notes != null && request.notes!.isNotEmpty) Text(request.notes!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppTheme.iosGray, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              if (request.canCancel) IconButton(onPressed: () => _confirmCancel(context, ref, request), icon: const Icon(Icons.cancel_outlined, color: AppTheme.iosRed, size: 22), visualDensity: VisualDensity.compact),
            ],
          ),
          if (request.status == 'in_progress' && request.assignedWorkerName != null) ...[const SizedBox(height: 20), _buildWorkerInfo(context, request)],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 6)], Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5))]),
    );
  }

  Widget _buildWorkerInfo(BuildContext context, ClientRequest request) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.person_rounded, color: AppTheme.primaryBlue, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(request.assignedWorkerName!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)), if (request.workerPhone != null) Text(request.workerPhone!, style: const TextStyle(color: AppTheme.iosGray, fontSize: 12))])),
          const Icon(Icons.local_shipping_rounded, color: AppTheme.primaryBlue, size: 20),
        ],
      ),
    );
  }
}

// ─── Notifications Tab ─────────────────────────────────────────────────────────

class ClientNotificationsTab extends ConsumerWidget {
  const ClientNotificationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proximityState = ref.watch(proximityMonitorProvider);
    final notificationsAsync = ref.watch(notificationsProvider('client'));
    final l10n = AppLocalizations.of(context)!;

    return notificationsAsync.when(
      data: (data) {
        final notifications = data['notifications'] as List;

        return RefreshIndicator(
          onRefresh: () => ref.refresh(notificationsProvider('client').future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              if (notifications.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await ref
                            .read(notificationServiceProvider)
                            .markAllAsRead();
                        ref.invalidate(notificationsProvider);
                        ref.invalidate(unreadCountProvider);
                      },
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text('Mark all read'),
                    ),
                  ],
                ),
              if (proximityState.isNear)
                ProximityNotificationTile(state: proximityState),
              if (notifications.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      Icon(Icons.notifications_off_outlined,
                          size: 64, color: AppTheme.iosGray.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(l10n.noActivity,
                          style: const TextStyle(color: AppTheme.iosGray)),
                    ],
                  ),
                )
              else
                ...notifications.map((notif) {
                  final isRead = notif['is_read'] ?? false;
                  final type = notif['type'] ?? '';
                  final createdAt = DateTime.parse(notif['created_at']);

                  Color borderColor = AppTheme.primary;
                  if (type == 'important' || type == 'critical')
                    borderColor = AppTheme.criticalRed;
                  if (type == 'mid' || type == 'warning')
                    borderColor = AppTheme.midUrgentOrange;

                  return ModernCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.zero,
                    color: isRead ? null : AppTheme.primaryBlue.withOpacity(0.05),
                    child: InkWell(
                      onTap: () async {
                        if (!isRead) {
                          await ref
                              .read(notificationServiceProvider)
                              .markAsRead(notif['id']);
                          ref.invalidate(notificationsProvider);
                          ref.invalidate(unreadCountProvider);
                        }
                        _navigateToReference(context, notif);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Container(
                                width: 6,
                                decoration: BoxDecoration(
                                    color: borderColor,
                                    borderRadius: const BorderRadius.horizontal(
                                        left: Radius.circular(20)))),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(notif['title'] ?? '',
                                                style: TextStyle(
                                                    fontWeight: isRead
                                                        ? FontWeight.w600
                                                        : FontWeight.w800,
                                                    fontSize: 16)),
                                          ),
                                          Text(timeago.format(createdAt),
                                              style: const TextStyle(
                                                  color: AppTheme.iosGray,
                                                  fontSize: 12))
                                        ]),
                                    const SizedBox(height: 4),
                                    Text(notif['message'] ?? '',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                            fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  void _navigateToReference(BuildContext context, Map<String, dynamic> notification) {
    final referenceType = notification['reference_type'];
    final referenceId = notification['reference_id'];

    if (referenceType == null || referenceId == null) return;

    switch (referenceType) {
      case 'coupon_book_request':
        // index 1 is requests tab in client home
        break;
      case 'delivery_request':
        break;
      case 'delivery':
        break;
    }
  }
}

// ─── Profile Tab ───────────────────────────────────────────────────────────────

class ClientProfileTab extends ConsumerWidget {
  const ClientProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(clientProfileProvider);
    final l10n = AppLocalizations.of(context)!;
    return profileAsync.when(
      data: (profile) => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          _buildProfileHero(context, profile),
          const SizedBox(height: 32),
          _buildSectionHeader(l10n.accountInfo),
          ModernCard(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildModernInfoRow(Icons.person_outline_rounded, l10n.fullName, profile.fullName),
                _buildModernInfoRow(Icons.location_on_outlined, l10n.address, profile.address),
                _buildModernInfoRow(Icons.badge_outlined, l10n.username, StorageService.getUsername() ?? '-', isLast: true),
              ],
            ),
          ),
          _buildSectionHeader(l10n.deliveryLocation),
          _HomeLocationCard(profile: profile),
          const SizedBox(height: 32),
          _buildSectionHeader(l10n.subscription),
          ModernCard(
            margin: const EdgeInsets.only(bottom: 32),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildModernInfoRow(Icons.card_membership_rounded, l10n.type, _getSubscriptionTypeDisplay(context, profile.subscriptionType), color: AppTheme.primaryBlue),
                _buildModernInfoRow(Icons.info_outline_rounded, l10n.status, _getSubscriptionStatusDisplay(context, profile.subscriptionStatus), color: profile.subscriptionStatus == 'active' ? AppTheme.successGreen : AppTheme.criticalRed),
                if (profile.subscriptionExpiryDate != null)
                  _buildModernInfoRow(Icons.event_available_rounded, l10n.expires, DateFormat('MMM d, yyyy').format(DateTime.parse(profile.subscriptionExpiryDate!)), isLast: true),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showEditProfileDialog(context, ref, profile),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(l10n.edit),
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showChangePasswordDialog(context, ref),
                  icon: const Icon(Icons.lock_reset_rounded, size: 18),
                  label: Text(l10n.password),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryBlue, side: const BorderSide(color: AppTheme.primaryBlue), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Center(child: Text('Version 2.1.0', style: TextStyle(color: AppTheme.iosGray.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => Center(child: Text('${l10n.error}: $err')),
    );
  }

  Widget _buildProfileHero(BuildContext context, ClientProfile profile) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2), width: 2)),
              child: CircleAvatar(radius: 54, backgroundColor: AppTheme.primaryBlue.withOpacity(0.1), child: const Icon(Icons.person_rounded, size: 60, color: AppTheme.primaryBlue)),
            ),
            Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppTheme.successGreen, shape: BoxShape.circle), child: const Icon(Icons.verified_rounded, color: Colors.white, size: 16)),
          ],
        ),
        const SizedBox(height: 20),
        Text(profile.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(profile.address, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.iosGray, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value, {bool isLast = false, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Colors.black.withOpacity(0.03)))),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.iosGray),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.iosGray)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color ?? AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

// ─── Home Location Card ────────────────────────────────────────────────────────

class _HomeLocationCard extends ConsumerWidget {
  final ClientProfile profile;
  const _HomeLocationCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locationState = ref.watch(clientHomeLocationProvider);
    final hasLocation = locationState.hasLocation || profile.hasHomeLocation;
    final displayLat = locationState.latitude ?? profile.homeLatitude;
    final displayLng = locationState.longitude ?? profile.homeLongitude;
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (hasLocation ? AppTheme.successGreen : AppTheme.iosGray).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(hasLocation ? Icons.home_rounded : Icons.add_home_rounded, color: hasLocation ? AppTheme.successGreen : AppTheme.iosGray)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(hasLocation ? l10n.homeLocationSaved : l10n.setHomeLocation, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: hasLocation ? AppTheme.successGreen : null)), Text(hasLocation ? l10n.workersWillBeNotified : l10n.requiredToReceiveAlerts, style: const TextStyle(color: AppTheme.iosGray, fontSize: 13))])),
            ],
          ),
          if (hasLocation && displayLat != null && displayLng != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.successGreen.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.successGreen.withOpacity(0.2))),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppTheme.successGreen, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${displayLat.toStringAsFixed(6)}, ${displayLng.toStringAsFixed(6)}', style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.successGreen))),
                  GestureDetector(onTap: () { Clipboard.setData(ClipboardData(text: '$displayLat, $displayLng')); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.coordinatesCopied), behavior: SnackBarBehavior.floating)); }, child: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.iosGray)),
                ],
              ),
            ),
          ],
          if (locationState.error != null) ...[const SizedBox(height: 10), Text(locationState.error!, style: const TextStyle(color: AppTheme.criticalRed, fontSize: 13))],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: FilledButton.icon(onPressed: locationState.isSaving ? null : () => _useGPS(context, ref), icon: locationState.isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.my_location_rounded, size: 18), label: Text(hasLocation ? l10n.updateViaGPS : l10n.useMyLocation), style: FilledButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 12)))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: () => _showManualEntry(context, ref, displayLat, displayLng), icon: const Icon(Icons.edit_location_alt_rounded, size: 18), label: Text(l10n.enterManually), style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, side: BorderSide(color: AppTheme.primary.withOpacity(0.4)), padding: const EdgeInsets.symmetric(vertical: 12)))),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _useGPS(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), title: Text(l10n.confirm), content: Text(l10n.updateViaGPS), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.confirm))]));
    if (confirmed != true) return;
    await ref.read(clientHomeLocationProvider.notifier).setFromCurrentGPS();
    final state = ref.read(clientHomeLocationProvider);
    if (state.isSaved && state.hasLocation) {
      try { await ref.read(clientServiceProvider).saveHomeLocation(latitude: state.latitude!, longitude: state.longitude!); ref.invalidate(clientProfileProvider); } catch (_) {}
    }
    if (context.mounted) {
      final s = ref.read(clientHomeLocationProvider);
      if (s.isSaved) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${l10n.homeLocationSaved}'), backgroundColor: AppTheme.successGreen, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), margin: const EdgeInsets.all(16)));
    }
  }

  void _showManualEntry(BuildContext context, WidgetRef ref, double? currentLat, double? currentLng) {
    final l10n = AppLocalizations.of(context)!;
    final latCtrl = TextEditingController(text: currentLat?.toString() ?? '');
    final lngCtrl = TextEditingController(text: currentLng?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [Icon(Icons.edit_location_alt_rounded, color: AppTheme.primary), const SizedBox(width: 10), Text(l10n.enterCoordinates)]),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: latCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: l10n.latitude, hintText: 'e.g. 31.7683', prefixIcon: const Icon(Icons.north_rounded)), validator: (v) { final d = double.tryParse(v ?? ''); if (d == null) return l10n.enterValidNumber; if (d < -90 || d > 90) return l10n.mustBeBetween('-90', '90'); return null; }),
                const SizedBox(height: 16),
                TextFormField(controller: lngCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: l10n.longitude, hintText: 'e.g. 35.2137', prefixIcon: const Icon(Icons.east_rounded)), validator: (v) { final d = double.tryParse(v ?? ''); if (d == null) return l10n.enterValidNumber; if (d < -180 || d > 180) return l10n.mustBeBetween('-180', '180'); return null; }),
                const SizedBox(height: 8),
                Text(l10n.coordinatesTip, style: const TextStyle(color: AppTheme.iosGray, fontSize: 12)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final lat = double.parse(latCtrl.text);
              final lng = double.parse(lngCtrl.text);
              Navigator.pop(context);
              await ref.read(clientHomeLocationProvider.notifier).setManually(lat: lat, lng: lng);
              try { await ref.read(clientServiceProvider).saveHomeLocation(latitude: lat, longitude: lng); ref.invalidate(clientProfileProvider); } catch (_) {}
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${l10n.homeLocationSaved}'), backgroundColor: AppTheme.successGreen, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), margin: const EdgeInsets.all(16)));
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 45)),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Helpers ────────────────────────────────────────────────────────────

Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 12),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppTheme.iosGray,
        letterSpacing: 1.2,
      ),
    ),
  );
}

void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('${l10n.password} ${l10n.update}'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: currentCtrl, obscureText: true, decoration: InputDecoration(labelText: l10n.currentPassword), validator: (v) => v!.isEmpty ? l10n.required : null),
              const SizedBox(height: 16),
              TextFormField(controller: newCtrl, obscureText: true, decoration: InputDecoration(labelText: l10n.newPassword), validator: (v) => v!.length < 8 ? l10n.min8Chars : null),
              const SizedBox(height: 16),
              TextFormField(controller: confirmCtrl, obscureText: true, decoration: InputDecoration(labelText: l10n.confirmNewPassword), validator: (v) => v != newCtrl.text ? l10n.passwordsDoNotMatch : null),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              ref.read(changePasswordProvider.notifier).changePassword(currentCtrl.text, newCtrl.text);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(100, 45)),
          child: Text(l10n.update),
        ),
      ],
    ),
  );
}

void _showEditProfileDialog(BuildContext context, WidgetRef ref, ClientProfile profile) {
  final l10n = AppLocalizations.of(context)!;
  final nameCtrl = TextEditingController(text: profile.fullName);
  final addressCtrl = TextEditingController(text: profile.address);
  final formKey = GlobalKey<FormState>();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('${l10n.edit} ${l10n.profile}'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameCtrl, decoration: InputDecoration(labelText: l10n.fullName), validator: (v) => v!.isEmpty ? l10n.required : null),
              const SizedBox(height: 16),
              TextFormField(controller: addressCtrl, decoration: InputDecoration(labelText: l10n.address), maxLines: 3, validator: (v) => v!.isEmpty ? l10n.required : null),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              ref.read(updateClientProfileProvider.notifier).updateProfile({'full_name': nameCtrl.text, 'address': addressCtrl.text});
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(100, 45)),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
}

void _confirmCancel(BuildContext context, WidgetRef ref, ClientRequest request) {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('${l10n.cancel} ${l10n.requests}', style: const TextStyle(color: AppTheme.iosRed)),
      content: Text(l10n.cancelRequestConfirm(request.requestedGallons)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.goBack)),
        ElevatedButton(
          onPressed: () {
            ref.read(cancelRequestProvider.notifier).cancelRequest(request.id);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.iosRed, minimumSize: const Size(100, 45)),
          child: Text(l10n.cancel),
        ),
      ],
    ),
  );
}

void _showCouponBookFlow(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  int step = 1;
  String bookType = 'physical';
  int? selectedSizeId;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) => Consumer(
      builder: (context, ref, _) {
        final sizesAsync = ref.watch(couponSizesProvider);
        return StatefulBuilder(
          builder: (context, setModalState) => GlassCard(
            color: Theme.of(context).scaffoldBackgroundColor,
            opacity: 0.98,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            margin: EdgeInsets.zero,
            padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.iosGray4, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  if (step == 1) ...[
                    Text(l10n.couponBookType, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 24),
                    _buildSelectionCard(icon: Icons.menu_book_rounded, title: l10n.physicalBook, subtitle: l10n.requestPhysicalCouponBook, isSelected: bookType == 'physical', onTap: () => setModalState(() => bookType = 'physical')),
                    const SizedBox(height: 12),
                    _buildSelectionCard(icon: Icons.qr_code_2_rounded, title: l10n.electronicBook, subtitle: l10n.buyDigitalCouponBook, isSelected: bookType == 'electronic', onTap: () => setModalState(() => bookType = 'electronic')),
                    const SizedBox(height: 32),
                    FilledButton(onPressed: () => setModalState(() => step = 2), child: Text(l10n.next)),
                  ] else if (step == 2) ...[
                    Text(l10n.selectBookSize, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 24),
                    sizesAsync.when(
                      data: (sizes) {
                        if (sizes.isEmpty) return const Text('No coupon books available');
                        return Column(children: sizes.map((s) {
                          final bonus = s['bonus_gallons'] ?? 0;
                          final totalGallons = s['total_gallons'] ?? s['size'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildSelectionCard(
                              icon: Icons.style_rounded,
                              title: '${s['size']} ${l10n.gallons}${bonus > 0 ? " + $bonus bonus" : ""}',
                              subtitle: '₪${DoubleUtils.toDouble(s['price'])} • Total: $totalGallons ${l10n.gallons}',
                              isSelected: selectedSizeId == s['id'],
                              onTap: () => setModalState(() { selectedSizeId = s['id']; })
                            )
                          );
                        }).toList());
                      },
                      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                      error: (_, __) => const Text('Error loading sizes'),
                    ),
                    const SizedBox(height: 32),
                    Row(children: [
                      Expanded(child: OutlinedButton(onPressed: () => setModalState(() => step = 1), child: Text(l10n.goBack))),
                      const SizedBox(width: 12),
                      Expanded(child: FilledButton(
                        onPressed: selectedSizeId == null ? null : () async {
                          if (bookType == 'electronic') {
                            // Electronic: purchase directly
                            await ref.read(couponBookRequestsProvider.notifier).requestCouponBook(selectedSizeId!, bookType, 'credit_card');
                            Navigator.pop(modalContext);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${l10n.purchaseComplete}'), behavior: SnackBarBehavior.floating));
                          } else {
                            // Physical: go to payment step
                            setModalState(() => step = 3);
                          }
                        },
                        child: Text(bookType == 'electronic' ? l10n.buyNow : l10n.next)
                      ))
                    ]),
                  ] else if (step == 3) ...[
                    Text(l10n.howWillYouPay, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 24),
                    _buildSelectionCard(icon: Icons.payments_rounded, title: l10n.cashOnDelivery, subtitle: l10n.payWhenWaterArrives, isSelected: true, onTap: () {}),
                    const SizedBox(height: 32),
                    Row(children: [Expanded(child: OutlinedButton(onPressed: () => setModalState(() => step = 2), child: Text(l10n.goBack))), const SizedBox(width: 12), Expanded(child: FilledButton(onPressed: () async { await ref.read(couponBookRequestsProvider.notifier).requestCouponBook(selectedSizeId!, bookType, 'cash'); Navigator.pop(modalContext); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${l10n.requestSubmitted}'), behavior: SnackBarBehavior.floating)); }, child: Text(l10n.confirm)))]),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildSelectionCard({required IconData icon, required String title, required String subtitle, required bool isSelected, required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isSelected ? AppTheme.primaryBlue.withOpacity(0.05) : null, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? AppTheme.primaryBlue : AppTheme.iosGray4, width: isSelected ? 2 : 1)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : AppTheme.iosGray6, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: isSelected ? AppTheme.primaryBlue : AppTheme.iosGray)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isSelected ? AppTheme.primaryBlue : null)), Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.iosGray))])),
          if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue),
        ],
      ),
    ),
  );
}

void _showCreateRequestFlow(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  int gallons = 10;
  final notesCtrl = TextEditingController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Consumer(
      builder: (context, ref, _) => StatefulBuilder(
        builder: (context, setModalState) => GlassCard(
          color: Theme.of(context).scaffoldBackgroundColor,
          opacity: 0.98,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          margin: EdgeInsets.zero,
          padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.iosGray4, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text(l10n.requestWaterDelivery, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGallonButton(Icons.remove_rounded, () { if (gallons > 1) setModalState(() => gallons--); }),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Column(children: [Text('$gallons', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)), Text(l10n.gallons.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.iosGray))])),
                  _buildGallonButton(Icons.add_rounded, () => setModalState(() => gallons++)),
                ],
              ),
              const SizedBox(height: 32),
              TextField(controller: notesCtrl, decoration: InputDecoration(hintText: l10n.addInstructions, prefixIcon: const Icon(Icons.note_alt_outlined))),
              const SizedBox(height: 32),
              FilledButton(onPressed: () async { await ref.read(createRequestProvider.notifier).createRequest(gallons, notesCtrl.text); Navigator.pop(context); }, child: Text(l10n.submit)),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildGallonButton(IconData icon, VoidCallback onTap) {
  return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: AppTheme.primaryBlue, size: 32)));
}

String _formatDateShort(String? date) {
  if (date == null) return '';
  try { final dt = DateTime.parse(date); return DateFormat('MMM d, h:mm a').format(dt); } catch (_) { return date; }
}

String _getSubscriptionTypeDisplay(BuildContext context, String type) {
  final l10n = AppLocalizations.of(context)!;
  switch (type.toLowerCase()) {
    case 'coupon':
    case 'coupons':
    case 'coupon_book': return l10n.coupons.toUpperCase();
    case 'cash': return l10n.cash.toUpperCase();
    default: return type.toUpperCase();
  }
}

String _getSubscriptionStatusDisplay(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context)!;
  switch (status.toLowerCase()) {
    case 'active': return l10n.active.toUpperCase();
    case 'inactive': return l10n.inactive.toUpperCase();
    case 'expired': return l10n.expired.toUpperCase();
    case 'cancelled': return l10n.cancelled.toUpperCase();
    default: return status.toUpperCase();
  }
}
