import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serviço responsável pela autenticação biométrica e armazenamento seguro
/// de credenciais no dispositivo Android.
class BiometricService {
  BiometricService._();
  static final instance = BiometricService._();

  final _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyEmail    = 'biometric_email';
  static const _keyPassword = 'biometric_password';

  // ─── Disponibilidade ───────────────────────────────────────────────────────

  /// Retorna true se o dispositivo suporta biometria E tem ao menos uma
  /// digital/face cadastrada.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isDeviceSupported) return false;

      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  // ─── Credenciais salvas ────────────────────────────────────────────────────

  /// Verifica se já existe um e-mail salvo para login biométrico.
  Future<bool> hasStoredCredentials() async {
    final email = await _storage.read(key: _keyEmail);
    return email != null && email.isNotEmpty;
  }

  /// Retorna o e-mail salvo (para exibir na UI, sem expor a senha).
  Future<String?> getStoredEmail() async {
    return _storage.read(key: _keyEmail);
  }

  /// Salva as credenciais de forma segura após login bem-sucedido.
  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
  }

  /// Remove as credenciais salvas (ex: ao fazer logout ou trocar de conta).
  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
  }

  // ─── Autenticação ──────────────────────────────────────────────────────────

  /// Exibe o prompt biométrico nativo do Android e, se aprovado, retorna
  /// as credenciais salvas. Retorna null se a autenticação falhar ou se
  /// não houver credenciais armazenadas.
  Future<({String email, String password})?> authenticateAndGetCredentials() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Use sua digital para entrar no Moneta',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!authenticated) return null;

      final email    = await _storage.read(key: _keyEmail);
      final password = await _storage.read(key: _keyPassword);

      if (email == null || password == null) return null;
      return (email: email, password: password);
    } on PlatformException {
      return null;
    }
  }
}
