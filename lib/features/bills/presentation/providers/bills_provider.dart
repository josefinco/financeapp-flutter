import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/bill.dart';
import '../../data/datasources/bills_remote_datasource.dart';
import '../../../../core/network/dio_client.dart';
import '../../../reports/presentation/providers/reports_provider.dart';
import '../../../wallets/presentation/providers/wallets_provider.dart';

part 'bills_provider.g.dart';

// ─── Datasource provider ──────────────────────────────────────────────────────

@riverpod
BillsRemoteDatasource billsDatasource(BillsDatasourceRef ref) {
  return BillsRemoteDatasource(createDio());
}

// ─── Bills list ───────────────────────────────────────────────────────────────

@riverpod
Future<BillListResponse> bills(
  BillsRef ref, {
  BillStatus? status,
  int? month,
  int? year,
  String? categoryId,
}) async {
  final ds = ref.watch(billsDatasourceProvider);
  return ds.getBills(
    status: status?.name,
    month: month,
    year: year,
    categoryId: categoryId,
  );
}

// ─── Upcoming bills ───────────────────────────────────────────────────────────

@riverpod
Future<List<Bill>> upcomingBills(UpcomingBillsRef ref, {int days = 7}) async {
  final ds = ref.watch(billsDatasourceProvider);
  return ds.getUpcomingBills(days: days);
}

// ─── Bill actions (mark paid, create, update, delete) ────────────────────────

@riverpod
class BillsNotifier extends _$BillsNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Bill?> markPaid(
    String billId, {
    DateTime? paidDate,
    double? paidAmount,
    String? walletId,
  }) async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(billsDatasourceProvider);
      final bill = await ds.markBillPaid(billId, {
        'paid_date': (paidDate ?? DateTime.now()).toIso8601String().substring(0, 10),
        if (paidAmount != null) 'paid_amount': paidAmount,
        if (walletId != null) 'wallet_id': walletId,
      });
      state = const AsyncData(null);
      // Invalidate lists to force refresh
      ref.invalidate(billsProvider);
      ref.invalidate(upcomingBillsProvider);
      // Refresh wallet balances since money was deducted from the wallet
      ref.invalidate(walletBalancesProvider);
      ref.invalidate(walletsProvider);
      return bill;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<Bill?> createBill(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(billsDatasourceProvider);
      final bill = await ds.createBill(data);
      state = const AsyncData(null);
      ref.invalidate(billsProvider);
      return bill;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> deleteBill(String billId) async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(billsDatasourceProvider);
      await ds.deleteBill(billId);
      state = const AsyncData(null);
      ref.invalidate(billsProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<Bill?> updateBill(String billId, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(billsDatasourceProvider);
      final bill = await ds.updateBill(billId, data);
      state = const AsyncData(null);
      ref.invalidate(billsProvider);
      return bill;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// Exclui toda a série recorrente chamando DELETE /bills/{id}?cascade=true
  Future<bool> deleteBillSeries(String billId) async {
    state = const AsyncLoading();
    try {
      final dio = createDio();
      await dio.delete('/bills/$billId', queryParameters: {'cascade': true});
      state = const AsyncData(null);
      ref.invalidate(billsProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
