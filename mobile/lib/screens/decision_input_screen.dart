import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/api/api_service.dart';
import 'decision_analysis_screen.dart';
import 'goals_hub_screen.dart';
import 'habits_screen.dart';
import 'home_screen.dart';
import 'purchase_reflection_screen.dart';

class DecisionInputScreen extends StatefulWidget {
  const DecisionInputScreen({super.key});

  @override
  State<DecisionInputScreen> createState() => _DecisionInputScreenState();
}

class _DecisionInputScreenState extends State<DecisionInputScreen> {
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;
  String? _currentIdempotencyKey;

  Future<void> _evaluatePurchase() async {
    final item = _itemController.text.trim();
    final priceStr = _priceController.text.trim();

    if (item.isEmpty || priceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter item name and price.')),
      );
      return;
    }

    final parsed = double.tryParse(priceStr.replaceAll(',', ''));
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid positive price.')),
      );
      return;
    }

    final priceCents = (parsed * 100).toInt();
    _currentIdempotencyKey ??= const Uuid().v4();

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.evaluatePurchase(
        itemName: item,
        priceCents: priceCents,
        category: 'General',
        idempotencyKey: _currentIdempotencyKey,
      );
      _currentIdempotencyKey = null;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DecisionAnalysisScreen(evaluationData: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Evaluation error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text('New Decision'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _itemController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Item name',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Price (USD)',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _evaluatePurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: bgDark,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Evaluate Decision'),
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
            _buildNavItem(Icons.add, 'New', true, null),
            _buildNavItem(Icons.insights, 'Insights', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const PurchaseReflectionScreen(),
                ),
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
