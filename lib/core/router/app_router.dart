import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';
import '../../features/bills/presentation/pages/bills_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/budgets/presentation/pages/budgets_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/wallets/presentation/pages/wallets_page.dart';

part 'app_router.g.dart';

// ─── Auth change notifier ─────────────────────────────────────────────────────
// Escuta o stream de auth do Supabase e notifica o GoRouter para reavaliar
// os redirects. Necessário para detectar o evento passwordRecovery.

class _AuthChangeNotifier extends ChangeNotifier {
  AuthChangeEvent? _lastEvent;
  AuthChangeEvent? get lastEvent => _lastEvent;

  StreamSubscription<AuthState>? _sub;

  void init() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      _lastEvent = state.event;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final authChangeNotifierProvider = Provider<_AuthChangeNotifier>((ref) {
  final notifier = _AuthChangeNotifier();
  if (isBackendAvailable) notifier.init();
  ref.onDispose(notifier.dispose);
  return notifier;
});

// ─── Router ───────────────────────────────────────────────────────────────────

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authNotifier = ref.watch(authChangeNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      if (!isBackendAvailable) return null;

      // Quando o Supabase processa o link de redefinição de senha, dispara
      // passwordRecovery — redireciona para a tela de nova senha.
      if (authNotifier.lastEvent == AuthChangeEvent.passwordRecovery) {
        return '/reset-password';
      }

      final session = Supabase.instance.client.auth.currentSession;
      final isAuth  = session != null;
      final loc     = state.matchedLocation;

      // /reset-password é sempre acessível (sessão temporária de recovery)
      if (loc == '/reset-password') return null;

      if (!isAuth && loc != '/login') return '/login';
      if (isAuth  && loc == '/login') return '/';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/',              builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/bills',         builder: (_, __) => const BillsPage()),
          GoRoute(path: '/transactions',  builder: (_, __) => const TransactionsPage()),
          GoRoute(path: '/wallets',       builder: (_, __) => const WalletsPage()),
          GoRoute(path: '/reports',       builder: (_, __) => const ReportsPage()),
          GoRoute(path: '/categories',    builder: (_, __) => const CategoriesPage()),
          GoRoute(path: '/budgets',       builder: (_, __) => const BudgetsPage()),
          GoRoute(path: '/ai-chat',       builder: (_, __) => const _ComingSoonPage(title: 'Assistente IA')),
        ],
      ),
      // Rotas fora do shell (sem bottom nav)
      GoRoute(path: '/notifications',   builder: (_, __) => const NotificationsPage()),
      GoRoute(path: '/profile',         builder: (_, __) => const ProfilePage()),
      GoRoute(path: '/login',           builder: (_, __) => const LoginPage()),
      GoRoute(path: '/reset-password',  builder: (_, __) => const ResetPasswordPage()),
    ],
  );
}

// ─── Main Shell ───────────────────────────────────────────────────────────────

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF232333)
                  : const Color(0xFFE8EBF0),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _indexFromLocation(location),
          onDestinationSelected: (i) => _navigateTo(context, i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          animationDuration: const Duration(milliseconds: 400),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Contas',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_horiz_outlined),
              selectedIcon: Icon(Icons.swap_horiz_rounded),
              label: 'Lançamentos',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Carteiras',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Relatórios',
            ),
          ],
        ),
      ),
    );
  }

  int _indexFromLocation(String location) => switch (location) {
    '/'             => 0,
    '/bills'        => 1,
    '/transactions' => 2,
    '/wallets'      => 3,
    '/reports'      => 4,
    _               => 0,
  };

  void _navigateTo(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/');
      case 1: context.go('/bills');
      case 2: context.go('/transactions');
      case 3: context.go('/wallets');
      case 4: context.go('/reports');
    }
  }
}

// ─── Coming soon placeholder ──────────────────────────────────────────────────

class _ComingSoonPage extends StatelessWidget {
  final String title;
  const _ComingSoonPage({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF171720) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)],
              ),
              child: Icon(Icons.construction_rounded, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Em breve por aqui',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
