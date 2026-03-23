import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/api_repository.dart';

final decisionStyleProvider = FutureProvider.autoDispose<String>((ref) async {
  final repository = ref.watch(apiRepositoryProvider);

  try {
    final summary = await repository.getDecisionQuality(
      lookbackDays: 30,
      minSample: 5,
    );
    final breakdown =
        (summary['breakdown_by_factor'] as List<dynamic>? ?? const []);

    for (final item in breakdown) {
      if (item is Map<String, dynamic>) {
        final key = (item['key'] ?? '').toString().toLowerCase();
        final overrideRate = (item['override_rate'] as num?)?.toDouble() ?? 0.0;
        final confidence = (item['confidence'] ?? '').toString().toLowerCase();

        if (key == 'behavior' &&
            overrideRate >= 50.0 &&
            confidence == 'stable') {
          return 'concrete';
        }
      }
    }
  } catch (_) {
    // Fall back to concise mode when analytics is unavailable.
  }

  return 'concise';
});
