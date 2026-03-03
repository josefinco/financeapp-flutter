import 'package:dio/dio.dart';

import '../../domain/entities/wallet.dart';

class WalletsRemoteDatasource {
  final Dio _dio;
  const WalletsRemoteDatasource(this._dio);

  Future<List<Wallet>> getWallets() async {
    final response = await _dio.get('/wallets');
    return (response.data as List)
        .map((e) => Wallet.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Wallet> createWallet(Map<String, dynamic> body) async {
    final response = await _dio.post('/wallets', data: body);
    return Wallet.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Wallet> updateWallet(String id, Map<String, dynamic> body) async {
    final response = await _dio.patch('/wallets/$id', data: body);
    return Wallet.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteWallet(String id) async {
    await _dio.delete('/wallets/$id');
  }
}
