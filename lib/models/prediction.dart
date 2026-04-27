class PredictionResult {
  final double winProbability;
  final String predictionId;

  PredictionResult({
    required this.winProbability,
    required this.predictionId,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      winProbability: json['win_probability'].toDouble(),
      predictionId: json['prediction_id'] ?? '',
    );
  }
}

class PredictionInput {
  final double totalRuns;
  final int wicketsFallen;
  final int ballsBowled;
  final double targetRuns;

  PredictionInput({
    required this.totalRuns,
    required this.wicketsFallen,
    required this.ballsBowled,
    required this.targetRuns,
  });

  Map<String, dynamic> toJson() => {
        'total_runs': totalRuns,
        'wickets_fallen': wicketsFallen,
        'balls_bowled': ballsBowled,
        'target_runs': targetRuns,
      };
}
