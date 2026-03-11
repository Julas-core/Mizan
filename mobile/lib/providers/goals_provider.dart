import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal.dart';
import '../repositories/api_repository.dart';

final goalsProvider = FutureProvider.autoDispose<List<Goal>>((ref) async {
  final repository = ref.watch(apiRepositoryProvider);
  return repository.getGoals();
});
