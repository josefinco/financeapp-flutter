import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/report.dart';
import '../providers/reports_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../bills/presentation/providers/bills_provider.dart';

// ─── Reports Page ─────────────────────────────────────────────────────────────

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  late int _month;
  late int _year;

  final _currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _monthFmt = DateFormat('MMMM yyyy', 'pt_BR');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year  = now.year;
  }

  void _prevMonth() => setState(() {
        _month--;
        if (_month < 1) { _month = 12; _year--; }
      });

  void _nextMonth() => setState(() {
        _month++;
        if (_month > 12) { _month = 1; _year++; }
      });

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month == now.month && _year == now.year;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final summaryAsync  = ref.watch(monthlySummaryProvider(month: _month, year: _year));
    final expensesAsync = ref.watch(expensesByCategoryProvider(month: _month, year: _year));
    final evolutionAsync = ref.watch(monthlyEvolutionProvider());
    final walletsAsync  = ref.watch(walletBalancesProvider);
    final upcomingAsync = ref.watch(upcomingBillsProvider(days: 7));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0B3D2E), Color(0xFF1B6B45), Color(0xFF1A3A5C)],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
              title: const Text('Relatórios',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: isDark ? const Color(0xFF0D0D0F) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: _prevMonth,
                      splashRadius: 20,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isCurrentMonth
                            ? null
                            : () {
                                final now = DateTime.now();
                                setState(() { _month = now.month; _year = now.year; });
                              },
                        child: Text(
                          _monthFmt.format(DateTime(_year, _month)),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: _isCurrentMonth
                                ? AppTheme.incomeColor
                                : (isDark ? Colors.white : const Color(0xFF1B2B3A)),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _nextMonth,
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: RefreshIndicator(
          color: AppTheme.incomeColor,
          onRefresh: () async {
            ref.invalidate(monthlySummaryProvider);
            ref.invalidate(expensesByCategoryProvider);
            ref.invalidate(monthlyEvolutionProvider);
            ref.invalidate(walletBalancesProvider);
            ref.invalidate(upcomingBillsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // ── 1. Resumo Financeiro ───────────────────────────────────────
              _SectionHeader(icon: Icons.account_balance_wallet_rounded, title: 'Resumo Financeiro'),
              const SizedBox(height: 10),
              summaryAsync.when(
                loading: () => const _LoadingCard(),
                error: (e, _) => _ErrorCard('Erro ao carregar resumo'),
                data: (s) => _FinancialSummaryCard(summary: s, currFmt: _currFmt),
              ),
              const SizedBox(height: 24),

              // ── 2. Situação das Contas ─────────────────────────────────────
              _SectionHeader(icon: Icons.receipt_long_rounded, title: 'Situação das Contas'),
              const SizedBox(height: 10),
              summaryAsync.when(
                loading: () => const _LoadingCard(),
                error: (e, _) => _ErrorCard('Erro ao carregar contas'),
                data: (s) => _BillsStatusCard(summary: s, currFmt: _currFmt),
              ),
              const SizedBox(height: 24),

              // ── 3. Próximos Vencimentos (7 dias) ──────────────────────────
              _SectionHeader(icon: Icons.upcoming_rounded, title: 'Próximos Vencimentos'),
              const SizedBox(height: 10),
              upcomingAsync.when(
                loading: () => const _LoadingCard(),
                error: (e, _) => _ErrorCard('Erro ao carregar vencimentos'),
                data: (bills) => _UpcomingBillsCard(bills: bills, currFmt: _currFmt),
              ),
              const SizedBox(height: 24),

              // ── 4. Gastos por Categoria ───────────────────────────────────
              _SectionHeader(icon: Icons.pie_chart_rounded, title: 'Gastos por Categoria'),
              const SizedBox(height: 10),
              expensesAsync.when(
                loading: () => const _LoadingCard(),
                error: (e, _) => _ErrorCard('Erro ao carregar categorias'),
                data: (r) => _CategoryExpensesCard(response: r, currFmt: _currFmt),
              ),
              const SizedBox(height: 24),

              // ── 5. Evolução dos Últimos 6 Meses ───────────────────────────
              _SectionHeader(icon: Icons.bar_chart_rounded, title: 'Evolução — Últimos 6 Meses'),
              const SizedBox(height: 10),
              evolutionAsync.when(
                loading: () => const _LoadingCard(),
                error: (e, _) => _ErrorCard('Erro ao carregar evolução'),
                data: (r) => _MonthlyEvolutionCard(months: r.months, currFmt: _currFmt),
              ),
              const SizedBox(height: 24),

              // ── 6. Carteiras ──────────────────────────────────────────────
              _SectionHeader(icon: Icons.account_balance_rounded, title: 'Carteiras'),
              const SizedBox(height: 10),
              walletsAsync.when(
                loading: () => const _LoadingCard(),
                error: (e, _) => _ErrorCard('Erro ao carregar carteiras'),
                data: (r) => _WalletsCard(data: r, currFmt: _currFmt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.incomeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppTheme.incomeColor),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800, letterSpacing: -0.2)),
      ],
    );
  }
}

