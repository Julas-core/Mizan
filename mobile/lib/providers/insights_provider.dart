import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/insight.dart';
import '../repositories/api_repository.dart';

final insightsProvider = FutureProvider.autoDispose<Insight>((ref) async {
  final repository = ref.watch(apiRepositoryProvider);
  return repository.getHabitsInsights();
});
