import 'package:flutter/material.dart';

import 'create_custom_goal_screen.dart';
import 'decision_input_screen.dart';
import 'habits_screen.dart';
import 'home_screen.dart';
import 'purchase_reflection_screen.dart';

class GoalsHubScreen extends StatelessWidget {
  const GoalsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF30e8c9);
    const bgDark = Color(0xFF11211e);
    const surfaceDark = Color(0xFF1e293b);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Primary Goal',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Track and adjust your active savings goals from here.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateCustomGoalScreen(isCustomGoal: true),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: bgDark,
                ),
                child: const Text('Create / Edit Goal'),
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
            _buildNavItem(Icons.psychology, 'Habits', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HabitsScreen()),
              );
            }),
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
            _buildNavItem(Icons.track_changes, 'Goals', true, null),
          ],
        ),
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
          Icon(
            icon,
            color: isActive ? const Color(0xFF30e8c9) : Colors.white54,
            size: 24,
          ),
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
