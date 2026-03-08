import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class UserProfile with _$UserProfile {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory UserProfile({
    required String id,
    required String userId,
    required String fullName,
    String? avatarUrl,
    required String currency,
    required String timezone,
    String? fcmToken,
    required bool notificationsEnabled,
    @JsonKey(defaultValue: 8) @Default(8) int notificationHour,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
