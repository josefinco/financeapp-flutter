import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';
import '../../features/bills/presentation/pages/bills_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/budgets/presentation/pages/budgets_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (!isBackendAvailable) return null;

      final session   = Supabase.instance.client.auth.currentSession;
      final isAuth    = session != null;
      final isLogin   = state.matchedLocation == '/login';

      if (!isAuth && !isLogin) return '/login';
      if (isAuth  &&  isLogin) return '/';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/',              builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/bills',         builder: (_, __) => const BillsPage()),
          GoRoute(path: '/transactions',  builder: (_, __) => const TransactionsPage()),
          GoRoute(path: '/reports',       builder: (_, __) => const ReportsPage()),
          GoRoute(path: '/categories',    builder: (_, __) => const CategoriesPage()),
          GoRoute(path: '/budgets',       builder: (_, __) => const BudgetsPage()),
          GoRoute(path: '/ai-chat',       builder: (_, __) => const _ComingSoonPage(title: 'Assistente IA')),
          GoRoute(path: '/profile',       builder: (_, __) => const ProfilePage()),
        ],
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
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
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Relatórios',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded),
              label: 'IA',
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
    '/reports'      => 3,
    '/ai-chat'      => 4,
    _               => 0,
  };

  void _navigateTo(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/');
      case 1: context.go('/bills');
      case 2: context.go('/transactions');
      case 3: context.go('/reports');
      case 4: context.go('/ai-chat');
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
