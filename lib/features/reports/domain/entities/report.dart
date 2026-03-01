import 'package:freezed_annotation/freezed_annotation.dart';

part 'report.freezed.dart';
part 'report.g.dart';

double _parseDouble(dynamic value) =>
    value is String ? double.parse(value) : (value as num).toDouble();

double? _parseDoubleNullable(dynamic value) => value == null
    ? null
    : (value is String ? double.parse(value) : (value as num).toDouble());

@freezed
class MonthlySummary with _$MonthlySummary {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory MonthlySummary({
    required int month,
    required int year,
    @JsonKey(fromJson: _parseDouble) required double totalIncome,
    @JsonKey(fromJson: _parseDouble) required double totalExpense,
    @JsonKey(fromJson: _parseDouble) required double balance,
    required int pendingBills,
    required int overdueBills,
  }) = _MonthlySummary;

  factory MonthlySummary.fromJson(Map<String, dynamic> json) =>
      _$MonthlySummaryFromJson(json);
}

@freezed
class CategoryExpense with _$CategoryExpense {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CategoryExpense({
    String? categoryId,
    required String categoryName,
    required String categoryColor,
    @JsonKey(fromJson: _parseDouble) required double amount,
    required double percentage,
  }) = _CategoryExpense;

  factory CategoryExpense.fromJson(Map<String, dynamic> json) =>
      _$CategoryExpenseFromJson(json);
}

class ExpenseByCategoryResponse {
  final int month;
  final int year;
  final double total;
  final List<CategoryExpense> categories;

  ExpenseByCategoryResponse({
    required this.month,
    required this.year,
    required this.total,
    required this.categories,
  });

  factory ExpenseByCategoryResponse.fromJson(Map<String, dynamic> json) =>
      ExpenseByCategoryResponse(
        month: json['month'],
        year: json['year'],
        total: json['total'] is String
            ? double.parse(json['total'])
            : (json['total'] as num).toDouble(),
        categories: (json['categories'] as List)
            .map((e) => CategoryExpense.fromJson(e))
            .toList(),
      );
}

class MonthlyEvolutionResponse {
  final List<MonthlySummary> months;

  MonthlyEvolutionResponse({required this.months});

  factory MonthlyEvolutionResponse.fromJson(Map<String, dynamic> json) =>
      MonthlyEvolutionResponse(
        months: (json['months'] as List)
            .map((e) => MonthlySummary.fromJson(e))
            .toList(),
      );
}
