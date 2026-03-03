import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';
import '../providers/transactions_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../reports/presentation/providers/reports_provider.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  void _prevMonth() => setState(() {
        _month--;
        if (_month < 1) {
          _month = 12;
          _year--;
        }
      });

  void _nextMonth() => setState(() {
        _month++;
        if (_month > 12) {
          _month = 1;
          _year++;
        }
      });

  void _goToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _month = now.month;
      _year = now.year;
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month == now.month && _year == now.year;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactionsAsync =
        ref.watch(transactionsProvider(month: _month, year: _year));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: _GradientFab(
        onTap: () => _openCreateSheet(context),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          // ── Sticky month nav ─────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            toolbarHeight: 0,
            expandedHeight: 0,
            backgroundColor: isDark ? const Color(0xFF0D0D0F) : Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            // ── Month navigation ─────────────────────────────────────────
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Container(
                color: isDark ? const Color(0xFF0D0D0F) : Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: _prevMonth,
                      splashRadius: 20,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _goToCurrentMonth,
                        child: Column(
                          children: [
                            Text(
                              DateFormat('MMMM', 'pt_BR')
                                  .format(DateTime(_year, _month))
                                  .toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                letterSpacing: 1.2,
                                color: _isCurrentMonth
                                    ? AppTheme.incomeColor
                                    : (isDark
                                        ? Colors.white
                                        : const Color(0xFF1B2B3A)),
                              ),
                            ),
                            Text(
                              '$_year',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
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
        body: _TransactionsBody(
          transactionsAsync: transactionsAsync,
          month: _month,
          year: _year,
          onRefresh: () => ref.invalidate(transactionsProvider),
        ),
      ),
    );
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateTransactionSheet(),
    );
  }
}

// ─── Transactions Body ────────────────────────────────────────────────────────

class _TransactionsBody extends ConsumerWidget {
  final AsyncValue<dynamic> transactionsAsync;
  final int month;
  final int year;
  final VoidCallback onRefresh;

  const _TransactionsBody({
    required this.transactionsAsync,
    required this.month,
    required this.year,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 12),
              Text('Erro: $e', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      data: (response) {
        final transactions = response.items as List<Transaction>;

        return RefreshIndicator(
          color: AppTheme.incomeColor,
          onRefresh: () async => onRefresh(),
          child: CustomScrollView(
            slivers: [
              // ── Summary cards ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: _SummaryCards(
                    totalIncome: (response.totalIncome as num).toDouble(),
                    totalExpense: (response.totalExpense as num).toDouble(),
                    currFmt: currFmt,
                  ),
                ),
              ),

              // ── Empty state ────────────────────────────────────────────
              if (transactions.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState(month: month, year: year),
                )
              else ...[
                ..._buildGroupedSliver(transactions, context, ref, currFmt),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildGroupedSliver(
    List<Transaction> transactions,
    BuildContext context,
    WidgetRef ref,
    NumberFormat currFmt,
  ) {
    // Sort by date descending
    final sorted = [...transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    // Group by day
    final groups = <DateTime, List<Transaction>>{};
    for (final tx in sorted) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      groups.putIfAbsent(day, () => []).add(tx);
    }

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    final widgets = <Widget>[];
    for (final day in groups.keys) {
      widgets.add(
        SliverToBoxAdapter(
          child: _DateHeader(date: day, today: todayKey),
        ),
      );
      widgets.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: groups[day]!.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final tx = groups[day]![i];
              return Dismissible(
                key: ValueKey(tx.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => AppFeedback.confirmDelete(
                  context,
                  title: 'Excluir lançamento?',
                  subtitle: 'Esta ação não pode ser desfeita.',
                ),
                onDismissed: (_) {
                  ref
                      .read(transactionsNotifierProvider.notifier)
                      .deleteTransaction(tx.id);
                  AppFeedback.showSuccess(context, 'Lançamento excluído.');
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
                      Icon(Icons.delete_outline_rounded,
                          color: Colors.white, size: 24),
                      SizedBox(height: 4),
                      Text('Excluir',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                child: _TransactionCard(transaction: tx, currFmt: currFmt),
              );
            },
          ),
        ),
      );
      widgets.add(const SliverToBoxAdapter(child: SizedBox(height: 4)));
    }
    return widgets;
  }
}

// ─── Date Header ──────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final DateTime today;

  const _DateHeader({required this.date, required this.today});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final yesterday = today.subtract(const Duration(days: 1));

    String label;
    if (date == today) {
      label = 'Hoje';
    } else if (date == yesterday) {
      label = 'Ontem';
    } else if (today.difference(date).inDays < 7) {
      label = _cap(DateFormat('EEEE', 'pt_BR').format(date));
    } else if (date.year == today.year) {
      label = DateFormat("d 'de' MMM", 'pt_BR').format(date);
    } else {
      label = DateFormat("d 'de' MMM 'de' yyyy", 'pt_BR').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF1B2B3A),
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              thickness: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
        ],
      ),
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Summary Cards ────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final NumberFormat currFmt;

