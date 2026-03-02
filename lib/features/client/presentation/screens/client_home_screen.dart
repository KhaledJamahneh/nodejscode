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

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: CustomScrollView(
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
                      TextButton(onPressed: () {}, child: Text(l10n.viewAllHistory)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _RecentDeliveryCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ClientBottomNavBar(),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          // backgroundImage: NetworkImage('...'), // TODO: Add user image
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
          const _Wave(),
          const _Wave(isSecond: true),
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
                        Text('${profile.remainingCoupons} Coupons', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      ],
                    ),
                     Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3))
                      ),
                      child: const Text('Premium Plan', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Water Level', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                        const Text('85%', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Est. Remaining', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                        const Text('5 Days', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontFamily: 'Roboto'),
                    children: [
                      TextSpan(text: 'Based on your usage, you will likely need a refill by '),
                      TextSpan(text: 'Thursday, Oct 24', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    ]
                  ),
                ),
                 const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.secondaryBlue.withOpacity(0.7),
                    foregroundColor: AppTheme.primaryBlue,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Schedule for Thursday'),
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

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: const [
        _QuickActionItem(icon: Icons.water_drop, label: 'Request Water', color: AppTheme.primaryBlue),
        _QuickActionItem(icon: Icons.confirmation_number, label: 'Buy Coupons', color: Colors.purple),
        _QuickActionItem(icon: Icons.local_shipping, label: 'Track Order', color: Colors.orange),
        _QuickActionItem(icon: Icons.support_agent, label: 'Support', color: Colors.green),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickActionItem({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
       decoration: BoxDecoration(
        color: AppTheme.glassBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.glassBorder)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _RecentDeliveryCard extends StatelessWidget {
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
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.1),
            ),
            child: const Icon(Icons.check_circle, color: Colors.green),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivered', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text('Oct 15, 09:30 AM', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('4 Gallons', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text('-1 Coupon', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
         color: AppTheme.glassBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.glassBorder)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _NavItem(icon: Icons.home, label: 'Home', isActive: true),
          const _NavItem(icon: Icons.calendar_month, label: 'Schedule'),
          FloatingActionButton(
            onPressed: () {},
            backgroundColor: AppTheme.primaryBlue,
            child: const Icon(Icons.add),
          ),
          const _NavItem(icon: Icons.account_balance_wallet, label: 'Wallet'),
          const _NavItem(icon: Icons.person, label: 'Profile'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _NavItem({required this.icon, required this.label, this.isActive = false});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary)),
      ],
    );
  }
}


class _Wave extends StatefulWidget {
  final bool isSecond;
  const _Wave({this.isSecond = false});
  @override
  _WaveState createState() => _WaveState();
}
class _WaveState extends State<_Wave> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: widget.isSecond ? 15 : 12),
      vsync: this,
    )..repeat();
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
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(widget.isSecond ? 0.15 : 0.2),
              borderRadius: const BorderRadius.all(Radius.circular(1000)),
            ),
          ),
        );
      },
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
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(32),
      ),
    );
  }
}
