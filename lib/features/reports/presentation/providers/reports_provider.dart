import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/report.dart';
import '../../data/datasources/reports_remote_datasource.dart';
import '../../../../core/network/dio_client.dart';

part 'reports_provider.g.dart';

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
