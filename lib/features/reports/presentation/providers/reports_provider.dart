import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/report.dart';
import '../../data/datasources/reports_remote_datasource.dart';
import '../../../../core/network/dio_client.dart';

part 'reports_provider.g.dart';

// ─── Wallet Balances (manual FutureProvider – sem retrofit) ───────────────────

/// Represents a wallet balance entry returned by GET /reports/wallets
class WalletBalance {
  final String walletId;
  final String walletName;
  final double balance;
  final String walletType;
  final String color;

  const WalletBalance({
    required this.walletId,
    required this.walletName,
    required this.balance,
    required this.walletType,
    required this.color,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> j) => WalletBalance(
        walletId:   j['wallet_id'].toString(),
        walletName: j['wallet_name'] as String,
        balance:    j['balance'] is String
            ? double.parse(j['balance'])
            : (j['balance'] as num).toDouble(),
        walletType: j['wallet_type'] as String,
        color:      j['color'] as String? ?? '#4CAF50',
      );
}

class WalletBalancesData {
  final List<WalletBalance> wallets;
  final double totalBalance;

  const WalletBalancesData({required this.wallets, required this.totalBalance});

  factory WalletBalancesData.fromJson(Map<String, dynamic> j) =>
      WalletBalancesData(
        wallets: (j['wallets'] as List)
            .map((e) => WalletBalance.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalBalance: j['total_balance'] is String
            ? double.parse(j['total_balance'])
            : (j['total_balance'] as num).toDouble(),
      );
}

final walletBalancesProvider = FutureProvider.autoDispose<WalletBalancesData>((ref) async {
  final dio = createDio();
  final response = await dio.get('/reports/wallets');
  return WalletBalancesData.fromJson(response.data as Map<String, dynamic>);
});

@riverpod
ReportsRemoteDatasource reportsDatasource(ReportsDatasourceRef ref) {
  return ReportsRemoteDatasource(createDio());
}

@riverpod
Future<MonthlySummary> monthlySummary(
  MonthlySummaryRef ref, {
  int? month,
  int? year,
}) async {
  final ds = ref.watch(reportsDatasourceProvider);
  return ds.getMonthlySummary(month: month, year: year);
}

@riverpod
Future<ExpenseByCategoryResponse> expensesByCategory(
  ExpensesByCategoryRef ref, {
  int? month,
  int? year,
}) async {
  final ds = ref.watch(reportsDatasourceProvider);
  return ds.getExpensesByCategory(month: month, year: year);
}

@riverpod
Future<MonthlyEvolutionResponse> monthlyEvolution(
  MonthlyEvolutionRef ref, {
  int months = 6,
}) async {
  final ds = ref.watch(reportsDatasourceProvider);
  return ds.getMonthlyEvolution(months: months);
}
