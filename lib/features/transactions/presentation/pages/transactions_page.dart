import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';
import '../providers/transactions_provider.dart';
import '../../../../core/theme/app_theme.dart';

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
            onDismissed: (_) {
              ref.read(transactionsNotifierProvider.notifier).deleteTransaction(tx.id);
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
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
    return Row(
      children: [
        Expanded(
          child: Card(
            color: Colors.green.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receita',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${totalIncome.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            color: Colors.red.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Despesa',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${totalExpense.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
    final color = _getTypeColor(transaction.type);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _getTypeIcon(transaction.type),
                  color: color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(transaction.date),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${transaction.type == TransactionType.income ? '+' : '-'}R\$ ${transaction.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(TransactionType type) {
    return switch (type) {
      TransactionType.income => Colors.green,
      TransactionType.expense => Colors.red,
      TransactionType.transfer => Colors.blue,
    };
  }

  IconData _getTypeIcon(TransactionType type) {
    return switch (type) {
      TransactionType.income => Icons.add_circle_outline,
      TransactionType.expense => Icons.remove_circle_outline,
      TransactionType.transfer => Icons.swap_horiz,
    };
  }
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
