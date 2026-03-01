import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType { income, expense, transfer }

double _parseDouble(dynamic value) =>
    value is String ? double.parse(value) : (value as num).toDouble();

double? _parseDoubleNullable(dynamic value) => value == null
    ? null
    : (value is String ? double.parse(value) : (value as num).toDouble());

@freezed
class Transaction with _$Transaction {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Transaction({
    required String id,
    required String userId,
    required String walletId,
    String? categoryId,
    String? billId,
    required TransactionType type,
    @JsonKey(fromJson: _parseDouble) required double amount,
    required String description,
    required DateTime date,
    String? notes,
    required bool isConfirmed,
    String? destinationWalletId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
}

class TransactionListResponse {
  final List<Transaction> items;
  final int total;
  final double totalIncome;
  final double totalExpense;

  TransactionListResponse({
    required this.items,
    required this.total,
    required this.totalIncome,
    required this.totalExpense,
  });

  factory TransactionListResponse.fromJson(Map<String, dynamic> json) =>
      TransactionListResponse(
        items: (json['items'] as List).map((e) => Transaction.fromJson(e)).toList(),
        total: json['total'],
        totalIncome: json['total_income'] is String
            ? double.parse(json['total_income'])
            : (json['total_income'] as num).toDouble(),
        totalExpense: json['total_expense'] is String
            ? double.parse(json['total_expense'])
            : (json['total_expense'] as num).toDouble(),
      );
}
