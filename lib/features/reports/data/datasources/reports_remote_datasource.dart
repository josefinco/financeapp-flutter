import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../domain/entities/report.dart';

part 'reports_remote_datasource.g.dart';

@RestApi()
abstract class ReportsRemoteDatasource {
  factory ReportsRemoteDatasource(Dio dio) = _ReportsRemoteDatasource;

  @GET('/reports/summary')
  Future<MonthlySummary> getMonthlySummary({
    @Query('month') int? month,
    @Query('year') int? year,
  });

  @GET('/reports/expenses-by-category')
  Future<ExpenseByCategoryResponse> getExpensesByCategory({
    @Query('month') int? month,
    @Query('year') int? year,
  });

  @GET('/reports/evolution')
  Future<MonthlyEvolutionResponse> getMonthlyEvolution({
    @Query('months') int months = 6,
  });
}
