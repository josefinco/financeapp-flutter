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

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Skip auth check in demo mode
      if (!isBackendAvailable) return null;

      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuth && !isLoginRoute) return '/login';
      if (isAuth && isLoginRoute) return '/';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/bills', builder: (_, __) => const BillsPage()),
          GoRoute(path: '/transactions', builder: (_, __) => const TransactionsPage()),
          GoRoute(path: '/reports', builder: (_, __) => const ReportsPage()),
          GoRoute(path: '/categories', builder: (_, __) => const CategoriesPage()),
          GoRoute(path: '/budgets', builder: (_, __) => const BudgetsPage()),
          GoRoute(path: '/ai-chat', builder: (_, __) => const _ComingSoonPage(title: 'Assistente IA')),
        ],
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    ],
  );
}

// ─── Main Shell (Bottom Navigation) ─────────────────────────────────────────

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexFromLocation(location),
        onTap: (i) => _navigateTo(context, i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Contas'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz_outlined), activeIcon: Icon(Icons.swap_horiz), label: 'Lançamentos'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Relatórios'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), activeIcon: Icon(Icons.smart_toy), label: 'IA'),
        ],
      ),
    );
  }

  int _indexFromLocation(String location) => switch (location) {
        '/' => 0,
        '/bills' => 1,
        '/transactions' => 2,
        '/reports' => 3,
        '/ai-chat' => 4,
        _ => 0,
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

// ─── Placeholder para rotas ainda não implementadas ─────────────────────────

class _ComingSoonPage extends StatelessWidget {
  final String title;
  const _ComingSoonPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Em desenvolvimento — backend em breve',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
