import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/api_service.dart';
import 'decision_input_screen.dart';
import 'goals_hub_screen.dart';
import 'habits_screen.dart';
import 'home_screen.dart';

class PurchaseReflectionScreen extends StatefulWidget {
  const PurchaseReflectionScreen({super.key});

  @override
  State<PurchaseReflectionScreen> createState() =>
      _PurchaseReflectionScreenState();
}

class _PurchaseReflectionScreenState extends State<PurchaseReflectionScreen> {
  int? _selectedOption; // 0 = regret, 1 = worth it
  bool _isSubmitting = false;
  bool _isLoadingPurchase = true;
  String? _error;
  Map<String, dynamic>? _latestPurchase;

  @override
  void initState() {
    super.initState();
    _loadLatestPurchase();
  }

  Future<void> _loadLatestPurchase() async {
    try {
      final purchase = await ApiService.getLatestEvaluatedPurchase();
      if (!mounted) return;
      setState(() {
        _latestPurchase = purchase;
        _isLoadingPurchase = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingPurchase = false;
      });
    }
  }

  Future<void> _submitReflection(int option) async {
    final purchaseId = _latestPurchase?['id'] as String?;
    if (purchaseId == null || purchaseId.isEmpty || _isSubmitting) {
      return;
    }

    setState(() {
      _selectedOption = option;
      _isSubmitting = true;
    });

    try {
      final regretScore = option == 0 ? 5 : 1;
      final status = option == 0 ? 'ABANDONED' : 'BOUGHT';

      await ApiService.updatePurchaseStatus(
        purchaseId: purchaseId,
        status: status,
      );
      await ApiService.submitReflection(
        purchaseId: purchaseId,
        windowDays: 7,
        regretScore: regretScore,
        feltFinancialPressure: option == 0,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reflection saved to your timeline.')),
      );
      await _loadLatestPurchase();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save reflection: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF30e8c9);
    const bgDark = Color(0xFF11211e);
    const surfaceDark = Color(0xFF1e293b);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text(
          'Purchase Reflection',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          children: [
            if (_isLoadingPurchase)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Unable to load recent purchase\n$_error',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
            else if (_latestPurchase == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No evaluated purchase found yet. Evaluate a decision first.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RECENT PURCHASE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white54,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_latestPurchase?['item_name'] ?? 'Item'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_latestPurchase?['category'] ?? 'General'} • \$${(((_latestPurchase?['price_cents'] as num?)?.toInt() ?? 0) / 100).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Illustration / Icon
            Container(
              height: 96,
              width: 96,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_alt,
                color: primaryColor,
                size: 60,
              ),
            ),

            const SizedBox(height: 32),

            // Reflection Prompt
            const Text(
              'Was this worth the money?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Reflecting on your spending helps our AI understand your unique patterns to prevent future impulse regret.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Action Options
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: (_latestPurchase == null || _isSubmitting)
                        ? null
                        : () => _submitReflection(0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _selectedOption == 0
                            ? Colors.redAccent.withValues(alpha: 0.2)
                            : surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedOption == 0
                              ? Colors.redAccent
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.sentiment_dissatisfied,
                            color: Colors.white54,
                            size: 40,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No, I regret it',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: (_latestPurchase == null || _isSubmitting)
                        ? null
                        : () => _submitReflection(1),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _selectedOption == 1
                            ? primaryColor.withValues(alpha: 0.3)
                            : primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedOption == 1
                              ? primaryColor
                              : primaryColor.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.sentiment_satisfied,
                            color: primaryColor,
                            size: 40,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Yes, worth it',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // AI Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: surfaceDark),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: primaryColor, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your feedback is anonymous and used only to calibrate your personal budget triggers and savings goals.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
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
            _buildNavItem(Icons.insights, 'Insights', true, null),
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