// ─── Base Card ────────────────────────────────────────────────────────────────

class _BaseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _BaseCard({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171720) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? const Color(0xFF232333) : const Color(0xFFE8EBF0)),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

// ─── 1. Financial Summary Card ────────────────────────────────────────────────

class _FinancialSummaryCard extends StatelessWidget {
  final MonthlySummary summary;
  final NumberFormat currFmt;
  const _FinancialSummaryCard({required this.summary, required this.currFmt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final savingsRate = summary.totalIncome > 0
        ? ((summary.totalIncome - summary.totalExpense) / summary.totalIncome * 100)
            .clamp(0.0, 100.0)
        : 0.0;
    final balancePositive = summary.balance >= 0;

    return _BaseCard(
      child: Column(
        children: [
          // Top row: Income + Expense
          Row(
            children: [
              _MetricTile(
                icon: Icons.arrow_downward_rounded,
                iconColor: AppTheme.incomeColor,
                label: 'Receitas',
                value: currFmt.format(summary.totalIncome),
                valueColor: AppTheme.incomeColor,
              ),
              const SizedBox(width: 12),
              _MetricTile(
                icon: Icons.arrow_upward_rounded,
                iconColor: AppTheme.errorColor,
                label: 'Despesas',
                value: currFmt.format(summary.totalExpense),
                valueColor: AppTheme.errorColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom row: Balance + Savings rate
          Row(
            children: [
              _MetricTile(
                icon: balancePositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                iconColor: balancePositive ? AppTheme.incomeColor : AppTheme.errorColor,
                label: 'Saldo',
                value: currFmt.format(summary.balance),
                valueColor: balancePositive ? AppTheme.incomeColor : AppTheme.errorColor,
              ),
              const SizedBox(width: 12),
              // Savings rate with mini arc
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF29B6F6).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF29B6F6).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: Stack(
                          children: [
                            CircularProgressIndicator(
                              value: savingsRate / 100,
                              strokeWidth: 4,
                              backgroundColor: isDark
                                  ? Colors.white12
                                  : const Color(0xFF29B6F6).withOpacity(0.15),
                              valueColor: const AlwaysStoppedAnimation(Color(0xFF29B6F6)),
                            ),
                            Center(
                              child: Text(
                                '${savingsRate.round()}%',
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF29B6F6)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Taxa de',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white38 : Colors.grey)),
                          const Text('Economia',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF29B6F6))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: iconColor.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.grey)),
                  Text(value,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: valueColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 2. Bills Status Card ─────────────────────────────────────────────────────

class _BillsStatusCard extends StatelessWidget {
  final MonthlySummary summary;
  final NumberFormat currFmt;
  const _BillsStatusCard({required this.summary, required this.currFmt});

  @override
  Widget build(BuildContext context) {
    final total = summary.pendingBills + summary.overdueBills;
    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (total == 0)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.incomeColor, size: 20),
                const SizedBox(width: 8),
                Text('Todas as contas do mês pagas!',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.incomeColor)),
              ],
            )
          else ...[
            Row(
              children: [
                _BillsStatusTile(
                  label: 'Pendentes',
                  count: summary.pendingBills,
                  color: AppTheme.pendingColor,
                  icon: Icons.hourglass_top_rounded,
                ),
                const SizedBox(width: 12),
                _BillsStatusTile(
                  label: 'Vencidas',
                  count: summary.overdueBills,
                  color: AppTheme.errorColor,
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: summary.pendingBills / total,
                  minHeight: 6,
                  backgroundColor: AppTheme.errorColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(AppTheme.pendingColor),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$total conta${total == 1 ? '' : 's'} aguardando pagamento',
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white38
                        : Colors.grey),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _BillsStatusTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _BillsStatusTile({
    required this.label, required this.count,
    required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900, color: color)),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color.withOpacity(0.8))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 3. Upcoming Bills Card ───────────────────────────────────────────────────

class _UpcomingBillsCard extends StatelessWidget {
  final List bills;
  final NumberFormat currFmt;
  const _UpcomingBillsCard({required this.bills, required this.currFmt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (bills.isEmpty) {
      return _BaseCard(
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AppTheme.incomeColor, size: 20),
            const SizedBox(width: 10),
            Text('Nenhum vencimento nos próximos 7 dias',
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey)),
          ],
        ),
      );
    }

    return _BaseCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: bills.asMap().entries.map((entry) {
          final i    = entry.key;
          final bill = entry.value;
          final today = DateTime.now();
          final diff  = bill.dueDate.difference(DateTime(today.year, today.month, today.day)).inDays;
          final diffLabel = diff == 0 ? 'Hoje!' : 'Em $diff dias';
          final diffColor = diff == 0 ? AppTheme.errorColor : (diff <= 3 ? AppTheme.pendingColor : AppTheme.incomeColor);

          return Container(
            decoration: BoxDecoration(
              border: i < bills.length - 1
                  ? Border(
                      bottom: BorderSide(
                          color: isDark ? const Color(0xFF232333) : const Color(0xFFE8EBF0)))
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: diffColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(diffLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: diffColor)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(bill.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text(currFmt.format(bill.amount),
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppTheme.pendingColor)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── 4. Category Expenses Card ────────────────────────────────────────────────

class _CategoryExpensesCard extends StatelessWidget {
  final ExpenseByCategoryResponse response;
  final NumberFormat currFmt;
  const _CategoryExpensesCard({required this.response, required this.currFmt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (response.categories.isEmpty) {
      return _BaseCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Sem despesas neste período',
                style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
          ),
        ),
      );
    }

    final colors = response.categories.map((c) => _hexColor(c.categoryColor)).toList();

    return _BaseCard(
      child: Column(
        children: [
          // Pie chart
          Row(
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: PieChart(
                  PieChartData(
                    sections: response.categories.asMap().entries.map((e) {
                      final pct   = e.value.percentage;
                      final color = colors[e.key];
                      return PieChartSectionData(
                        value: pct,
                        title: pct >= 8 ? '${pct.round()}%' : '',
                        titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                        color: color,
                        radius: 50,
                        borderSide: BorderSide(
                            color: isDark ? const Color(0xFF171720) : Colors.white,
                            width: 2),
                      );
                    }).toList(),
                    centerSpaceRadius: 32,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: response.categories.asMap().entries.take(5).map((e) {
                    final cat   = e.value;
                    final color = colors[e.key];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(cat.categoryName,
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text('${cat.percentage.round()}%',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Detail bars
          ...response.categories.map((cat) {
            final color = _hexColor(cat.categoryColor);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(width: 8, height: 8,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(cat.categoryName,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                      Text(currFmt.format(cat.amount),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (cat.percentage / 100).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor:
                          isDark ? Colors.white12 : Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _hexColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xff'))); }
    catch (_) { return Colors.grey; }
  }
}

// ─── 5. Monthly Evolution Card ────────────────────────────────────────────────

class _MonthlyEvolutionCard extends StatelessWidget {
  final List<MonthlySummary> months;
  final NumberFormat currFmt;
  const _MonthlyEvolutionCard({required this.months, required this.currFmt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (months.isEmpty) {
      return _BaseCard(
        child: Center(
          child: Text('Sem dados disponíveis',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
        ),
      );
    }

    final maxValue = months.fold<double>(0, (m, s) {
      final v = s.totalIncome > s.totalExpense ? s.totalIncome : s.totalExpense;
      return v > m ? v : m;
    });

    if (maxValue == 0) {
      return _BaseCard(
        child: Center(
          child: Text('Sem movimentações no período',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
        ),
      );
    }

    final barGroups = months.asMap().entries.map((e) {
      final s = e.value;
      return BarChartGroupData(
        x: e.key,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: s.totalIncome,
            color: AppTheme.incomeColor,
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: s.totalExpense,
            color: AppTheme.errorColor,
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.15,
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= months.length) return const SizedBox.shrink();
                        final m = months[i];
                        return Text(
                          DateFormat('MMM', 'pt_BR')
                              .format(DateTime(m.year, m.month))
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0 ? 'Receita' : 'Despesa';
                      return BarTooltipItem(
                        '$label\n${currFmt.format(rod.toY)}',
                        TextStyle(
                          color: rod.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppTheme.incomeColor, label: 'Receitas'),
              const SizedBox(width: 20),
              _LegendDot(color: AppTheme.errorColor, label: 'Despesas'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      );
}

// ─── 6. Wallets Card ─────────────────────────────────────────────────────────

class _WalletsCard extends StatelessWidget {
  final WalletBalancesData data;
  final NumberFormat currFmt;
  const _WalletsCard({required this.data, required this.currFmt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (data.wallets.isEmpty) {
      return _BaseCard(
        child: Center(
          child: Text('Nenhuma carteira cadastrada',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
        ),
      );
    }

    return _BaseCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // Total
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Saldo Total',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey)),
                Text(currFmt.format(data.totalBalance),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: data.totalBalance >= 0
                            ? AppTheme.incomeColor
                            : AppTheme.errorColor)),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF232333) : const Color(0xFFE8EBF0)),
          ...data.wallets.asMap().entries.map((e) {
            final wallet = e.value;
            final i      = e.key;
            final color  = _hexColor(wallet.color);
            final typeIcon = switch (wallet.walletType) {
              'checking'    => Icons.account_balance_rounded,
              'savings'     => Icons.savings_rounded,
              'credit_card' => Icons.credit_card_rounded,
              'investment'  => Icons.trending_up_rounded,
              _             => Icons.wallet_rounded,
            };

            return Container(
              decoration: BoxDecoration(
                border: i < data.wallets.length - 1
                    ? Border(
                        bottom: BorderSide(
                            color: isDark
                                ? const Color(0xFF232333)
                                : const Color(0xFFE8EBF0)))
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(typeIcon, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(wallet.walletName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    Text(currFmt.format(wallet.balance),
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: wallet.balance >= 0
                                ? AppTheme.incomeColor
                                : AppTheme.errorColor)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _hexColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xff'))); }
    catch (_) { return Colors.grey; }
  }
}

// ─── Loading & Error ──────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => _BaseCard(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator.adaptive(),
          ),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard(this.message);

  @override
  Widget build(BuildContext context) => _BaseCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppTheme.errorColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(message,
                      style: const TextStyle(color: AppTheme.errorColor))),
            ],
          ),
        ),
      );
}
