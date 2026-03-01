import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../domain/entities/budget.dart';

part 'budgets_remote_datasource.g.dart';

@RestApi()
abstract class BudgetsRemoteDatasource {
  factory BudgetsRemoteDatasource(Dio dio) = _BudgetsRemoteDatasource;

  @GET('/budgets')
  Future<List<Budget>> getBudgets({
    @Query('month') int? month,
    @Query('year') int? year,
  });

  @GET('/budgets/{id}')
  Future<Budget> getBudget(@Path('id') String id);

  @POST('/budgets')
  Future<Budget> createBudget(@Body() Map<String, dynamic> body);

  @PATCH('/budgets/{id}')
  Future<Budget> updateBudget(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/budgets/{id}')
  Future<void> deleteBudget(@Path('id') String id);
}
