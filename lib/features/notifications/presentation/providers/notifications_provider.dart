import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/notifications_remote_datasource.dart';
import '../../domain/entities/notification_log.dart';
import '../../../../core/network/dio_client.dart';

part 'notifications_provider.g.dart';

// ─── Datasource provider ──────────────────────────────────────────────────────

@riverpod
NotificationsRemoteDatasource notificationsDatasource(
    NotificationsDatasourceRef ref) {
  return NotificationsRemoteDatasource(createDio());
}

// ─── Notifications list ───────────────────────────────────────────────────────

@riverpod
Future<NotificationListResponse> notifications(NotificationsRef ref) async {
  final ds = ref.watch(notificationsDatasourceProvider);
  return ds.getNotifications();
}

// ─── Notifications actions ────────────────────────────────────────────────────

@riverpod
class NotificationsNotifier extends _$NotificationsNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> markAsRead(String notificationId) async {
    try {
      final ds = ref.read(notificationsDatasourceProvider);
      await ds.markAsRead(notificationId);
      ref.invalidate(notificationsProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
