import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/goal_update_tracker.dart';

import 'create_custom_goal_screen.dart';
import 'decision_input_screen.dart';
import 'habits_screen.dart';
import 'home_screen.dart';
import 'purchase_reflection_screen.dart';

class GoalsHubScreen extends StatefulWidget {
  const GoalsHubScreen({super.key});

  @override
  State<GoalsHubScreen> createState() => _GoalsHubScreenState();
}

class _GoalsHubScreenState extends State<GoalsHubScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _goals = const [];
  PendingGoalUpdate? _pendingGoalUpdate;
  Timer? _pollTimer;
  bool _isPollingPendingUpdate = false;

  @override
  void initState() {
    super.initState();
    _initializeGoalsHub();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeGoalsHub() async {
    final pendingUpdate = await GoalUpdateTracker.getPendingUpdate();
    if (!mounted) {
      return;
    }

    setState(() {
      _pendingGoalUpdate = pendingUpdate;
    });

    await _loadGoals();
    _updatePendingGoalState();
  }

  void _startPendingPoller() {
    if (_pendingGoalUpdate == null || _pollTimer != null) {
      return;
    }

    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_isPollingPendingUpdate || _pendingGoalUpdate == null) {
        return;
      }
      _isPollingPendingUpdate = true;
      await _loadGoals(silent: true);
      _updatePendingGoalState();
      _isPollingPendingUpdate = false;
    });
  }

  void _stopPendingPoller() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _updatePendingGoalState() async {
    final pending = _pendingGoalUpdate;
    if (pending == null) {
      _stopPendingPoller();
      return;
    }

    Map<String, dynamic>? matchingGoal;
    for (final goal in _goals) {
      if (goal['id'] == pending.goalId) {
        matchingGoal = goal;
        break;
      }
    }

    final currentTargetCents =
        (matchingGoal?['target_amount_cents'] as num?)?.toInt();
    final completed =
        currentTargetCents != null && currentTargetCents <= pending.expectedTargetCents;

    if (completed) {
      await GoalUpdateTracker.clearPendingUpdate();
      _stopPendingPoller();
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingGoalUpdate = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pending.goalName} was updated successfully.'),
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {});
    }
    _startPendingPoller();
  }

  Future<void> _loadGoals({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final goals = await ApiService.getGoals();
      if (!mounted) return;
      setState(() {
        _goals = goals;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF30e8c9);
    const bgDark = Color(0xFF11211e);
    const surfaceDark = Color(0xFF1e293b);
    final pending = _pendingGoalUpdate;

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
            if (pending != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Goal update in progress',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Applying \$${(pending.purchaseAmountCents / 100).toStringAsFixed(2)} to ${pending.goalName}. This usually completes within a few seconds.',
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Expected remaining target: \$${(pending.expectedTargetCents / 100).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : () async {
                        await _loadGoals();
                        await _updatePendingGoalState();
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Text(
                        'Unable to load goals\n$_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    )
                  : _goals.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Text(
                        'No goals saved yet. Create your first goal to start tracking it here.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _goals.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        final cents =
                            (goal['target_amount_cents'] as num?)?.toInt() ?? 0;
                        final amount = (cents / 100).toStringAsFixed(2);
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: pending?.goalId == goal['id']
                                  ? primaryColor.withValues(alpha: 0.7)
                                  : primaryColor.withValues(alpha: 0.15),
                              width: pending?.goalId == goal['id'] ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${goal['name'] ?? 'Goal'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Target: \$$amount',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Priority: ${goal['priority'] ?? '-'}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              if (pending?.goalId == goal['id']) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Pending background update…',
                                  style: TextStyle(
                                    color: Color(0xFF30e8c9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
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
                      builder: (_) =>
                          const CreateCustomGoalScreen(isCustomGoal: true),
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
        padding: const EdgeInsets.only(
          top: 12,
          bottom: 24,
          left: 24,
          right: 24,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0f172a),
          border: Border(
            top: BorderSide(color: primaryColor.withValues(alpha: 0.1)),
          ),
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
                MaterialPageRoute(
                  builder: (_) => const PurchaseReflectionScreen(),
                ),
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
