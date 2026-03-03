import 'package:flutter/material.dart';

class DecisionAnalysisScreen extends StatelessWidget {
  final Map<String, dynamic> evaluationData;

  const DecisionAnalysisScreen({super.key, required this.evaluationData});

  @override
  Widget build(BuildContext context) {
    final score = evaluationData['affordability_score'] ?? 0;
    final riskLevel = evaluationData['risk_level'] ?? 'Unknown';
    final aiInsight = evaluationData['ai_insight'] ?? 'No insight available.';
    final daysImpacted = (evaluationData['days_impacted'] ?? evaluationData['days_impacted_predicted'] ?? 0).toDouble();
    
    // Determine color based on risk level
    Color statusColor = const Color(0xFF30e8c9); // Primary teal
    String statusTitle = 'Highly Affordable';
    String statusSubtitle = 'This purchase fits comfortably within your remaining monthly budget and savings plan.';
    double scorePercentage = score / 100.0;
    
    if (riskLevel.contains('Moderate')) {
      statusColor = Colors.orangeAccent;
      statusTitle = 'Moderate Impact';
      statusSubtitle = 'This requires a minor adjustment to your savings rate.';
    } else if (riskLevel.contains('High')) {
      statusColor = Colors.deepOrangeAccent;
      statusTitle = 'High Risk';
      statusSubtitle = 'This purchase will significantly delay your goals.';
    } else if (riskLevel.contains('Severe')) {
      statusColor = Colors.redAccent;
      statusTitle = 'Severe Risk';
      statusSubtitle = 'Warning: This will cause immediate financial pressure.';
    }

    const brandPrimary = Color(0xFF30e8c9);
    const bgDark = Color(0xFF11211e);
    const surfaceDark = Color(0xFF1e293b); // Slate 800

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text('Decision Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section - Score
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              decoration: BoxDecoration(
                color: surfaceDark.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                   SizedBox(
                     height: 180,
                     width: 180,
                     child: Stack(
                       fit: StackFit.expand,
                       children: [
                         CircularProgressIndicator(
                           value: scorePercentage,
                           strokeWidth: 12,
                           color: statusColor,
                           backgroundColor: const Color(0xFF334155), // Slate 700
                           strokeCap: StrokeCap.round,
                         ),
                         Center(
                           child: Column(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Text(
                                 '$score',
                                 style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white),
                               ),
                               const Text(
                                 'SCORE',
                                 style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white54, letterSpacing: 2),
                               ),
                             ],
                           ),
                         )
                       ],
                     ),
                   ),
                   const SizedBox(height: 24),
                   Text(
                     statusTitle,
                     style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                   ),
                   const SizedBox(height: 8),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 24),
                     child: Text(
                       statusSubtitle,
                       textAlign: TextAlign.center,
                       style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                     ),
                   ),
                ],
              ),
            ),
            
            // Details Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // AI Advice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: brandPrimary.withOpacity(0.1),
                      border: Border.all(color: brandPrimary.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.smart_toy, color: brandPrimary, size: 20),
                            SizedBox(width: 8),
                            Text('AI INSIGHT', style: TextStyle(color: brandPrimary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '"$aiInsight"',
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Metrics
                  _MetricCard(
                    icon: Icons.hourglass_empty,
                    iconColor: Colors.orangeAccent,
                    iconBgColor: Colors.orange.withOpacity(0.2),
                    title: 'DELAY IMPACT',
                    description: 'Delays your goals by ',
                    boldDescription: '${daysImpacted.toStringAsFixed(1)} days',
                  ),
                  const SizedBox(height: 12),
                  _MetricCard(
                    icon: Icons.movie_outlined,
                    iconColor: Colors.blueAccent,
                    iconBgColor: Colors.blue.withOpacity(0.2),
                    title: 'OPPORTUNITY COST',
                    description: 'Equivalent to ',
                    boldDescription: '${(priceCents(evaluationData) / 1200).ceil()} movie nights', // rough estimate
                  ),
                  const SizedBox(height: 12),
                  _MetricCard(
                    icon: Icons.speed,
                    iconColor: Colors.redAccent,
                    iconBgColor: Colors.red.withOpacity(0.2),
                    title: 'FINANCIAL PRESSURE',
                    description: 'Reduces safe weekly spending',
                    boldDescription: '', // Simplified for UI
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // helper to safely extract price for mock calculation if present, else default
  int priceCents(Map<String,dynamic> data) {
      if(data['affordability_score'] != null) {
          // just a mock proxy mapping 
          if(data['affordability_score'] < 20) return 250000;
          if(data['affordability_score'] < 60) return 60000;
      }
      return 15000;
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String description;
  final String boldDescription;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.description,
    required this.boldDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        border: Border.all(color: const Color(0xFF334155)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Roboto'),
                    children: [
                      TextSpan(text: description),
                      TextSpan(text: boldDescription, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
