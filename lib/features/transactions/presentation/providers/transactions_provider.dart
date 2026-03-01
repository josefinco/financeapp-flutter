import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/transaction.dart';
import '../../data/datasources/transactions_remote_datasource.dart';
import '../../../../core/network/dio_client.dart';

part 'transactions_provider.g.dart';

@riverpod
TransactionsRemoteDatasource transactionsDatasource(TransactionsDatasourceRef ref) {
  return TransactionsRemoteDatasource(createDio());
}

@riverpod
Future<TransactionListResponse> transactions(
  TransactionsRef ref, {
  TransactionType? type,
  int? month,
  int? year,
}) async {
  final ds = ref.watch(transactionsDatasourceProvider);
  return ds.getTransactions(
    type: type?.name,
    month: month,
    year: year,
  );
}

@riverpod
class TransactionsNotifier extends _$TransactionsNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Transaction?> createTransaction(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(transactionsDatasourceProvider);
      final tx = await ds.createTransaction(data);
      state = const AsyncData(null);
      ref.invalidate(transactionsProvider);
      return tx;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(transactionsDatasourceProvider);
      await ds.deleteTransaction(id);
      state = const AsyncData(null);
      ref.invalidate(transactionsProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
