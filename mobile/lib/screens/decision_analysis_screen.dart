import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/decision_style_provider.dart';
import '../utils/decision_translator.dart';
import '../repositories/api_repository.dart';

class DecisionAnalysisScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> evaluationData;

  const DecisionAnalysisScreen({super.key, required this.evaluationData});

  @override
  ConsumerState<DecisionAnalysisScreen> createState() =>
      _DecisionAnalysisScreenState();
}

class _DecisionAnalysisScreenState
    extends ConsumerState<DecisionAnalysisScreen> {
  bool _didEmitShownEvent = false;

  bool _isOverrideForAction({
    required String finalStatus,
    required String recommendedAction,
  }) {
    final normalizedStatus = finalStatus.toUpperCase();
    final normalizedRecommendation = recommendedAction.toLowerCase();

    if (normalizedRecommendation == 'buy') {
      return normalizedStatus != 'BOUGHT';
    }

    // Delay and avoid both mean "do not buy now" from an outcome perspective.
    if (normalizedRecommendation == 'delay' ||
        normalizedRecommendation == 'avoid') {
      return normalizedStatus != 'ABANDONED';
    }

    return false;
  }

  String _buildAmountBand(int priceCents) {
    final dollars = priceCents / 100.0;
    if (dollars <= 25) return '<=25';
    if (dollars <= 100) return '26-100';
    if (dollars <= 500) return '101-500';
    return '500+';
  }

  Future<void> _emitVerdictShown(DecisionExplanation explanation) async {
    if (_didEmitShownEvent) return;
    _didEmitShownEvent = true;

    final purchaseId =
        widget.evaluationData['purchase_id'] ?? widget.evaluationData['id'];
    final priceCents =
        (widget.evaluationData['price_cents'] as num?)?.toInt() ?? 0;
    final category = widget.evaluationData['category']?.toString();
    final riskLevel = widget.evaluationData['risk_level']?.toString();

    try {
      await ref
          .read(apiRepositoryProvider)
          .postDecisionEvent(
            eventType: 'verdict_shown',
            purchaseId: purchaseId?.toString(),
            verdict: explanation.verdict,
            dominantFactor: explanation.dominantFactor,
            riskLevel: riskLevel,
            category: category,
            amountBand: _buildAmountBand(priceCents),
            recommendedAction: explanation.recommendedAction,
            metadataJson: {'screen': 'decision_analysis'},
          );
    } catch (e) {
      debugPrint('Failed to log verdict_shown event: $e');
    }
  }

  Future<void> _emitActionAndFeedback({
    required String finalStatus,
    required DecisionExplanation explanation,
    required bool overrodeRecommendation,
  }) async {
    final purchaseId =
        widget.evaluationData['purchase_id'] ?? widget.evaluationData['id'];
    final riskLevel = widget.evaluationData['risk_level']?.toString();
    final category = widget.evaluationData['category']?.toString();
    final priceCents =
        (widget.evaluationData['price_cents'] as num?)?.toInt() ?? 0;

    if (purchaseId != null) {
      try {
        await ref
            .read(apiRepositoryProvider)
            .postDecisionEvent(
              eventType: 'action_selected',
              purchaseId: purchaseId.toString(),
              verdict: explanation.verdict,
              dominantFactor: explanation.dominantFactor,
              riskLevel: riskLevel,
              category: category,
              amountBand: _buildAmountBand(priceCents),
              recommendedAction: explanation.recommendedAction,
              userAction: finalStatus.toLowerCase(),
              overrodeRecommendation: overrodeRecommendation,
              metadataJson: {'screen': 'decision_analysis'},
            );
      } catch (e) {
        debugPrint('Failed to log action_selected event: $e');
      }
    }

    if (!mounted) return;

    final helpful = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1e293b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Was this recommendation helpful?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  child: const Text('Helpful'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(sheetContext, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF475569)),
                  ),
                  child: const Text('Not helpful'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (purchaseId != null && helpful != null) {
      try {
        await ref
            .read(apiRepositoryProvider)
            .postDecisionEvent(
              eventType: 'feedback_submitted',
              purchaseId: purchaseId.toString(),
              verdict: explanation.verdict,
              dominantFactor: explanation.dominantFactor,
              riskLevel: riskLevel,
              category: category,
              amountBand: _buildAmountBand(priceCents),
              recommendedAction: explanation.recommendedAction,
              feedbackHelpful: helpful,
              metadataJson: {'screen': 'decision_analysis'},
            );
      } catch (e) {
        debugPrint('Failed to log feedback_submitted event: $e');
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final explanationStyle = ref
        .watch(decisionStyleProvider)
        .maybeWhen(data: (value) => value, orElse: () => 'concise');

    // 1. Translate the backend evaluation into human terms
    final explanation = DecisionTranslator.translate(
      widget.evaluationData,
      explanationStyle: explanationStyle,
    );
    final behaviorPenalty =
        (widget.evaluationData['behavior_penalty'] as num?)?.toDouble() ?? 0.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emitVerdictShown(explanation);
    });

    final isSafeToBuy = explanation.verdict == "Safe to buy";
    final primaryLabel = isSafeToBuy ? "Buy item" : "Accept recommendation";
    final secondaryLabel = isSafeToBuy ? "Changed my mind" : "Proceed anyway";

    final primaryStatusAction = isSafeToBuy ? "BOUGHT" : "ABANDONED";
    final secondaryStatusAction = isSafeToBuy ? "ABANDONED" : "BOUGHT";

    // 2. Determine Styling based on Verdict
    Color verdictColor = const Color(0xFF30e8c9); // Safe to buy
    IconData verdictIcon = Icons.check_circle_outline;

    if (explanation.verdict == "Delay") {
      verdictColor = Colors.orangeAccent;
      verdictIcon = Icons.schedule;
    } else if (explanation.verdict == "Avoid") {
      verdictColor = Colors.redAccent;
      verdictIcon = Icons.warning_amber_rounded;
    }

    const brandPrimary = Color(0xFF30e8c9);
    const bgDark = Color(0xFF11211e);
    const surfaceDark = Color(0xFF1e293b);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 1),

                    // --- 1. THE VERDICT ---
                    Center(
                      child: Column(
                        children: [
                          Icon(verdictIcon, size: 80, color: verdictColor),
                          const SizedBox(height: 24),
                          Text(
                            explanation.verdict,
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: verdictColor,
                              letterSpacing: -1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // --- 2. PRIMARY EXPLANATION ---
                    Text(
                      explanation.primaryReason,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // --- 3. TINY STAT (Optional) ---
                    if (explanation.tinyStat != null &&
                        explanation.tinyStat!.isNotEmpty)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: surfaceDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Text(
                            explanation.tinyStat!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // --- 4. BEHAVIOR AWARENESS BANNER (Strict Rule: Only if triggered) ---
                    if (behaviorPenalty > 0.1 &&
                        !explanation.primaryReason.contains("regret"))
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.psychology, color: Colors.orangeAccent),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "You've shown regret for similar purchases in the past.",
                                style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Spacer(flex: 2),

                    // --- ACTIONS ---
                    ElevatedButton(
                      onPressed: () async {
                        final purchaseId =
                            widget.evaluationData['purchase_id'] ??
                            widget.evaluationData['id'];
                        if (purchaseId != null) {
                          try {
                            await ref
                                .read(apiRepositoryProvider)
                                .updatePurchaseStatus(
                                  purchaseId: purchaseId.toString(),
                                  status: primaryStatusAction,
                                );
                          } catch (e) {
                            debugPrint('Failed to update purchase status: $e');
                          }
                        }

                        final isOverride = _isOverrideForAction(
                          finalStatus: primaryStatusAction,
                          recommendedAction: explanation.recommendedAction,
                        );
                        await _emitActionAndFeedback(
                          finalStatus: primaryStatusAction,
                          explanation: explanation,
                          overrodeRecommendation: isOverride,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandPrimary,
                        foregroundColor: bgDark,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        primaryLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () async {
                        final purchaseId =
                            widget.evaluationData['purchase_id'] ??
                            widget.evaluationData['id'];
                        if (purchaseId != null) {
                          try {
                            await ref
                                .read(apiRepositoryProvider)
                                .updatePurchaseStatus(
                                  purchaseId: purchaseId.toString(),
                                  status: secondaryStatusAction,
                                );
                          } catch (e) {
                            debugPrint('Failed to update purchase status: $e');
                          }
                        }

                        final isOverride = _isOverrideForAction(
                          finalStatus: secondaryStatusAction,
                          recommendedAction: explanation.recommendedAction,
                        );
                        await _emitActionAndFeedback(
                          finalStatus: secondaryStatusAction,
                          explanation: explanation,
                          overrodeRecommendation: isOverride,
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(
                        secondaryLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
