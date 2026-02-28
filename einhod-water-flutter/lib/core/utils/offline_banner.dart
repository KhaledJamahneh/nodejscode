//
// FIX #9 — Renamed from `OfflineBanner` to `CoreOfflineBanner` to resolve the
// name collision with the `OfflineBanner` widget in lib/widgets/shared_widgets.dart.
// Any callers that imported this file must update their usage accordingly.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CoreOfflineBanner extends StatelessWidget {
  final bool isOffline;

  const CoreOfflineBanner({super.key, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Material(
      child: Container(
        width: double.infinity,
        color: AppTheme.criticalRed,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_wifi_off_rounded, color: Colors.white, size: 16),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'Offline — Changes will sync when connected',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
