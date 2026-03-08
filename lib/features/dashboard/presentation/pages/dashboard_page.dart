import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../bills/domain/entities/bill.dart';
import '../../../bills/presentation/providers/bills_provider.dart';
import '../../../bills/presentation/pages/bills_page.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();

    // Resolve user's first name from Supabase auth metadata or email
    final authUser = Supabase.instance.client.auth.currentUser;
    final firstName = _resolveFirstName(authUser);

    // Pending bills filtered by current month
    final pendingAsync = ref.watch(billsProvider(
      status: BillStatus.pending,
      month: now.month,
      year: now.year,
    ));

    // All overdue bills — filtered client-side to current month for the summary
    final overdueAsync = ref.watch(billsProvider(status: BillStatus.overdue));

    // Paid bills filtered by current month
    final paidAsync = ref.watch(billsProvider(
      status: BillStatus.paid,
      month: now.month,
      year: now.year,
    ));

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
                paidAsync: paidAsync,
                currencyFmt: currencyFmt,
                monthName: monthName,
                firstName: firstName,
                now: now,
              ),
            ),

            // ─── Month progress card ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _MonthProgressCard(
                  pendingAsync: pendingAsync,
                  overdueAsync: overdueAsync,
                  paidAsync: paidAsync,
                  currencyFmt: currencyFmt,
                  monthName: monthName,
                  now: now,
                ),
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
                          ? GestureDetector(
                              onTap: () => context.go('/bills'),
                              child: Row(children: [
                                _CountBadge(
                                    count: bills.length,
                                    color: AppTheme.pendingColor),
                                const SizedBox(width: 6),
                                Text('Ver todos',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.pendingColor,
                                        fontWeight: FontWeight.w600)),
                              ]),
                            )
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
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  static String _resolveFirstName(User? user) {
    if (user == null) return 'você';
    // 1. Try Supabase userMetadata (set at sign-up or profile update)
    final meta = user.userMetadata;
    if (meta != null) {
      for (final key in ['full_name', 'name', 'display_name']) {
        final v = meta[key];
        if (v is String && v.trim().isNotEmpty) {
          return _cap(v.trim().split(RegExp(r'\s+')).first);
        }
      }
    }
    // 2. Derive from email: "jose.silva@..." → "Jose"
    final email = user.email ?? '';
    final local = email.split('@').first;
    return _cap(local.split(RegExp(r'[._+\-]')).first);
  }
}

// ─── Hero Section ──────────────────────────────────────────────────────────────

class _HeroSection extends ConsumerWidget {
  final AsyncValue<dynamic> pendingAsync;
  final AsyncValue<dynamic> overdueAsync;
  final AsyncValue<dynamic> paidAsync;
  final NumberFormat currencyFmt;
  final String monthName;
  final String firstName;
  final DateTime now;

