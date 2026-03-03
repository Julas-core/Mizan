import 'package:flutter/material.dart';
import 'decision_input_screen.dart';
import 'goals_hub_screen.dart';
import 'home_screen.dart';
import 'purchase_reflection_screen.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF30e8c9);
    const bgDark = Color(0xFF11211e);
    const surfaceDark = Color(0xFF1e293b);

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Your Money Habits',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Insight Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MAIN BEHAVIORAL TREND', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                          const Text('Friday Night Impulses', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          const Text.rich(
                            TextSpan(
                              text: 'You spend ',
                              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                              children: [
                                TextSpan(text: '40% more', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                TextSpan(text: ' on non-essentials between 8 PM and midnight on Fridays compared to any other time.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: bgDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Set a Friday Reminder', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Text('Lifestyle Patterns', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    // Regret Alert Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surfaceDark.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: surfaceDark),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.shopping_bag, color: Colors.orangeAccent),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Clothing Regret Alert', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text.rich(
                                      TextSpan(
                                        text: 'Based on your return history, you tend to regret ',
                                        style: TextStyle(color: Colors.white54, fontSize: 14),
                                        children: [
                                          TextSpan(text: '60%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                                          TextSpan(text: ' of clothing purchases over \$100.'),
                                        ]
                                      )
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                backgroundColor: primaryColor.withOpacity(0.1),
                                foregroundColor: primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('View Shopping Tips', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Coffee Impact Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surfaceDark.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: surfaceDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.coffee, color: Colors.lightBlue),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Recurring Coffee Impact', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text.rich(
                                      TextSpan(
                                        text: 'Your daily \$5.50 espresso habit adds up to ',
                                        style: TextStyle(color: Colors.white54, fontSize: 14),
                                        children: [
                                          TextSpan(text: '\$165/mo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                                          TextSpan(text: '. That\'s a weekend getaway every 3 months.'),
                                        ]
                                      )
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    backgroundColor: surfaceDark,
                                    foregroundColor: Colors.white70,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Set a limit', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: bgDark,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Switch to Brew', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Insights Scroll (Horizontal)
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        children: [
                          _buildInsightPill(Icons.auto_awesome, Colors.teal, Colors.teal.withOpacity(0.2), 'SUPERPOWER', 'Never late on utilities'),
                          const SizedBox(width: 16),
                          _buildInsightPill(Icons.history_edu, Colors.amber, Colors.amber.withOpacity(0.2), 'SUBSCRIPTION', '3 unused services'),
                          const SizedBox(width: 16),
                          _buildInsightPill(Icons.sentiment_satisfied, Colors.purpleAccent, Colors.purpleAccent.withOpacity(0.2), 'MOOD SPEND', 'Higher when bored'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Analysis Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Behavioral Score', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('84/100', style: TextStyle(color: bgDark, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: 0.84,
                            backgroundColor: surfaceDark,
                            color: primaryColor,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '"You\'re in the top 12% of mindful spenders this month."',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                          )
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 12, bottom: 24, left: 24, right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0f172a),
          border: Border(top: BorderSide(color: primaryColor.withValues(alpha: 0.1))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.home, 'Home', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }),
            _buildNavItem(Icons.psychology, 'Habits', true, null),
            _buildNavItem(Icons.add, 'New', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DecisionInputScreen()),
              );
            }),
            _buildNavItem(Icons.insights, 'Insights', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PurchaseReflectionScreen()),
              );
            }),
            _buildNavItem(Icons.track_changes, 'Goals', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const GoalsHubScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightPill(IconData icon, Color iconColor, Color bgColor, String title, String subtitle) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const Spacer(),
          Text(title, style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? const Color(0xFF30e8c9) : Colors.white54, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF30e8c9) : Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
