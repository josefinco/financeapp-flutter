import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/report.dart';
import '../providers/reports_provider.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  late int currentMonth;
  late int currentYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentMonth = now.month;
    currentYear = now.year;
  }

  void _previousMonth() {
    setState(() {
      currentMonth--;
      if (currentMonth < 1) {
        currentMonth = 12;
        currentYear--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      currentMonth++;
      if (currentMonth > 12) {
        currentMonth = 1;
        currentYear++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(
      monthlySummaryProvider(month: currentMonth, year: currentYear),
    );
    final expensesAsync = ref.watch(
      expensesByCategoryProvider(month: currentMonth, year: currentYear),
    );
    final evolutionAsync = ref.watch(monthlyEvolutionProvider());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            monthlySummaryProvider(month: currentMonth, year: currentYear),
          );
          ref.invalidate(
            expensesByCategoryProvider(month: currentMonth, year: currentYear),
          );
          ref.invalidate(monthlyEvolutionProvider());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Month selector
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: Colors.grey.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _previousMonth,
                    ),
                    Text(
                      DateFormat('MMMM yyyy', 'pt_BR').format(
                        DateTime(currentYear, currentMonth),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Monthly Summary
                    Text(
                      'Resumo do Mês',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    summaryAsync.when(
                      data: (summary) => _buildSummaryCard(summary),
                      loading: () => const _LoadingCard(),
                      error: (error, stack) => _buildErrorCard(
                        'Erro ao carregar resumo',
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Section 2: Expenses by Category
                    Text(
                      'Gastos por Categoria',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    expensesAsync.when(
                      data: (response) =>
                          _buildCategoryExpenses(response.categories),
                      loading: () => const _LoadingCard(),
                      error: (error, stack) => _buildErrorCard(
                        'Erro ao carregar gastos',
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Section 3: Monthly Evolution
                    Text(
                      'Evolução Mensal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    evolutionAsync.when(
                      data: (response) => _buildMonthlyEvolution(response.months),
                      loading: () => const _LoadingCard(),
                      error: (error, stack) => _buildErrorCard(
                        'Erro ao carregar evolução',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(MonthlySummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Receita',
                  summary.totalIncome,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Despesa',
                  summary.totalExpense,
                  Colors.red,
                ),
                _buildSummaryItem(
                  'Saldo',
                  summary.balance,
                  Colors.blue,
                ),
              ],
            ),
            if (summary.pendingBills > 0 || summary.overdueBills > 0) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusItem(
                    'Pendentes',
                    summary.pendingBills.toString(),
                    Colors.orange,
                  ),
                  _buildStatusItem(
                    'Vencidas',
                    summary.overdueBills.toString(),
                    Colors.red,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryExpenses(List<CategoryExpense> categories) {
    if (categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'Sem gastos neste período',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    return Column(
      children: categories.map((expense) {
        final color = _hexToColor(expense.categoryColor);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.categoryName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'R\$ ${expense.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${expense.percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (expense.percentage / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyEvolution(List<MonthlySummary> months) {
    if (months.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'Sem dados disponíveis',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    // Find max value for scaling
    final maxValue = months.fold<double>(
      0,
      (max, m) => max > m.totalIncome || max > m.totalExpense ? max : m.totalIncome > m.totalExpense ? m.totalIncome : m.totalExpense,
    );

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: months.map((month) {
              final incomeHeight =
                  (month.totalIncome / maxValue * 200).clamp(0.0, 200.0);
              final expenseHeight =
                  (month.totalExpense / maxValue * 200).clamp(0.0, 200.0);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('MMM', 'pt_BR')
                            .format(DateTime(month.year, month.month)),
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: incomeHeight,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 2),
                          Container(
                            width: 6,
                            height: expenseHeight,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Receita', Colors.green),
            const SizedBox(width: 24),
            _buildLegendItem('Despesa', Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 32,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hexString) {
    try {
      return Color(int.parse(hexString.replaceFirst('#', '0xff')));
    } catch (_) {
      return Colors.grey;
    }
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      ),
    );
  }
}
