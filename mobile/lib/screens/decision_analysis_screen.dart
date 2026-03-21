import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/decision_translator.dart';
import '../repositories/api_repository.dart';

class DecisionAnalysisScreen extends ConsumerWidget {
  final Map<String, dynamic> evaluationData;

  const DecisionAnalysisScreen({super.key, required this.evaluationData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Translate the backend evaluation into human terms
    final explanation = DecisionTranslator.translate(evaluationData);
    final behaviorPenalty = (evaluationData['behavior_penalty'] as num?)?.toDouble() ?? 0.0;
    
    // Action Handlers
    void handleDecision(String finalStatus) async {
       final purchaseId = evaluationData['purchase_id'] ?? evaluationData['id'];
       if (purchaseId != null) {
         try {
           await ref.read(apiRepositoryProvider).updatePurchaseStatus(
             purchaseId: purchaseId,
             status: finalStatus,
           );
         } catch (e) {
           debugPrint('Failed to log action: $e');
         }
       }
       if (context.mounted) Navigator.pop(context);
    }
    
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                    if (explanation.tinyStat != null && explanation.tinyStat!.isNotEmpty)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    if (behaviorPenalty > 0.1 && !explanation.primaryReason.contains("regret"))
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.psychology, color: Colors.orangeAccent),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "You've shown regret for similar purchases in the past.",
                                style: TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Spacer(flex: 2),

                    // --- ACTIONS ---
                    ElevatedButton(
                      onPressed: () => handleDecision(primaryStatusAction),
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
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextButton(
                      onPressed: () => handleDecision(secondaryStatusAction),
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
