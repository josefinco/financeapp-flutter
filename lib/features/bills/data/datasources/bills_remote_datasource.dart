import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../domain/entities/bill.dart';

part 'bills_remote_datasource.g.dart';

@RestApi()
abstract class BillsRemoteDatasource {
  factory BillsRemoteDatasource(Dio dio) = _BillsRemoteDatasource;

  @GET('/bills')
  Future<BillListResponse> getBills({
    @Query('status') String? status,
    @Query('month') int? month,
    @Query('year') int? year,
    @Query('category_id') String? categoryId,
  });

  @GET('/bills/upcoming')
  Future<List<Bill>> getUpcomingBills({
    @Query('days') int days = 7,
  });

  @GET('/bills/{id}')
  Future<Bill> getBill(@Path('id') String id);

  @POST('/bills')
  Future<Bill> createBill(@Body() Map<String, dynamic> body);

  @PATCH('/bills/{id}')
  Future<Bill> updateBill(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('/bills/{id}/pay')
  Future<Bill> markBillPaid(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/bills/{id}')
  Future<void> deleteBill(@Path('id') String id);
}

class BillListResponse {
  final List<Bill> items;
  final int total;
  final int pendingCount;
  final int overdueCount;
  final double totalPendingAmount;

  BillListResponse({
    required this.items,
    required this.total,
    required this.pendingCount,
    required this.overdueCount,
    required this.totalPendingAmount,
  });

  factory BillListResponse.fromJson(Map<String, dynamic> json) =>
      BillListResponse(
        items: (json['items'] as List).map((e) => Bill.fromJson(e)).toList(),
        total: json['total'],
        pendingCount: json['pending_count'],
        overdueCount: json['overdue_count'],
        totalPendingAmount: json['total_pending_amount'] is String
            ? double.parse(json['total_pending_amount'])
            : (json['total_pending_amount'] as num).toDouble(),
      );
}
