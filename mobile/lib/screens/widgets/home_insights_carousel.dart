import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/insights_provider.dart';

class HomeInsightsCarousel extends ConsumerStatefulWidget {
  const HomeInsightsCarousel({super.key});

  @override
  ConsumerState<HomeInsightsCarousel> createState() => _HomeInsightsCarouselState();
}

class _HomeInsightsCarouselState extends ConsumerState<HomeInsightsCarousel> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() => _currentIndex++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insightsAsync = ref.watch(insightsProvider);

    return insightsAsync.when(
      data: (insight) {
        // Collect insights to show
        List<String> messages = [];
        
        // Priority 1: High Regret Target
        if (insight.highRegretRatePercent > 30) {
          messages.add("You've frequently regretted ${insight.topRegretCategory} purchases lately.");
        }
        
        // Priority 2: Impulse Window
        if (insight.fridayOverspendPercent > 0) {
          messages.add("Watch out during ${insight.impulseWindow}: you tend to spend ${insight.fridayOverspendPercent}% more.");
        }
        
        // Priority 3: General Trend (Fallback)
        if (messages.isEmpty) {
          messages.add("Recent behavior: ${insight.mainBehaviorTrend}");
        }

        // Cap at 2 insights max for the home screen rotating card
        final displayMessages = messages.take(2).toList();
        
        if (displayMessages.isEmpty) return const SizedBox.shrink();

        final currentMessage = displayMessages[_currentIndex % displayMessages.length];

        return AnimatedSwitcher(
          duration: const Duration(seconds: 1),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: Container(
            key: ValueKey(currentMessage),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.orangeAccent, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    currentMessage,
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
