import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../repositories/api_repository.dart';

final userSummaryProvider = FutureProvider.autoDispose<UserSummary>((
  ref,
) async {
  final repository = ref.watch(apiRepositoryProvider);
  return repository.getUserSummary();
});
