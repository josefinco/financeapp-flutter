import 'package:freezed_annotation/freezed_annotation.dart';

part 'bill.freezed.dart';
part 'bill.g.dart';

enum BillStatus { pending, paid, overdue, cancelled }

enum RecurrenceType { none, daily, weekly, monthly, yearly }

// Backend returns amount fields as strings ("1650.00"), not numbers.
double _parseDouble(dynamic value) =>
    value is String ? double.parse(value) : (value as num).toDouble();

double? _parseDoubleNullable(dynamic value) => value == null
    ? null
    : (value is String ? double.parse(value) : (value as num).toDouble());

@freezed
class Bill with _$Bill {
  // Backend retorna snake_case: user_id, due_date, wallet_id, etc.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Bill({
    required String id,
    required String userId,
    required String name,
    @JsonKey(fromJson: _parseDouble) required double amount,
    required DateTime dueDate,
    required BillStatus status,
    required RecurrenceType recurrence,
    String? description,
    String? walletId,
    String? categoryId,
    DateTime? paidDate,
    @JsonKey(fromJson: _parseDoubleNullable) double? paidAmount,
    String? notes,
    String? attachmentUrl,
    int? installmentNumber,
    int? totalInstallments,
    DateTime? recurrenceEndDate,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Bill;

  factory Bill.fromJson(Map<String, dynamic> json) => _$BillFromJson(json);
}
