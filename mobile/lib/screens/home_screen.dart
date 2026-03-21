import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/api/api_service.dart';
import 'decision_analysis_screen.dart';
import 'goals_hub_screen.dart';
import 'purchase_reflection_screen.dart';
import 'habits_screen.dart';
import 'widgets/home_insights_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;
  String? _currentIdempotencyKey;
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _aiStatus;
  bool _isSummaryLoading = true;
  bool _isAiStatusLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadAiStatus();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await ApiService.getUserSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isSummaryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSummaryLoading = false;
      });
      debugPrint('Error loading summary: $e');
    }
  }

  Future<void> _loadAiStatus() async {
    try {
      final status = await ApiService.getAiStatus();
      if (!mounted) return;
      setState(() {
        _aiStatus = status;
        _isAiStatusLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAiStatusLoading = false;
      });
    }
  }

  void _evaluatePurchase() async {
    final item = _itemController.text;
    final priceStr = _priceController.text;

    if (item.isEmpty || priceStr.isEmpty) return;

    final priceCents = (double.parse(priceStr) * 100).toInt();

    _currentIdempotencyKey ??= const Uuid().v4();

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.evaluatePurchase(
        itemName: _itemController.text,
        priceCents: priceCents,
        category: 'General',
        idempotencyKey: _currentIdempotencyKey,
      );

      if (!mounted) return;

      _currentIdempotencyKey = null; // Clear on success

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
      ).showSnackBar(SnackBar(content: Text('Evaluation Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF30e8c9);

    return Scaffold(
      backgroundColor: const Color(0xFF11211e),
      appBar: AppBar(
        title: const Text(
          'Home: Decision Hub',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_circle,
              color: primaryColor,
              size: 24,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Evaluation trigger card mimicking the design
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1e293b), // slate-800
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Empowering your choices',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Need a quick reflection before checking out?',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _itemController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Item Name (e.g. Headphones)',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Price (\$)',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _evaluatePurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: const Color(0xFF11211e),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Color(0xFF11211e),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Evaluate Decision',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            
            // --- PASSIVE INSIGHTS CAROUSEL ---
            const HomeInsightsCarousel(),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy, color: primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _isAiStatusLoading
                        ? 'Gemini: checking...'
                        : ((_aiStatus?['gemini_configured'] == true)
                              ? 'Gemini: configured (${_aiStatus?['model'] ?? 'unknown model'})'
                              : 'Gemini: not configured on backend'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Mock metrics row from the design
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1e293b),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.1),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white54,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'NEXT INCOME',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isSummaryLoading
                              ? '...'
                              : '${_summary?['days_to_next_income'] ?? '0'} days',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1e293b),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.1),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.verified_user,
                              color: primaryColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SAFE-TO-SPEND',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isSummaryLoading
                              ? '...'
                              : '\$${((_summary?['safe_to_spend_cents'] ?? 0) / 100).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
          color: const Color(0xFF0f172a), // Very dark slate
          border: Border(
            top: BorderSide(color: primaryColor.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.home, 'Home', true, null),
            _buildNavItem(Icons.psychology, 'Habits', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HabitsScreen()),
              );
            }),
            _buildNavItem(Icons.add, 'New', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DecisionInputScreen(),
                ),
              );
            }),
            _buildNavItem(Icons.insights, 'Insights', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const PurchaseReflectionScreen(),
                ),
              );
            }),
            _buildNavItem(Icons.track_changes, 'Goals', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const GoalsHubScreen()),
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
