import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../domain/entities/notification_log.dart';

part 'notifications_remote_datasource.g.dart';

@RestApi()
abstract class NotificationsRemoteDatasource {
  factory NotificationsRemoteDatasource(Dio dio) = _NotificationsRemoteDatasource;

  @GET('/notifications')
  Future<NotificationListResponse> getNotifications({
    @Query('limit') int limit = 50,
    @Query('offset') int offset = 0,
  });

  @PATCH('/notifications/{id}/read')
  Future<NotificationLog> markAsRead(@Path('id') String id);
}
