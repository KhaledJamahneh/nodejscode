import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../widgets/shared_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/location_tracking_service.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/worker_provider.dart';

final _locationTrackingProvider = StateProvider<bool>((ref) => false);

class WorkerProfileTab extends ConsumerStatefulWidget {
  const WorkerProfileTab({super.key});

  @override
  ConsumerState<WorkerProfileTab> createState() => _WorkerProfileTabState();
}

class _WorkerProfileTabState extends ConsumerState<WorkerProfileTab> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(workerProfileProvider);

    return profileAsync.when(
      data: (profile) {
        // Initialize location tracking state from profile
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentState = ref.read(_locationTrackingProvider);
          if (currentState != profile.gpsSharingEnabled) {
            ref.read(_locationTrackingProvider.notifier).state = profile.gpsSharingEnabled;
            if (profile.gpsSharingEnabled) {
              LocationTrackingService.startTracking();
            }
          }
        });

        return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ModernCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded,
                        size: 48, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.fullName,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.isOnsite ? l10n.onsiteWorker : l10n.deliveryWorker,
                    style: const TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.basicInformation,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ModernCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(Icons.badge_rounded, l10n.username,
                      profile.username),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.person_rounded, l10n.fullName,
                      profile.fullName),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.attach_money_rounded, l10n.salary,
                      '₪${profile.currentSalary}'),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.account_balance_wallet_rounded, l10n.salaryAdvance,
                      '₪${profile.debtAdvances}'),
                  if (profile.isDelivery) ...[
                    const Divider(height: 24),
                    _buildInfoRow(
                        Icons.local_shipping_rounded,
                        l10n.vehicleCapacity,
                        '${profile.vehicleCurrentGallons} ${l10n.gallons}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.settings,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ModernCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_rounded,
                        color: AppTheme.primary),
                    title: Text(l10n.newPassword),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _showChangePasswordDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator.adaptive()),
      error: (_, __) => Center(child: Text(l10n.error)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.iosGray, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.iosGray,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newPassword),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                decoration: InputDecoration(labelText: l10n.currentPassword),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                decoration: InputDecoration(labelText: l10n.newPassword),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: l10n.confirmNewPassword),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (_newPasswordController.text !=
                  _confirmPasswordController.text) {
                DialogUtils.showErrorDialog(context, l10n.passwordsDoNotMatch);
                return;
              }
              ref.read(changePasswordProvider.notifier).changePassword(
                    _currentPasswordController.text,
                    _newPasswordController.text,
                  );
              Navigator.pop(context);
              _currentPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
