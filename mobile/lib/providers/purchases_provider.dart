import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/purchase.dart';
import '../repositories/api_repository.dart';

final latestEvaluatedPurchaseProvider = FutureProvider.autoDispose<Purchase>((
  ref,
) async {
  final repository = ref.watch(apiRepositoryProvider);
  return repository.getLatestEvaluatedPurchase();
});

final passedPurchasesProvider = FutureProvider.autoDispose<List<Purchase>>((
  ref,
) async {
  final repository = ref.watch(apiRepositoryProvider);
  return repository.getPassedPurchases();
});
