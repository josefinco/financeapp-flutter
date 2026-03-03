import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/wallet.dart';
import '../../data/datasources/wallets_remote_datasource.dart';
import '../../../../core/network/dio_client.dart';
// Also invalidate walletBalancesProvider in reports so dropdowns stay fresh
import '../../../reports/presentation/providers/reports_provider.dart';

part 'wallets_provider.g.dart';

// ─── Datasource ───────────────────────────────────────────────────────────────

@riverpod
WalletsRemoteDatasource walletsDatasource(WalletsDatasourceRef ref) =>
    WalletsRemoteDatasource(createDio());

// ─── Wallets list ─────────────────────────────────────────────────────────────

@riverpod
Future<List<Wallet>> wallets(WalletsRef ref) async {
  final ds = ref.watch(walletsDatasourceProvider);
  return ds.getWallets();
}

// ─── Wallet actions ───────────────────────────────────────────────────────────

@riverpod
class WalletsNotifier extends _$WalletsNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  void _invalidateAll() {
    ref.invalidate(walletsProvider);
    ref.invalidate(walletBalancesProvider); // keep reports dropdown in sync
  }

  Future<Wallet?> createWallet(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(walletsDatasourceProvider);
      final wallet = await ds.createWallet(data);
      state = const AsyncData(null);
      _invalidateAll();
      return wallet;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<Wallet?> updateWallet(String id, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(walletsDatasourceProvider);
      final wallet = await ds.updateWallet(id, data);
      state = const AsyncData(null);
      _invalidateAll();
      return wallet;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> deleteWallet(String id) async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(walletsDatasourceProvider);
      await ds.deleteWallet(id);
      state = const AsyncData(null);
      _invalidateAll();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
