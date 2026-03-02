import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../bills/presentation/providers/bills_provider.dart';
import '../../../bills/presentation/pages/bills_page.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now          = DateTime.now();
    final billsAsync   = ref.watch(billsProvider(month: now.month, year: now.year));
    final upcomingAsync = ref.watch(upcomingBillsProvider(days: 7));
    final currencyFmt  = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final monthName    = _capitalizeFirst(DateFormat('MMMM', 'pt_BR').format(now));

    // Extract values for header
    final totalAmount  = billsAsync.maybeWhen(
      data: (res) => currencyFmt.format(res.totalPendingAmount),
      orElse: () => '--',
    );
    final overdueCount = billsAsync.maybeWhen(
      data: (res) => res.overdueCount,
      orElse: () => 0,
    );
    final pendingCount = billsAsync.maybeWhen(
      data: (res) => res.pendingCount,
      orElse: () => 0,
    );
    final pendingAmount = billsAsync.maybeWhen(
      data: (res) => currencyFmt.format(res.totalPendingAmount),
      orElse: () => '--',
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppTheme.incomeColor,
        onRefresh: () async {
          ref.invalidate(billsProvider);
          ref.invalidate(upcomingBillsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ─── Hero Header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _HeroHeader(
                totalAmount: totalAmount,
                monthName: monthName,
              ),
            ),

            // ─── Stats Row ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: billsAsync.when(
                    loading: () => const SizedBox(height: 88, child: Center(child: CircularProgressIndicator())),
                    error: (_, __) => const SizedBox(),
                    data: (_) => Row(
                      children: [
                        _StatCard(
                          label: 'A Pagar',
                          value: pendingAmount,
                          icon: Icons.payments_outlined,
                          color: AppTheme.pendingColor,
                          flex: 2,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Vencidas',
                          value: overdueCount.toString(),
                          icon: Icons.warning_amber_rounded,
                          color: AppTheme.overdueColor,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Pendentes',
                          value: pendingCount.toString(),
                          icon: Icons.hourglass_top_rounded,
                          color: AppTheme.expenseColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ─── Section: Upcoming ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Próximos 7 dias',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    upcomingAsync.maybeWhen(
                      data: (bills) => bills.isNotEmpty
                          ? _Badge(label: '${bills.length}', color: AppTheme.pendingColor)
                          : const SizedBox(),
                      orElse: () => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Upcoming list ───────────────────────────────────────────
            upcomingAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ErrorCard(message: 'Erro ao carregar contas: $e'),
                ),
              ),
              data: (bills) {
                if (bills.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _EmptyCard(
                        icon: Icons.check_circle_outline_rounded,
                        color: AppTheme.paidColor,
                        title: 'Tudo em dia! 🎉',
                        subtitle: 'Nenhuma conta nos próximos 7 dias',
                      ),
                    ),
                  );
                }
                return SliverList.separated(
                  itemCount: bills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: BillCard(bill: bills[i]),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  static String _capitalizeFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Hero Header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final String totalAmount;
  final String monthName;

  const _HeroHeader({required this.totalAmount, required this.monthName});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bom dia ☀️' : hour < 18 ? 'Boa tarde 🌤' : 'Boa noite 🌙';

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Moneta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                  _GlassButton(
                    icon: Icons.notifications_outlined,
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Balance label
              Text(
                'Total a pagar em $monthName',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),

              // Big balance number
              Text(
                totalAmount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),

              const SizedBox(height: 20),

              // Quick action chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickAction(icon: Icons.add_rounded, label: 'Nova conta', onTap: () {}),
                    const SizedBox(width: 10),
                    _QuickAction(icon: Icons.bar_chart_rounded, label: 'Relatório', onTap: () {}),
                    const SizedBox(width: 10),
                    _QuickAction(icon: Icons.category_outlined, label: 'Categorias', onTap: () {}),
                    const SizedBox(width: 10),
                    _QuickAction(icon: Icons.account_balance_wallet_outlined, label: 'Carteiras', onTap: () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Glass icon button ────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─── Quick action chip ────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int flex;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171720) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.18), width: 1),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: flex == 2 ? 14 : 18,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─── Empty state card ─────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _EmptyCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171720) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─── Error card ───────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
