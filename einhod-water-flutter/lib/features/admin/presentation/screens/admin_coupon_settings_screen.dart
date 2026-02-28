// lib/features/admin/presentation/screens/admin_coupon_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';
import '../providers/coupon_settings_provider.dart';
import '../../data/admin_service.dart';
import '../providers/admin_provider.dart';

class AdminCouponSettingsScreen extends ConsumerWidget {
  const AdminCouponSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sizesAsync = ref.watch(adminCouponSizesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.couponSettings),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCouponSizeDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.add),
      ),
      body: sizesAsync.when(
        data: (sizes) => RefreshIndicator(
          onRefresh: () => ref.refresh(adminCouponSizesProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sizes.length,
            itemBuilder: (context, index) {
              final size = sizes[index];
              return _CouponSizeCard(size: size);
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.iosRed),
              const SizedBox(height: 16),
              Text('${l10n.error}: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminCouponSizesProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateCouponSizeDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sizeController = TextEditingController();
    final totalGallonsController = TextEditingController();
    final priceController = TextEditingController();
    final bonusController = TextEditingController(text: '0');
    final expiryDaysController = TextEditingController(text: '365');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.add),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sizeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${l10n.size} (${l10n.gallons})',
                  hintText: '50',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalGallonsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${l10n.total} ${l10n.gallons}',
                  hintText: '500',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (₪)',
                  hintText: '500',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bonusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bonus Gallons',
                  hintText: '0',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expiryDaysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Expiry Days',
                  hintText: '365',
                ),
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
            onPressed: () async {
              final size = int.tryParse(sizeController.text);
              final totalGallons = int.tryParse(totalGallonsController.text);
              final price = double.tryParse(priceController.text);
              final bonus = int.tryParse(bonusController.text) ?? 0;
              final expiryDays = int.tryParse(expiryDaysController.text) ?? 365;

              if (size == null || totalGallons == null || price == null) {
                return;
              }

              try {
                await ref.read(adminServiceProvider).createCouponSize(
                  size: size,
                  totalGallons: totalGallons,
                  price: price,
                  bonusGallons: bonus,
                  expiryDays: expiryDays,
                );
                ref.invalidate(adminCouponSizesProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.success)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.error}: $e')),
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
}

class _CouponSizeCard extends ConsumerWidget {
  final Map<String, dynamic> size;

  const _CouponSizeCard({required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.style_rounded, color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${size['size']} ${l10n.gallons}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${l10n.total}: ${size['total_gallons']} ${l10n.gallons}',
                      style: const TextStyle(fontSize: 14, color: AppTheme.iosGray),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryBlue),
                onPressed: () => _showEditDialog(context, ref, size),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _InfoRow(
            label: l10n.pricePerPage,
            value: '₪${size['price_per_page']}',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: l10n.bonusGallons,
            value: '${size['bonus_gallons'] ?? 0}',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: l10n.totalPrice,
            value: '₪${size['total_price']}',
            highlight: true,
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> size) {
    final l10n = AppLocalizations.of(context)!;
    final priceCtrl = TextEditingController(text: '${size['price_per_page']}');
    final bonusCtrl = TextEditingController(text: '${size['bonus_gallons'] ?? 0}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.editPackage} ${size['size']} ${l10n.gallons}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '${l10n.pricePerPage} (₪)',
                prefixIcon: const Icon(Icons.attach_money_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bonusCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.bonusGallons,
                prefixIcon: const Icon(Icons.card_giftcard_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final price = double.tryParse(priceCtrl.text);
              final bonus = int.tryParse(bonusCtrl.text);

              if (price != null && bonus != null) {
                await ref.read(adminServiceProvider).updateCouponSize(
                  size['id'],
                  {'price_per_page': price, 'bonus_gallons': bonus},
                );
                Navigator.pop(context);
                ref.invalidate(adminCouponSizesProvider);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.iosGray,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: highlight ? AppTheme.primaryBlue : null,
          ),
        ),
      ],
    );
  }
}
