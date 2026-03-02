import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../bills/presentation/providers/bills_provider.dart';
import '../../../bills/presentation/pages/bills_page.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now           = DateTime.now();
    final billsAsync    = ref.watch(billsProvider(month: now.month, year: now.year));
    final upcomingAsync = ref.watch(upcomingBillsProvider(days: 7));
    final currencyFmt   = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final monthName     = _cap(DateFormat('MMMM', 'pt_BR').format(now));

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
            // ─── Full hero header (gradient + stat cards inside) ─────────
            SliverToBoxAdapter(
              child: _HeroSection(
                billsAsync: billsAsync,
                currencyFmt: currencyFmt,
                monthName: monthName,
              ),
            ),

            // ─── Upcoming bills section ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Próximos 7 dias',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    upcomingAsync.maybeWhen(
                      data: (bills) => bills.isNotEmpty
                          ? _CountBadge(count: bills.length, color: AppTheme.pendingColor)
                          : const SizedBox(),
                      orElse: () => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Bills list ──────────────────────────────────────────────
            upcomingAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ErrorBanner(message: 'Erro ao carregar: $e'),
                ),
              ),
              data: (bills) {
                if (bills.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _EmptyState(),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: bills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => BillCard(bill: bills[i]),
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

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Hero Section (gradient header + stats) ───────────────────────────────────

class _HeroSection extends StatelessWidget {
  final AsyncValue<dynamic> billsAsync;
  final NumberFormat currencyFmt;
  final String monthName;

  const _HeroSection({
    required this.billsAsync,
    required this.currencyFmt,
    required this.monthName,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bom dia ☀️' : hour < 18 ? 'Boa tarde 🌤' : 'Boa noite 🌙';

    final totalAmount = billsAsync.maybeWhen(
      data: (res) => currencyFmt.format(res.totalPendingAmount),
      orElse: () => '---',
    );
    final pendingAmount = billsAsync.maybeWhen(
      data: (res) => currencyFmt.format(res.totalPendingAmount),
      orElse: () => '--',
    );
    final overdueCount  = billsAsync.maybeWhen(data: (res) => res.overdueCount,  orElse: () => 0);
    final pendingCount  = billsAsync.maybeWhen(data: (res) => res.pendingCount,   orElse: () => 0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B3D2E), Color(0xFF1B6B45), Color(0xFF1A3A5C)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Moneta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _GlassButton(icon: Icons.notifications_outlined, onTap: () {}),
                      const SizedBox(width: 10),
                      _GlassButton(
                        icon: Icons.person_outline_rounded,
                        onTap: () => context.go('/profile'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Balance ────────────────────────────────────────────────
              Text(
                'Total a pagar em $monthName',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              billsAsync.when(
                loading: () => const SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)),
                  ),
                ),
                error: (_, __) => const SizedBox(),
                data: (_) => Text(
                  totalAmount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    height: 1.1,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ── Quick actions ──────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _QuickChip(
                      icon: Icons.add_rounded,
                      label: 'Nova conta',
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => const CreateBillSheet(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _QuickChip(
                      icon: Icons.bar_chart_rounded,
                      label: 'Relatório',
                      onTap: () => context.go('/reports'),
                    ),
                    const SizedBox(width: 8),
                    _QuickChip(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Lançamentos',
                      onTap: () => context.go('/transactions'),
                    ),
                    const SizedBox(width: 8),
                    _QuickChip(
                      icon: Icons.category_outlined,
                      label: 'Categorias',
                      onTap: () => context.go('/categories'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Stat cards (glassmorphism on gradient) ─────────────────
              Row(
                children: [
                  _GlassStatCard(
                    label: 'A Pagar',
                    value: pendingAmount,
                    icon: Icons.payments_outlined,
                    iconColor: const Color(0xFFFFD54F),
                    flex: 5,
                  ),
                  const SizedBox(width: 10),
                  _GlassStatCard(
                    label: 'Vencidas',
                    value: overdueCount.toString(),
                    icon: Icons.warning_amber_rounded,
                    iconColor: const Color(0xFFFF7043),
                    flex: 3,
                  ),
                  const SizedBox(width: 10),
                  _GlassStatCard(
                    label: 'Pendentes',
                    value: pendingCount.toString(),
                    icon: Icons.hourglass_top_rounded,
                    iconColor: const Color(0xFF81C784),
                    flex: 3,
                  ),
                ],
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
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─── Glass stat card ──────────────────────────────────────────────────────────

class _GlassStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final int flex;

  const _GlassStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.16), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick action chip ────────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Count badge ──────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        '$count',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171720) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.paidColor.withOpacity(0.2)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.paidColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 32, color: AppTheme.paidColor),
          ),
          const SizedBox(height: 14),
          Text('Tudo em dia! 🎉', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Nenhuma conta nos próximos 7 dias',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

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
          Expanded(child: Text(message, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13))),
        ],
      ),
    );
  }
}
