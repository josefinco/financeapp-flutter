import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_log.freezed.dart';
part 'notification_log.g.dart';

@freezed
class NotificationLog with _$NotificationLog {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory NotificationLog({
    required String id,
    required String userId,
    String? billId,
    required String title,
    required String body,
    required String type,
    int? daysBefore,
    required DateTime sentAt,
    DateTime? readAt,
  }) = _NotificationLog;

  factory NotificationLog.fromJson(Map<String, dynamic> json) =>
      _$NotificationLogFromJson(json);
}

class NotificationListResponse {
  final List<NotificationLog> items;
  final int total;
  final int unreadCount;

  NotificationListResponse({
    required this.items,
    required this.total,
    required this.unreadCount,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) =>
      NotificationListResponse(
        items: (json['items'] as List)
            .map((e) => NotificationLog.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        unreadCount: json['unread_count'] as int,
      );
}
