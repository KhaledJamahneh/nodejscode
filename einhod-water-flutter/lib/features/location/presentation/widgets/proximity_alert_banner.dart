// lib/features/location/presentation/widgets/proximity_alert_banner.dart
import 'package:flutter/material.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/location_provider.dart';

/// Animated proximity alert banner.
/// Shows different visual intensity depending on [ProximityLevel].
class ProximityAlertBanner extends StatefulWidget {
  final ProximityState state;
  final VoidCallback? onDismiss;

  const ProximityAlertBanner({
    super.key,
    required this.state,
    this.onDismiss,
  });

  @override
  State<ProximityAlertBanner> createState() => _ProximityAlertBannerState();
}

class _ProximityAlertBannerState extends State<ProximityAlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ps = widget.state;
    if (!ps.isMonitoring || !ps.isNear || ps.distanceMeters == null) {
      return const SizedBox.shrink();
    }

    final config = _BannerConfig.from(ps.level);
    final distLabel = LocationService.formatDistance(ps.distanceMeters!);
    final etaMin = LocationService.estimatedMinutes(ps.distanceMeters!);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, child) => Transform.scale(
        scale: ps.isVeryClose ? _pulseAnimation.value : 1.0,
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: config.gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: config.accentColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Decorative circle
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Animated icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(config.icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ps.isVeryClose
                                ? 'Your delivery is only $distLabel away!'
                                : 'Your delivery is $distLabel away — ETA ~$etaMin min',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (ps.workerSnapshot?.workerName != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person_rounded,
                                    size: 13, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  ps.workerSnapshot!.workerName!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.onDismiss != null)
                      IconButton(
                        onPressed: widget.onDismiss,
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white70),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerConfig {
  final List<Color> gradientColors;
  final Color accentColor;
  final IconData icon;
  final String title;

  const _BannerConfig({
    required this.gradientColors,
    required this.accentColor,
    required this.icon,
    required this.title,
  });

  factory _BannerConfig.from(ProximityLevel level) {
    switch (level) {
      case ProximityLevel.veryClose:
        return _BannerConfig(
          gradientColors: [const Color(0xFFE53935), const Color(0xFFFF6F60)],
          accentColor: const Color(0xFFE53935),
          icon: Icons.directions_run_rounded,
          title: '🚰 Delivery Arriving Now!',
        );
      case ProximityLevel.near:
        return _BannerConfig(
          gradientColors: [AppTheme.primaryBlue, AppTheme.accentSkyBlue],
          accentColor: AppTheme.primaryBlue,
          icon: Icons.local_shipping_rounded,
          title: '🚚 Delivery Worker Nearby',
        );
      default:
        return _BannerConfig(
          gradientColors: [AppTheme.primaryBlue, AppTheme.accentSkyBlue],
          accentColor: AppTheme.primaryBlue,
          icon: Icons.local_shipping_rounded,
          title: '🚚 Delivery On The Way',
        );
    }
  }
}

// ─── Compact notification tile for Notifications tab ─────────────────────────

class ProximityNotificationTile extends StatelessWidget {
  final ProximityState state;

  const ProximityNotificationTile({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (!state.isNear || state.distanceMeters == null)
      return const SizedBox.shrink();

    final dist = LocationService.formatDistance(state.distanceMeters!);
    final eta = LocationService.estimatedMinutes(state.distanceMeters!);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_shipping_rounded,
                        color: AppTheme.primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Worker Nearby',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dist away · ETA ~$eta min',
                        style: const TextStyle(
                            color: AppTheme.iosGray, fontSize: 13),
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
}
