import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:einhod_water/core/theme/app_theme.dart';
import '../services/ai_prediction_service.dart';
import 'glass_card.dart';

class SmartDeliverySuggestion extends StatelessWidget {
  final DeliveryPrediction prediction;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const SmartDeliverySuggestion({
    super.key,
    required this.prediction,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final reasoning = prediction.needMoreHistory
        ? l10n.predictionNeedHistory(prediction.avgInterval.round())
        : l10n.predictionReasoning(
            prediction.suggestedGallons,
            prediction.avgInterval.round(),
            "${prediction.suggestedDate.day}/${prediction.suggestedDate.month}/${prediction.suggestedDate.year}",
          );

    return GlassCard(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      color: AppColors.glassBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.warningAmber),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.smartSuggestion,
                style: AppTypography.titleLarge.copyWith(color: AppColors.oceanBlue),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reasoning,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.oceanBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: Text(l10n.scheduleDelivery),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton(
                onPressed: onDismiss,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(100, 44),
                ),
                child: Text(l10n.remindMe),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
