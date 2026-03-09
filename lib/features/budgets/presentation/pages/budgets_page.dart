import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../categories/presentation/providers/categories_provider.dart';
import '../../domain/entities/budget.dart';
import '../providers/budgets_provider.dart';
import '../../../../main.dart' show hideValuesProvider;

class BudgetsPage extends ConsumerStatefulWidget {
  const BudgetsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  late int currentMonth;
  late int currentYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentMonth = now.month;
    currentYear = now.year;
  }

  void _showCreateBudgetSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CreateBudgetSheet(
        month: currentMonth,
        year: currentYear,
      ),
    );
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
    final budgetsAsync = ref.watch(
      budgetsProvider(month: currentMonth, year: currentYear),
    );

    final hideValues = ref.watch(hideValuesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamentos'),
        actions: [
          IconButton(
            icon: Icon(
              hideValues
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              size: 20,
            ),
            onPressed: () => ref
                .read(hideValuesProvider.notifier)
                .state = !hideValues,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            budgetsProvider(month: currentMonth, year: currentYear),
          );
        },
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
            Expanded(
              child: budgetsAsync.when(
                data: (budgets) {
                  if (budgets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum orçamento',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final totalBudgeted =
                      budgets.fold<double>(0, (sum, b) => sum + b.amount);
                  final totalSpent =
                      budgets.fold<double>(0, (sum, b) => sum + b.spent);

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Summary card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Orçamento Total',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        hideValues
                                            ? 'R\$ ••••'
                                            : 'R\$ ${totalBudgeted.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Gasto',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        hideValues
                                            ? 'R\$ ••••'
                                            : 'R\$ ${totalSpent.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE53935),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: totalSpent > 0
                                      ? (totalSpent / totalBudgeted)
                                          .clamp(0.0, 1.0)
                                      : 0,
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Budget items
                      ..._buildBudgetItems(context, budgets, ref),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar orçamentos',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBudgetSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildBudgetItems(
    BuildContext context,
    List<Budget> budgets,
    WidgetRef ref,
  ) {
    return budgets.map((budget) {
      return _BudgetCard(budget: budget, ref: ref);
    }).toList();
  }
}

class _BudgetCard extends ConsumerWidget {
  final Budget budget;
  final WidgetRef ref;

  const _BudgetCard({
    required this.budget,
    required this.ref,
  });

  Color _getProgressColor(double percentage) {
    if (percentage < 70) {
      return Colors.green;
    } else if (percentage < 90) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideValues = ref.watch(hideValuesProvider);
    final categoriesAsync = ref.watch(categoriesProvider());

    return categoriesAsync.when(
      data: (categories) {
        final category = categories.firstWhere(
          (c) => c.id == budget.categoryId,
          orElse: () => categories.first,
        );

        return Dismissible(
          key: Key(budget.id),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) async {
            final success = await ref
                .read(budgetsNotifierProvider.notifier)
                .deleteBudget(budget.id);

            if (success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Orçamento removido')),
              );
            }
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red.withOpacity(0.1),
            child: const Icon(Icons.delete_outline, color: Colors.red),
          ),
          confirmDismiss: (_) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Remover orçamento?'),
                content: Text(
                  'Tem certeza que deseja remover o orçamento de ${category.name}?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Remover'),
                  ),
                ],
              ),
            );
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${budget.percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getProgressColor(budget.percentage),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Orçado',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hideValues
                                ? 'R\$ ••••'
                                : 'R\$ ${budget.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Gasto',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hideValues
                                ? 'R\$ ••••'
                                : 'R\$ ${budget.spent.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE53935),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: budget.percentage.clamp(0.0, 100.0) / 100.0,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(budget.percentage),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Erro ao carregar categoria para ${budget.categoryId}'),
        ),
      ),
    );
  }
}

class _CreateBudgetSheet extends ConsumerStatefulWidget {
  final int month;
  final int year;

  const _CreateBudgetSheet({
    required this.month,
    required this.year,
  });

  @override
  ConsumerState<_CreateBudgetSheet> createState() => _CreateBudgetSheetState();
}

class _CreateBudgetSheetState extends ConsumerState<_CreateBudgetSheet> {
  late String selectedCategoryId;
  late double amount;
  late int alertAtPercentage;
  late int selectedMonth;
  late int selectedYear;
  final amountController = TextEditingController();
  final alertController = TextEditingController(text: '80');

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.month;
    selectedYear = widget.year;
    alertAtPercentage = 80;
  }

  @override
  void dispose() {
    amountController.dispose();
    alertController.dispose();
    super.dispose();
  }

  void _selectMonth() async {
    final result = await showDatePicker(
      context: context,
      initialDate: DateTime(selectedYear, selectedMonth),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (result != null) {
      setState(() {
        selectedMonth = result.month;
        selectedYear = result.year;
      });
    }
  }

  void _submitForm() async {
    if (selectedCategoryId.isEmpty ||
        amountController.text.isEmpty ||
        double.tryParse(amountController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    final notifier = ref.read(budgetsNotifierProvider.notifier);
    final budget = await notifier.createBudget({
      'category_id': selectedCategoryId,
      'amount': double.parse(amountController.text),
      'month': selectedMonth,
      'year': selectedYear,
      'alert_at_percentage': int.parse(alertController.text),
    });

    if (mounted) {
      Navigator.pop(context);
      if (budget != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orçamento criado com sucesso')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao criar orçamento')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider());

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Novo Orçamento',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Categoria'),
          const SizedBox(height: 8),
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return const Text('Nenhuma categoria disponível');
              }
              selectedCategoryId = categories.first.id;
              return DropdownButton<String>(
                isExpanded: true,
                value: selectedCategoryId,
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedCategoryId = value;
                    });
                  }
                },
              );
            },
            loading: () =>
                const CircularProgressIndicator.adaptive(),
            error: (_, __) => const Text('Erro ao carregar categorias'),
          ),
          const SizedBox(height: 16),
          const Text('Valor do Orçamento'),
          const SizedBox(height: 8),
          TextField(
            controller: amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Ex: 1000.00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Alertar em (%)'),
          const SizedBox(height: 8),
          TextField(
            controller: alertController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ex: 80',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Mês'),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM yyyy', 'pt_BR')
                        .format(DateTime(selectedYear, selectedMonth)),
                  ),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Criar Orçamento'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