  const _HeroSection({
    required this.pendingAsync,
    required this.overdueAsync,
    required this.paidAsync,
    required this.currencyFmt,
    required this.monthName,
    required this.firstName,
    required this.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bom dia' : hour < 18 ? 'Boa tarde' : 'Boa noite';
    final greetingEmoji = hour < 12 ? '☀️' : hour < 18 ? '🌤' : '🌙';

    final authUser = Supabase.instance.client.auth.currentUser;
    final avatarUrl = () {
      final url = authUser?.userMetadata?['avatar_url'];
      return url is String ? url : '';
    }();

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

    // Paid this month
    final paidBills = paidAsync.maybeWhen(
      data: (res) => res.items as List<Bill>,
      orElse: () => <Bill>[],
    );
    final paidCount = paidBills.length;
    final paidAmount = paidBills.fold(0.0, (s, b) => s + (b.paidAmount ?? b.amount));

    // Total unpaid this month = pending + overdue
    final totalUnpaid = pendingAmount + overdueAmount;
    final isLoading =
        pendingAsync.isLoading || overdueAsync.isLoading || paidAsync.isLoading;

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Brand + greeting
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting line with name
                        Row(
                          children: [
                            Text(
                              '$greeting, $firstName ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                            ),
                            Text(greetingEmoji,
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        // Brand name
                        const Text(
                          'Moneta',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  _GlassButton(
                      icon: Icons.notifications_outlined,
                      onTap: () => context.push('/notifications')),
                  const SizedBox(width: 10),
                  // Avatar button
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF29B6F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1.5),
                      ),
                      child: ClipOval(
                        child: avatarUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Center(
                                  child: Text(
                                    firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Center(
                                  child: Text(
                                    firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                              ),
                      ),
                    ),
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

              // ── Status cards row 1: A Pagar + Vencidas ────────────────
              Row(
                children: [
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

              const SizedBox(height: 10),

              // ── Status card row 2: Pagas (full-width) ─────────────────
              _PaidCard(
                count: paidCount,
                amount: paidAmount,
                currencyFmt: currencyFmt,
                isLoading: paidAsync.isLoading,
                onTap: () => context.go('/bills'),
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

// ─── Month Progress Card ──────────────────────────────────────────────────────

class _MonthProgressCard extends StatelessWidget {
  final AsyncValue<dynamic> pendingAsync;
  final AsyncValue<dynamic> overdueAsync;
  final AsyncValue<dynamic> paidAsync;
  final NumberFormat currencyFmt;
  final String monthName;
  final DateTime now;

  const _MonthProgressCard({
    required this.pendingAsync,
    required this.overdueAsync,
    required this.paidAsync,
    required this.currencyFmt,
    required this.monthName,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final paidBills = paidAsync.maybeWhen(
      data: (res) => res.items as List<Bill>,
      orElse: () => <Bill>[],
    );
    final pendingBills = pendingAsync.maybeWhen(
      data: (res) => res.items as List<Bill>,
      orElse: () => <Bill>[],
    );
    final overdueBills = overdueAsync.maybeWhen(
      data: (res) => (res.items as List<Bill>)
          .where((b) =>
              b.dueDate.month == now.month && b.dueDate.year == now.year)
          .toList(),
      orElse: () => <Bill>[],
    );

    final paidCount = paidBills.length;
    final paidAmount =
        paidBills.fold(0.0, (s, b) => s + (b.paidAmount ?? b.amount));
    final totalCount = paidCount + pendingBills.length + overdueBills.length;
    final progress = totalCount > 0 ? paidCount / totalCount : 0.0;

    final isLoading =
        pendingAsync.isLoading || overdueAsync.isLoading || paidAsync.isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171720) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.06))
            : null,
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Calendar icon with month
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.incomeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              size: 14, color: AppTheme.incomeColor),
                          const SizedBox(width: 5),
                          Text(
                            monthName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.incomeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Progress percentage
                    Text(
                      totalCount == 0
                          ? 'Sem contas'
                          : '$paidCount de $totalCount ${totalCount == 1 ? 'conta paga' : 'contas pagas'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0
                          ? AppTheme.incomeColor
                          : const Color(0xFF29B6F6),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Bottom row: paid vs remaining
                Row(
                  children: [
                    // Paid
                    Expanded(
                      child: _ProgressStat(
                        label: 'Pago',
                        value: currencyFmt.format(paidAmount),
                        color: AppTheme.incomeColor,
                        icon: Icons.check_rounded,
                        isDark: isDark,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.06),
                    ),
                    // Remaining (pending + overdue)
                    Expanded(
                      child: _ProgressStat(
                        label: 'Em aberto',
                        value: currencyFmt.format(
                          (pendingBills.fold(0.0, (s, b) => s + b.amount)) +
                              (overdueBills.fold(0.0, (s, b) => s + b.amount)),
                        ),
                        color: pendingBills.isEmpty && overdueBills.isEmpty
                            ? AppTheme.incomeColor
                            : AppTheme.pendingColor,
                        icon: Icons.pending_outlined,
                        isDark: isDark,
                        alignRight: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isDark;
  final bool alignRight;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: alignRight ? 14 : 0, right: alignRight ? 0 : 14),
      child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: alignRight
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!alignRight) ...[
                Icon(icon, size: 11, color: color),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withOpacity(0.45)
                      : Colors.black45,
                ),
              ),
              if (alignRight) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 11, color: color),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Paid card (full-width, green) ───────────────────────────────────────────

class _PaidCard extends StatelessWidget {
  final int count;
  final double amount;
  final NumberFormat currencyFmt;
  final bool isLoading;
  final VoidCallback onTap;

  const _PaidCard({
    required this.count,
    required this.amount,
    required this.currencyFmt,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF4CAF50);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: green.withOpacity(0.13),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: count > 0
                ? green.withOpacity(0.35)
                : Colors.white.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white54, strokeWidth: 2),
                ),
              )
            : Row(
                children: [
                  // Check icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: green.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded,
                        color: green, size: 18),
                  ),
                  const SizedBox(width: 12),
                  // Labels
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pagas este mês',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          count == 0
                              ? 'Nenhuma conta paga'
                              : '$count ${count == 1 ? 'conta paga' : 'contas pagas'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Amount
                  Text(
                    count == 0 ? 'R\$ 0,00' : currencyFmt.format(amount),
                    style: TextStyle(
                      color: count == 0
                          ? Colors.white.withOpacity(0.3)
                          : green,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
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
