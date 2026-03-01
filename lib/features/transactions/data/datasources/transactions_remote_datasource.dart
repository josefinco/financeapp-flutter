import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../domain/entities/transaction.dart';

part 'transactions_remote_datasource.g.dart';

@RestApi()
abstract class TransactionsRemoteDatasource {
  factory TransactionsRemoteDatasource(Dio dio) = _TransactionsRemoteDatasource;

  @GET('/transactions')
  Future<TransactionListResponse> getTransactions({
    @Query('wallet_id') String? walletId,
    @Query('type') String? type,
    @Query('month') int? month,
    @Query('year') int? year,
    @Query('category_id') String? categoryId,
  });

  @GET('/transactions/{id}')
  Future<Transaction> getTransaction(@Path('id') String id);

  @POST('/transactions')
  Future<Transaction> createTransaction(@Body() Map<String, dynamic> body);

  @PATCH('/transactions/{id}')
  Future<Transaction> updateTransaction(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/transactions/{id}')
  Future<void> deleteTransaction(@Path('id') String id);
}