  const _SummaryCards({
    required this.totalIncome,
    required this.totalExpense,
    required this.currFmt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balance = totalIncome - totalExpense;

    return Row(
      children: [
        _SummaryTile(
          label: 'Receitas',
          amount: currFmt.format(totalIncome),
          icon: Icons.arrow_downward_rounded,
          color: AppTheme.incomeColor,
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _SummaryTile(
          label: 'Despesas',
          amount: currFmt.format(totalExpense),
          icon: Icons.arrow_upward_rounded,
          color: AppTheme.expenseColor,
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _SummaryTile(
          label: 'Saldo',
          amount: currFmt.format(balance),
          icon: balance >= 0
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          color: balance >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171720) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.18)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 13),
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                  fontWeight: FontWeight.w500),
          ),
          ],
        ),
      ),
    );
  }
}

// ─── Transaction Card ─────────────────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final NumberFormat currFmt;

  const _TransactionCard({required this.transaction, required this.currFmt});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(transaction.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefix = transaction.type == TransactionType.income ? '+' : '−';

    return Ink(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171720) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child:
                  Icon(_typeIcon(transaction.type), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            // Description + chip
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _TypeChip(type: transaction.type),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Amount
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

  Color _typeColor(TransactionType t) => switch (t) {
        TransactionType.income => AppTheme.incomeColor,
        TransactionType.expense => AppTheme.expenseColor,
        TransactionType.transfer => const Color(0xFF29B6F6),
      };

  IconData _typeIcon(TransactionType t) => switch (t) {
        TransactionType.income => Icons.arrow_downward_rounded,
        TransactionType.expense => Icons.arrow_upward_rounded,
        TransactionType.transfer => Icons.swap_horiz_rounded,
      };
}

// ─── Type Chip ────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final TransactionType type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      TransactionType.income => ('Receita', AppTheme.incomeColor),
      TransactionType.expense => ('Despesa', AppTheme.expenseColor),
      TransactionType.transfer =>
        ('Transferência', const Color(0xFF29B6F6)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final int month;
  final int year;

  const _EmptyState({required this.month, required this.year});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthLabel =
        DateFormat('MMMM', 'pt_BR').format(DateTime(year, month));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171720) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppTheme.incomeColor.withOpacity(0.15)),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.incomeColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    size: 32, color: AppTheme.incomeColor),
              ),
              const SizedBox(height: 14),
              Text('Sem lançamentos',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'Nenhum lançamento em $monthLabel',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Create Transaction Sheet ─────────────────────────────────────────────────

class CreateTransactionSheet extends ConsumerStatefulWidget {
  const CreateTransactionSheet({super.key});

  @override
  ConsumerState<CreateTransactionSheet> createState() =>
      _CreateTransactionSheetState();
}

class _CreateTransactionSheetState
    extends ConsumerState<CreateTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  String? _categoryId;
  String? _walletId;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final rawAmount = _amountController.text.trim();
    double amount = 0.0;
    if (rawAmount.contains(',') && rawAmount.contains('.')) {
      amount = double.tryParse(
              rawAmount.replaceAll('.', '').replaceAll(',', '.')) ??
          0.0;
    } else {
      amount = double.tryParse(rawAmount.replaceAll(',', '.')) ?? 0.0;
    }

    if (amount <= 0) {
      AppFeedback.showError(context, 'Informe um valor válido maior que zero.');
      return;
    }

    final data = <String, dynamic>{
      'description': _descriptionController.text.trim(),
      'amount': amount,
      'type': _type.name,
      'date': DateFormat('yyyy-MM-dd').format(_date),
      'is_confirmed': true,
      if (_walletId != null) 'wallet_id': _walletId,
      if (_categoryId != null) 'category_id': _categoryId,
    };

    final result = await ref
        .read(transactionsNotifierProvider.notifier)
        .createTransaction(data);

    if (mounted) {
      if (result != null) {
        Navigator.pop(context);
        AppFeedback.showSuccess(context, 'Lançamento criado com sucesso!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider());
    final walletsAsync = ref.watch(walletBalancesProvider);
    final actionState = ref.watch(transactionsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.96,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(
                24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Novo Lançamento',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 24),

              // ── Type selector (pill tabs) ──────────────────────────────
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0D0D0F)
                      : const Color(0xFFF2F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _TypePill(
                      type: TransactionType.expense,
                      selected: _type == TransactionType.expense,
                      onTap: () =>
                          setState(() => _type = TransactionType.expense),
                    ),
                    _TypePill(
                      type: TransactionType.income,
                      selected: _type == TransactionType.income,
                      onTap: () =>
                          setState(() => _type = TransactionType.income),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Description ───────────────────────────────────────────
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descrição *',
                  hintText: 'Ex: Supermercado, Salário...',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe a descrição'
                    : null,
              ),
              const SizedBox(height: 14),

              // ── Amount ────────────────────────────────────────────────
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Valor *',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  prefixText: 'R\$ ',
                  hintText: '0,00',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o valor';
                  final p = double.tryParse(v.trim().replaceAll(',', '.'));
                  if (p == null || p <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── Date ──────────────────────────────────────────────────
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data *',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(dateFmt.format(_date)),
                ),
              ),
              const SizedBox(height: 14),

              // ── Wallet selector ───────────────────────────────────────
              walletsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (walletsData) {
                  final wallets = walletsData.wallets;
                  if (wallets.isEmpty) return const SizedBox.shrink();
                  if (_walletId == null && wallets.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _walletId = wallets.first.walletId);
                      }
                    });
                  }
                  return DropdownButtonFormField<String>(
                    value: _walletId,
                    decoration: const InputDecoration(
                      labelText: 'Carteira',
                      prefixIcon:
                          Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: wallets
                        .map((w) => DropdownMenuItem(
                              value: w.walletId,
                              child: Row(children: [
                                Icon(_walletIcon(w.walletType),
                                    size: 16, color: AppTheme.incomeColor),
                                const SizedBox(width: 8),
                                Expanded(child: Text(w.walletName, overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 8),
                                Text(
                                  NumberFormat.currency(
                                          locale: 'pt_BR', symbol: 'R\$')
                                      .format(w.balance),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey.shade500),
                                ),
                              ]),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _walletId = v),
                  );
                },
              ),
              const SizedBox(height: 14),

              // ── Category ──────────────────────────────────────────────
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (cats) => DropdownButtonFormField<String>(
                  value: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Sem categoria')),
                    ...cats.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                  color: _hexColor(c.color),
                                  shape: BoxShape.circle),
                            ),
                            Text(c.name),
                          ]),
                        )),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ),
              const SizedBox(height: 28),

              // ── Buttons ───────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: actionState.isLoading
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF1B6B45), Color(0xFF2196F3)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: actionState.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: actionState.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded,
                              color: Colors.white),
                      label: Text(
                        actionState.isLoading
                            ? 'Salvando...'
                            : 'Salvar Lançamento',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  IconData _walletIcon(String type) => switch (type.toLowerCase()) {
        'checking' || 'corrente' => Icons.account_balance_outlined,
        'savings' || 'poupanca' || 'poupança' => Icons.savings_outlined,
        'investment' || 'investimento' => Icons.trending_up_rounded,
        _ => Icons.account_balance_wallet_outlined,
      };

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}

// ─── Type Pill ────────────────────────────────────────────────────────────────

class _TypePill extends StatelessWidget {
  final TransactionType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypePill(
      {required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = switch (type) {
      TransactionType.income => AppTheme.incomeColor,
      TransactionType.expense => AppTheme.expenseColor,
      TransactionType.transfer => const Color(0xFF29B6F6),
    };
    final label = switch (type) {
      TransactionType.income => 'Receita',
      TransactionType.expense => 'Despesa',
      TransactionType.transfer => 'Transferência',
    };

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == TransactionType.income
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 13,
                color: selected
                    ? color
                    : (isDark ? Colors.white38 : Colors.grey.shade400),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? color
                      : (isDark ? Colors.white38 : Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Gradient FAB ─────────────────────────────────────────────────────────────

class _GradientFab extends StatelessWidget {
  final VoidCallback onTap;
  const _GradientFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B6B45), Color(0xFF1A3A5C)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B6B45).withOpacity(0.45),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
