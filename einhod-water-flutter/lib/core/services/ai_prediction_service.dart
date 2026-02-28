import '../../models/models.dart';

class DeliveryPrediction {
  final DateTime suggestedDate;
  final int suggestedGallons;
  final double avgInterval;
  final double confidence;
  final bool needMoreHistory;

  DeliveryPrediction({
    required this.suggestedDate,
    required this.suggestedGallons,
    required this.avgInterval,
    required this.confidence,
    this.needMoreHistory = false,
  });
}

class AIPredictionService {
  static DeliveryPrediction predictNextDelivery(List<DeliveryModel> history) {
    if (history.isEmpty || history.length < 2) {
      return DeliveryPrediction(
        suggestedDate: DateTime.now().add(const Duration(days: 7)),
        suggestedGallons: 3,
        avgInterval: 7.0,
        confidence: 0.3,
        needMoreHistory: true,
      );
    }

    // Sort history by date (newest first)
    final sortedHistory = List<DeliveryModel>.from(history)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Calculate intervals and average gallons
    List<int> intervals = [];
    int totalGallons = 0;

    for (int i = 0; i < sortedHistory.length - 1; i++) {
      final diff = sortedHistory[i].date.difference(sortedHistory[i + 1].date).inDays;
      if (diff > 0) intervals.add(diff);
      totalGallons += sortedHistory[i].gallons;
    }
    // Add the oldest delivery's gallons
    totalGallons += sortedHistory.last.gallons;

    final double avgInterval = intervals.isEmpty 
        ? 7.0 
        : intervals.reduce((a, b) => a + b) / intervals.length;
    
    final int avgGallons = (totalGallons / sortedHistory.length).round();

    // Prediction
    final lastDeliveryDate = sortedHistory.first.date;
    final suggestedDate = lastDeliveryDate.add(Duration(days: avgInterval.round()));
    
    // Confidence calculation (simplified)
    double confidence = 0.5;
    if (history.length > 5) confidence += 0.2;
    if (intervals.every((element) => (element - avgInterval).abs() < 2)) confidence += 0.2;

    return DeliveryPrediction(
      suggestedDate: suggestedDate,
      suggestedGallons: avgGallons,
      avgInterval: avgInterval,
      confidence: confidence.clamp(0.0, 1.0),
      needMoreHistory: false,
    );
  }
}
