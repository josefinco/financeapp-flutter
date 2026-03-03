// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallets_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$walletsDatasourceHash() => r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';

/// See also [walletsDatasource].
@ProviderFor(walletsDatasource)
final walletsDatasourceProvider =
    AutoDisposeProvider<WalletsRemoteDatasource>.internal(
  walletsDatasource,
  name: r'walletsDatasourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$walletsDatasourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WalletsDatasourceRef = AutoDisposeProviderRef<WalletsRemoteDatasource>;

String _$walletsHash() => r'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1';

/// See also [wallets].
@ProviderFor(wallets)
final walletsProvider = AutoDisposeFutureProvider<List<Wallet>>.internal(
  wallets,
  name: r'walletsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$walletsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WalletsRef = AutoDisposeFutureProviderRef<List<Wallet>>;

String _$walletsNotifierHash() => r'c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2';

/// See also [WalletsNotifier].
@ProviderFor(WalletsNotifier)
final walletsNotifierProvider =
    AutoDisposeNotifierProvider<WalletsNotifier, AsyncValue<void>>.internal(
  WalletsNotifier.new,
  name: r'walletsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$walletsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WalletsNotifier = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
