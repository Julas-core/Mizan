class DecisionExplanation {
  final String verdict; // "Safe to buy", "Delay", "Avoid"
  final String primaryReason;
  final String? tinyStat;

  DecisionExplanation({
    required this.verdict,
    required this.primaryReason,
    this.tinyStat,
  });
}

class DecisionTranslator {
  static DecisionExplanation translate(Map<String, dynamic> data) {
    // 1. Parse fields robustly
    final behaviorPenalty = (data['behavior_penalty'] as num?)?.toDouble() ?? 0.0;
    final affordabilityScore = (data['affordability_score'] as num?)?.toDouble() ?? 100.0;
    
    final breakdown = data['risk_breakdown'] as Map<String, dynamic>? ?? {};
    final behaveImpact = (breakdown['behavior'] as num?)?.toDouble() ?? 0.0;
    final affordImpact = (breakdown['affordability'] as num?)?.toDouble() ?? 0.0;
    final goalImpact = (breakdown['goal_impact'] as num?)?.toDouble() ?? 0.0;
    
    final riskLevel = data['risk_level']?.toString() ?? 'Low Risk';
    final liquidityFailure = data['liquidity_failure'] == true;
    final deficitMode = data['deficit_mode'] == true;

    // 2. Compute Verdict using Dominant Factor Logic
    String verdict = "Safe to buy";
    
    if (deficitMode || liquidityFailure) {
      verdict = "Avoid";
    } else if (behaviorPenalty > 0.15 && affordabilityScore < 60) {
      verdict = "Avoid"; // High behavior risk + not incredibly affordable
    } else if (affordabilityScore < 40) {
      verdict = "Avoid";
    } else if (behaviorPenalty > 0.15) {
      verdict = "Delay"; // High behavior, but affordable - tell them to sleep on it
    } else if (goalImpact > 30 || riskLevel.contains('Moderate')) {
      verdict = "Delay";
    }

    // 3. Compute Primary Explanation using Tie-breaking (Behavior > Affordability > Goal)
    String primaryReason = "This fits comfortably within your plan.";
    String? tinyStat;

    if (deficitMode || liquidityFailure) {
      primaryReason = "This will leave you short before your next income.";
      tinyStat = "Score: ${affordabilityScore.toInt()}/100";
    } else if (behaveImpact > 0 && behaveImpact >= affordImpact && behaveImpact >= goalImpact) {
      primaryReason = "You tend to regret purchases like this.";
      // No tiny stat for behavior triggers to keep the message focused
    } else if (affordImpact > 0 && affordImpact >= goalImpact) {
      primaryReason = "This puts noticeable pressure on your cashflow.";
      tinyStat = "Score: ${affordabilityScore.toInt()}/100";
    } else if (goalImpact > 0) {
      primaryReason = "This delays your goal significantly.";
      
      // Try to extract max delay days
      final delays = data['goal_delay_days'] as Map<String, dynamic>?;
      if (delays != null && delays.isNotEmpty) {
        double maxDelay = 0;
        for (var details in delays.values) {
          if (details is Map) {
            final days = (details['delay_days'] as num?)?.toDouble() ?? 0.0;
            if (days > maxDelay) maxDelay = days;
          }
        }
        if (maxDelay > 0) {
          tinyStat = "+${maxDelay.toStringAsFixed(0)} days to goal";
        }
      }
    } else if (behaviorPenalty > 0) {
       // Catch-all for mild behavior penalty that didn't dominate the breakdown
       primaryReason = "Consider if you really need this right now.";
    }

    return DecisionExplanation(
      verdict: verdict,
      primaryReason: primaryReason,
      tinyStat: tinyStat,
    );
  }
}
