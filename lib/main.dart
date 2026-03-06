import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/config/app_config.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

/// Handler de mensagens FCM em background (isolate separado).
/// Deve ser função top-level.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background] ${message.notification?.title}');
}

/// Global theme mode provider — toggled from the profile screen.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Whether backend services (Supabase/Firebase) are available.
bool isBackendAvailable = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('pt_BR');

  // Skip backend init when using placeholder credentials
  final hasRealSupabase = AppConfig.supabaseUrl != 'https://your-project.supabase.co' &&
      AppConfig.supabaseAnonKey != 'your-anon-key';

  if (hasRealSupabase) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      isBackendAvailable = true;
    } catch (e) {
      debugPrint('Supabase init failed: $e — running in demo mode');
    }

    // Firebase é opcional (push notifications) — não bloqueia o app se ausente
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await NotificationService.instance.initialize();
      await NotificationService.instance.getAndSyncToken();
    } catch (e) {
      debugPrint('Firebase init skipped: $e');
    }
  } else {
    debugPrint('No real Supabase credentials — running in demo mode');
  }

  runApp(const ProviderScope(child: MonetaApp()));
}

class MonetaApp extends ConsumerWidget {
  const MonetaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router    = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Moneta',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
    );
  }
}
