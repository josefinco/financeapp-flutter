import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/budget.dart';
import '../../data/datasources/budgets_remote_datasource.dart';
import '../../../../core/network/dio_client.dart';

part 'budgets_provider.g.dart';

@riverpod
BudgetsRemoteDatasource budgetsDatasource(BudgetsDatasourceRef ref) {
  return BudgetsRemoteDatasource(createDio());
}

@riverpod
Future<List<Budget>> budgets(BudgetsRef ref, {int? month, int? year}) async {
  final ds = ref.watch(budgetsDatasourceProvider);
  return ds.getBudgets(month: month, year: year);
}

@riverpod
class BudgetsNotifier extends _$BudgetsNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Budget?> createBudget(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(budgetsDatasourceProvider);
      final budget = await ds.createBudget(data);
      state = const AsyncData(null);
      ref.invalidate(budgetsProvider);
      return budget;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> deleteBudget(String id) async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(budgetsDatasourceProvider);
      await ds.deleteBudget(id);
      state = const AsyncData(null);
      ref.invalidate(budgetsProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
