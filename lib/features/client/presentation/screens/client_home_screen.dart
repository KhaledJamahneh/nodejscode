// lib/features/client/presentation/screens/client_home_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/client_provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../data/models/client_models.dart';

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(clientProfileProvider);
    final usageAsync = ref.watch(clientUsageProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(clientProfileProvider);
          ref.invalidate(clientRequestsProvider);
          ref.invalidate(clientUsageProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppTheme.glassBg.withOpacity(0.8),
              floating: true,
              pinned: true,
              snap: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(color: Colors.transparent),
                ),
              ),
              title: profileAsync.when(
                data: (profile) => _buildHeader(context, profile.fullName),
                loading: () => _buildHeader(context, '...'),
                error: (_, __) => _buildHeader(context, 'Client'),
              ),
              actions: [
                Consumer(
                  builder: (context, ref, child) {
                    final unreadCount = ref.watch(unreadCountPollingProvider).asData?.value ?? 0;
                    return IconButton(
                      onPressed: () => context.push('/notifications'),
                      icon: Badge(
                        label: Text('$unreadCount'),
                        isLabelVisible: unreadCount > 0,
                        child: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    profileAsync.when(
                      data: (profile) => _BalanceCard(profile: profile),
                      loading: () => const _SkeletonCard(height: 224),
                      error: (err, _) => Text('Error: $err'),
                    ),
                    const SizedBox(height: 24),
                    _SmartSuggestionCard(),
                    const SizedBox(height: 24),
                    Text(l10n.quickActions, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 16),
                    _QuickActionsGrid(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.recentDeliveries, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        TextButton(
                          onPressed: () => context.push('/client/history'), 
                          child: Text(l10n.viewAllHistory)
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    usageAsync.when(
                      data: (usage) {
                        if (usage.recentDeliveries.isEmpty) {
                          return Center(child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(l10n.noActivity, style: TextStyle(color: AppTheme.textSecondary)),
                          ));
                        }
                        return _RecentDeliveryCard(delivery: usage.recentDeliveries.first);
                      },
                      loading: () => const _SkeletonCard(height: 80),
                      error: (err, _) => Text('Error: $err'),
                    ),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ClientBottomNavBar(),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded, color: AppTheme.primaryBlue, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ],
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final ClientProfile profile;
  const _BalanceCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isCoupon = profile.subscriptionType == 'coupon_book';
    
    return Container(
      height: 224,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, Color(0xFF03A9F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          _buildWave(context),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Balance', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                        Text(
                          isCoupon 
                            ? '${profile.remainingCoupons} Coupons' 
                            : '${profile.gallonsOnHand} Gallons', 
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                     Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3))
                      ),
                      child: Text(
                        profile.subscriptionType.toUpperCase().replaceAll('_', ' '), 
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)
                      ),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bonus Gallons', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                        Text('${profile.bonusGallons}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (profile.currentDebt > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Current Debt', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                          Text('\$${profile.currentDebt.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWave(BuildContext context) {
    return Positioned(
      bottom: -50,
      right: -50,
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SmartSuggestionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.glassBorder)
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBlue.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Smart Suggestion', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                const Text(
                  'Based on your usage, you will likely need a refill soon.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                 const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push('/client/request-water'),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.secondaryBlue.withOpacity(0.7),
                    foregroundColor: AppTheme.primaryBlue,
                    minimumSize: const Size(double.infinity, 36),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Request Delivery'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeRequest = ref.watch(activeInProgressRequestProvider);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _QuickActionItem(
          icon: Icons.water_drop, 
          label: l10n.requestWaterDelivery, 
          color: AppTheme.primaryBlue,
          onTap: () => context.push('/client/request-water'),
        ),
        _QuickActionItem(
          icon: Icons.confirmation_number, 
          label: l10n.buyNow, 
          color: Colors.purple,
          onTap: () => context.push('/client/buy-coupons'),
        ),
        _QuickActionItem(
          icon: Icons.local_shipping, 
          label: 'Track Delivery', 
          color: activeRequest != null ? Colors.orange : Colors.grey,
          onTap: () {
            if (activeRequest != null) {
              context.push('/client/track/${activeRequest.id}');
            } else {
              context.push('/client/requests');
            }
          },
        ),
        _QuickActionItem(
          icon: Icons.support_agent, 
          label: 'Support', 
          color: Colors.green,
          onTap: () {},
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon, 
    required this.label, 
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
         decoration: BoxDecoration(
          color: AppTheme.glassBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.glassBorder)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentDeliveryCard extends StatelessWidget {
  final dynamic delivery;
  const _RecentDeliveryCard({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, hh:mm a');
    final DateTime date = DateTime.tryParse(delivery['delivery_date'] ?? '') ?? DateTime.now();
    final String status = delivery['status'] ?? 'Completed';
    final int gallons = delivery['gallons_delivered'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.glassBorder)
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.1),
            ),
            child: const Icon(Icons.check_circle, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14)),
                Text(dateFormat.format(date), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$gallons Gallons', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              if (delivery['payment_method'] == 'coupon')
                const Text('-1 Coupon', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          )
        ],
      ),
    );
  }
}

class _ClientBottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
         color: AppTheme.glassBg.withOpacity(0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded, 
                label: 'Home', 
                isActive: currentPath == '/client/home',
                onTap: () => context.go('/client/home'),
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded, 
                label: 'Orders', 
                isActive: currentPath == '/client/requests',
                onTap: () => context.go('/client/requests'),
              ),
              const SizedBox(width: 48), // Space for middle button
              _NavItem(
                icon: Icons.account_balance_wallet_rounded, 
                label: 'Wallet', 
                isActive: currentPath == '/client/buy-coupons',
                onTap: () => context.go('/client/buy-coupons'),
              ),
              _NavItem(
                icon: Icons.person_rounded, 
                label: 'Profile', 
                isActive: currentPath == '/client/profile',
                onTap: () => context.go('/client/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon, 
    required this.label, 
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label, 
              style: TextStyle(
                fontSize: 10, 
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary
              )
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;
  const _SkeletonCard({required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(32),
      ),
    );
  }
}
