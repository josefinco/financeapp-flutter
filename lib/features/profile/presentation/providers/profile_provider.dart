import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/profile_remote_datasource.dart';
import '../../domain/entities/user_profile.dart';
import '../../../../core/network/dio_client.dart';

part 'profile_provider.g.dart';

// ─── Datasource provider ──────────────────────────────────────────────────────

@riverpod
ProfileRemoteDatasource profileDatasource(ProfileDatasourceRef ref) {
  return ProfileRemoteDatasource(createDio());
}

// ─── Profile data ─────────────────────────────────────────────────────────────

@riverpod
Future<UserProfile> profile(ProfileRef ref) async {
  final ds = ref.watch(profileDatasourceProvider);
  return ds.getProfile();
}

// ─── Profile update notifier ──────────────────────────────────────────────────

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<UserProfile?> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(profileDatasourceProvider);
      final updated = await ds.updateProfile(data);
      state = const AsyncData(null);
      ref.invalidate(profileProvider);
      return updated;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<UserProfile?> setNotificationsEnabled(bool enabled) async {
    return updateProfile({'notifications_enabled': enabled});
  }

  Future<UserProfile?> setNotificationHour(int hour) async {
    return updateProfile({'notification_hour': hour});
  }
}
