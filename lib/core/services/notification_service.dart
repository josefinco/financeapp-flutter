import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/dio_client.dart';

/// Canal Android usado tanto no FCM quanto no flutter_local_notifications.
const _kChannelId = 'finance_alerts';
const _kChannelName = 'Alertas Financeiros';
const _kChannelDescription = 'Notificações de contas, orçamentos e alertas financeiros';

final _localNotifications = FlutterLocalNotificationsPlugin();

/// Handler executado em background (isolate separado).
/// Deve ser função top-level.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase já foi inicializado em main.dart antes de registrar este handler.
  debugPrint('[FCM Background] ${message.notification?.title}');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  /// Callback chamado quando o usuário toca em uma notificação.
  /// A UI pode registrar uma função aqui para navegar para a tela correta.
  void Function(String? billId)? onNotificationTap;

  /// Inicializa o serviço: cria canal Android, configura flutter_local_notifications
  /// e solicita permissão de push notifications.
  Future<void> initialize() async {
    // 1. Configurar flutter_local_notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        onNotificationTap?.call(details.payload);
      },
    );

    // 2. Criar canal Android
    const channel = AndroidNotificationChannel(
      _kChannelId,
      _kChannelName,
      description: _kChannelDescription,
      importance: Importance.high,
      playSound: true,
    );
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);

    // 3. Solicitar permissão
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Exibir notificação local quando app está em foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Quando o usuário toca na notificação e o app estava em background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 6. Verificar se o app foi aberto via notificação (estava encerrado)
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Obtém o token FCM do dispositivo e o envia ao backend via PATCH /profile.
  /// Retorna o token ou null em caso de falha.
  Future<String?> getAndSyncToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return null;
      await _sendTokenToBackend(token);

      // Atualiza o token automaticamente quando o FCM o renova
      FirebaseMessaging.instance.onTokenRefresh.listen(_sendTokenToBackend);

      return token;
    } catch (e) {
      debugPrint('[NotificationService] Erro ao obter token FCM: $e');
      return null;
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final dio = createDio();
      await dio.patch('/profile', data: {'fcm_token': token});
      debugPrint('[NotificationService] Token FCM sincronizado com o backend.');
    } catch (e) {
      debugPrint('[NotificationService] Erro ao sincronizar token FCM: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _kChannelId,
          _kChannelName,
          channelDescription: _kChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['bill_id'],
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final billId = message.data['bill_id'] as String?;
    onNotificationTap?.call(billId);
  }
}
