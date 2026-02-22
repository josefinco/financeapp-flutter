import 'package:freezed_annotation/freezed_annotation.dart';

part 'bill.freezed.dart';
part 'bill.g.dart';

enum BillStatus { pending, paid, overdue, cancelled }

enum RecurrenceType { none, daily, weekly, monthly, yearly }

@freezed
class Bill with _$Bill {
  const factory Bill({
    required String id,
    required String userId,
    required String name,
    required double amount,
    required DateTime dueDate,
    required BillStatus status,
    required RecurrenceType recurrence,
    String? description,
    String? walletId,
    String? categoryId,
    DateTime? paidDate,
    double? paidAmount,
    String? notes,
    String? attachmentUrl,
    int? installmentNumber,
    int? totalInstallments,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Bill;

  factory Bill.fromJson(Map<String, dynamic> json) => _$BillFromJson(json);
}
