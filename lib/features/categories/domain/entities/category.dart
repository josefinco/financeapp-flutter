import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

enum CategoryType { income, expense, both }

@freezed
class Category with _$Category {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Category({
    required String id,
    required String userId,
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
    required bool isDefault,
    required DateTime createdAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
}
