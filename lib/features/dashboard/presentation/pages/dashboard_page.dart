import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../bills/domain/entities/bill.dart';
import '../../../bills/presentation/providers/bills_provider.dart';
import '../../../bills/presentation/pages/bills_page.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();

    // Pending bills filtered by current month
    final pendingAsync = ref.watch(billsProvider(
      status: BillStatus.pending,
      month: now.month,
      year: now.year,
    ));

    // All overdue bills — filtered client-side to current month for the summary
    final overdueAsync = ref.watch(billsProvider(status: BillStatus.overdue));

    final upcomingAsync = ref.watch(upcomingBillsProvider(days: 7));
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final monthName = _cap(DateFormat('MMMM', 'pt_BR').format(now));

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
            // ─── Hero header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _HeroSection(
                pendingAsync: pendingAsync,
                overdueAsync: overdueAsync,
                currencyFmt: currencyFmt,
                monthName: monthName,
                now: now,
              ),
            ),

            // ─── Upcoming bills header ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Próximos 7 dias',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    upcomingAsync.maybeWhen(
                      data: (bills) => bills.isNotEmpty
                          ? _CountBadge(
                              count: bills.length,
                              color: AppTheme.pendingColor)
                          : const SizedBox(),
                      orElse: () => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Upcoming bills list ──────────────────────────────────────
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

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Hero Section ──────────────────────────────────────────────────────────────

class _HeroSection extends ConsumerWidget {
  final AsyncValue<dynamic> pendingAsync;
  final AsyncValue<dynamic> overdueAsync;
  final NumberFormat currencyFmt;
  final String monthName;
  final DateTime now;

  const _HeroSection({
    required this.pendingAsync,
    required this.overdueAsync,
    required this.currencyFmt,
    required this.monthName,
    required this.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Bom dia ☀️' : hour < 18 ? 'Boa tarde 🌤' : 'Boa noite 🌙';

    // Pending this month
    final pendingBills = pendingAsync.maybeWhen(
      data: (res) => res.items as List<Bill>,
      orElse: () => <Bill>[],
    );
    final pendingCount = pendingBills.length;
    final pendingAmount =
        pendingBills.fold(0.0, (s, b) => s + b.amount);

    // Overdue scoped to this month (client-side filter)
    final overdueBills = overdueAsync.maybeWhen(
      data: (res) => (res.items as List<Bill>)
          .where(
              (b) => b.dueDate.month == now.month && b.dueDate.year == now.year)
          .toList(),
      orElse: () => <Bill>[],
    );
    final overdueCount = overdueBills.length;
    final overdueAmount =
        overdueBills.fold(0.0, (s, b) => s + b.amount);

    // Total unpaid this month = pending + overdue
    final totalUnpaid = pendingAmount + overdueAmount;
    final isLoading = pendingAsync.isLoading || overdueAsync.isLoading;

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

              // ── Main total ─────────────────────────────────────────────
              Text(
                'Em aberto em $monthName',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              isLoading
                  ? const SizedBox(
                      height: 44,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white54, strokeWidth: 2),
                        ),
                      ),
                    )
                  : Text(
                      currencyFmt.format(totalUnpaid),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        height: 1.1,
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

              const SizedBox(height: 20),

              // ── Status cards ──────────────────────────────────────────
              Row(
                children: [
                  // A Pagar card
                  Expanded(
                    child: _BillStatusCard(
                      label: 'A Pagar',
                      sublabel: 'Este mês',
                      icon: Icons.payments_outlined,
                      accentColor: const Color(0xFFFFD54F),
                      count: pendingCount,
                      amount: pendingAmount,
                      currencyFmt: currencyFmt,
                      isLoading: pendingAsync.isLoading,
                      onTap: () => context.go('/bills'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Vencidas card
                  Expanded(
                    child: _BillStatusCard(
                      label: 'Vencidas',
                      sublabel: 'Este mês',
                      icon: Icons.warning_amber_rounded,
                      accentColor: const Color(0xFFFF7043),
                      count: overdueCount,
                      amount: overdueAmount,
                      currencyFmt: currencyFmt,
                      isLoading: overdueAsync.isLoading,
                      urgent: overdueCount > 0,
                      onTap: () => context.go('/bills'),
                    ),
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

// ─── Bill Status Card (glassmorphism) ─────────────────────────────────────────

class _BillStatusCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color accentColor;
  final int count;
  final double amount;
  final NumberFormat currencyFmt;
  final bool isLoading;
  final bool urgent;
  final VoidCallback onTap;

  const _BillStatusCard({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.accentColor,
    required this.count,
    required this.amount,
    required this.currencyFmt,
    required this.isLoading,
    required this.onTap,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = urgent
        ? accentColor.withOpacity(0.45)
        : Colors.white.withOpacity(0.16);
    final bgColor = urgent
        ? accentColor.withOpacity(0.14)
        : Colors.white.withOpacity(0.10);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white54, strokeWidth: 2),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon row with optional urgent dot
                  Row(
                    children: [
                      Icon(icon, color: accentColor, size: 18),
                      const Spacer(),
                      if (urgent && count > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      else if (count > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Amount
                  Text(
                    count == 0 ? 'R\$ 0,00' : currencyFmt.format(amount),
                    style: TextStyle(
                      color: count == 0
                          ? Colors.white.withOpacity(0.35)
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Label
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Sublabel: count + scope
                  Text(
                    count == 0
                        ? sublabel
                        : '$count ${count == 1 ? 'conta' : 'contas'} · $sublabel',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
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
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w700),
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
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
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
            child: const Icon(Icons.check_circle_outline_rounded,
                size: 32, color: AppTheme.paidColor),
          ),
          const SizedBox(height: 14),
          Text('Tudo em dia! 🎉',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
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
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.errorColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppTheme.errorColor, fontSize: 13))),
        ],
      ),
    );
  }
}
