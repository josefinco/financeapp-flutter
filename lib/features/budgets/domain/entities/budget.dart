import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

double _parseDouble(dynamic value) =>
    value is String ? double.parse(value) : (value as num).toDouble();

@freezed
class Budget with _$Budget {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Budget({
    required String id,
    required String userId,
    required String categoryId,
    @JsonKey(fromJson: _parseDouble) required double amount,
    required int month,
    required int year,
    required int alertAtPercentage,
    @JsonKey(fromJson: _parseDouble) required double spent,
    required double percentage,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Budget;

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);
}
