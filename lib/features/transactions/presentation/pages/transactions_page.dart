import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';
import '../providers/transactions_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações'),
      ),
      body: _TransactionsContent(month: now.month, year: now.year),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateTransactionSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openCreateTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateTransactionSheet(),
    );
  }
}

// ─── Transactions Content ─────────────────────────────────────────────────

class _TransactionsContent extends ConsumerWidget {
  final int month;
  final int year;

  const _TransactionsContent({required this.month, required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider(month: month, year: year));

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro ao carregar transações: $e')),
      data: (response) {
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(transactionsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCards(
                totalIncome: response.totalIncome,
                totalExpense: response.totalExpense,
              ),
              const SizedBox(height: 24),
              if (response.items.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma transação',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ..._buildTransactionsList(response.items, context, ref),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTransactionsList(
    List<Transaction> transactions,
    BuildContext context,
    WidgetRef ref,
  ) {
    final grouped = <TransactionType, List<Transaction>>{};
    for (final tx in transactions) {
      grouped.putIfAbsent(tx.type, () => []).add(tx);
    }

    final widgets = <Widget>[];
    for (final type in grouped.keys) {
      widgets.add(_TypeHeader(type: type));
      widgets.add(const SizedBox(height: 8));
      for (final tx in grouped[type]!) {
        widgets.add(
          Dismissible(
            key: ValueKey(tx.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => AppFeedback.confirmDelete(
              context,
              title: 'Excluir transação?',
              subtitle: 'Esta ação não pode ser desfeita.',
            ),
            onDismissed: (_) {
              ref.read(transactionsNotifierProvider.notifier).deleteTransaction(tx.id);
              AppFeedback.showSuccess(context, 'Transação excluída.');
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
                  SizedBox(height: 4),
                  Text('Excluir', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            child: _TransactionCard(transaction: tx),
          ),
        );
        widgets.add(const SizedBox(height: 8));
      }
      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }
}

// ─── Summary Cards ────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;

  const _SummaryCards({
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final currFmt  = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
    return Row(
      children: [
        _SummaryTile(
          label: 'Receitas',
          amount: currFmt.format(totalIncome),
          icon: Icons.arrow_downward_rounded,
          color: AppTheme.incomeColor,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _SummaryTile(
          label: 'Despesas',
          amount: currFmt.format(totalExpense),
          icon: Icons.arrow_upward_rounded,
          color: AppTheme.expenseColor,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171720) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: isDark
              ? []
              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade500, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              amount,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Type Header ──────────────────────────────────────────────────────────

class _TypeHeader extends StatelessWidget {
  final TransactionType type;

  const _TypeHeader({required this.type});

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      TransactionType.income => 'Receitas',
      TransactionType.expense => 'Despesas',
      TransactionType.transfer => 'Transferências',
    };

    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Colors.grey[600],
      ),
    );
  }
}

// ─── Transaction Card ─────────────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final color      = _getTypeColor(transaction.type);
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currFmt    = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
    final prefix     = transaction.type == TransactionType.income ? '+' : '−';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171720) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            // Icon avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_getTypeIcon(transaction.type), color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // Description + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 11, color: isDark ? Colors.white38 : Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(transaction.date),
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            const SizedBox(width: 12),
            Text(
              '$prefix ${currFmt.format(transaction.amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(TransactionType type) => switch (type) {
    TransactionType.income   => AppTheme.incomeColor,
    TransactionType.expense  => AppTheme.expenseColor,
    TransactionType.transfer => const Color(0xFF29B6F6),
  };

  IconData _getTypeIcon(TransactionType type) => switch (type) {
    TransactionType.income   => Icons.arrow_downward_rounded,
    TransactionType.expense  => Icons.arrow_upward_rounded,
    TransactionType.transfer => Icons.swap_horiz_rounded,
  };
}

// ─── Create Transaction Sheet ─────────────────────────────────────────────

class CreateTransactionSheet extends ConsumerStatefulWidget {
  const CreateTransactionSheet({super.key});

  @override
  ConsumerState<CreateTransactionSheet> createState() =>
      _CreateTransactionSheetState();
}

class _CreateTransactionSheetState extends ConsumerState<CreateTransactionSheet> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nova Transação',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: 'Descrição',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: InputDecoration(
              hintText: 'Valor',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              prefixText: 'R\$ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          Text('Tipo', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButton<TransactionType>(
            value: _selectedType,
            isExpanded: true,
            items: [TransactionType.income, TransactionType.expense]
                .map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_transactionTypeLabel(type)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
              }
            },
          ),
          const SizedBox(height: 16),
          Text('Data', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Criar Transação'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _submitForm() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite a descrição')),
      );
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o valor')),
      );
      return;
    }

    final data = {
      'description': _descriptionController.text.trim(),
      'amount': double.parse(_amountController.text.trim()),
      'type': _selectedType.name,
      'date': _selectedDate.toIso8601String().substring(0, 10),
      'wallet_id': 'default', // This should be dynamic based on app state
      'is_confirmed': true,
    };

    final result = await ref.read(transactionsNotifierProvider.notifier).createTransaction(data);

    if (mounted) {
      Navigator.pop(context);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transação criada com sucesso')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao criar transação')),
        );
      }
    }
  }

  String _transactionTypeLabel(TransactionType type) {
    return switch (type) {
      TransactionType.income => 'Receita',
      TransactionType.expense => 'Despesa',
      TransactionType.transfer => 'Transferência',
    };
  }
}
