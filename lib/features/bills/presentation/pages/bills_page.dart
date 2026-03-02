import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/bill.dart';
import '../providers/bills_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../categories/presentation/providers/categories_provider.dart';

class BillsPage extends ConsumerStatefulWidget {
  const BillsPage({super.key});

  @override
  ConsumerState<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends ConsumerState<BillsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas a Pagar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendentes'),
            Tab(text: 'Vencidas'),
            Tab(text: 'Pagas'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openCreateBillSheet(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BillsList(status: BillStatus.pending),
          _BillsList(status: BillStatus.overdue),
          _BillsList(status: BillStatus.paid),
        ],
      ),
    );
  }

  void _openCreateBillSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateBillSheet(),
    );
  }
}

// ─── Bills List ───────────────────────────────────────────────────────────────

class _BillsList extends ConsumerWidget {
  final BillStatus status;

  const _BillsList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final billsAsync = ref.watch(billsProvider(status: status, month: now.month, year: now.year));

    return billsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro ao carregar contas: $e')),
      data: (response) {
        final bills = response.items;
        if (bills.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma conta ${_statusLabel(status)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(billsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => BillCard(bill: bills[i]),
          ),
        );
      },
    );
  }

  String _statusLabel(BillStatus s) => switch (s) {
        BillStatus.pending => 'pendente',
        BillStatus.overdue => 'vencida',
        BillStatus.paid => 'paga',
        BillStatus.cancelled => 'cancelada',
      };
}

// ─── Bill Card ────────────────────────────────────────────────────────────────

class BillCard extends ConsumerWidget {
  final Bill bill;

  const BillCard({super.key, required this.bill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt     = DateFormat('dd/MM/yyyy');
    final color       = _statusColor(bill.status);
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final isPaid      = bill.status == BillStatus.paid;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showDetails(context, ref),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171720) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(isPaid ? 0.1 : 0.2), width: 1),
            boxShadow: isDark
                ? []
                : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // ── Icon avatar ─────────────────────────────────────────
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_statusIcon(bill.status), color: color, size: 22),
                ),
                const SizedBox(width: 14),

                // ── Main content ─────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              decoration: isPaid ? TextDecoration.lineThrough : null,
                              decorationColor: color,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFmt.format(bill.dueDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(status: bill.status),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Amount ────────────────────────────────────────────────
                const SizedBox(width: 12),
                Text(
                  currencyFmt.format(bill.amount),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isPaid
                        ? (isDark ? Colors.white30 : Colors.grey.shade400)
                        : color,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(BillStatus s) => switch (s) {
        BillStatus.pending   => AppTheme.pendingColor,
        BillStatus.overdue   => AppTheme.overdueColor,
        BillStatus.paid      => AppTheme.paidColor,
        BillStatus.cancelled => Colors.grey,
      };

  IconData _statusIcon(BillStatus s) => switch (s) {
        BillStatus.pending   => Icons.hourglass_top_rounded,
        BillStatus.overdue   => Icons.warning_amber_rounded,
        BillStatus.paid      => Icons.check_circle_rounded,
        BillStatus.cancelled => Icons.cancel_outlined,
      };

  void _showDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BillDetailsSheet(bill: bill),
    );
  }
}

// ─── Status Chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final BillStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BillStatus.pending => ('Pendente', AppTheme.pendingColor),
      BillStatus.overdue => ('Vencida', AppTheme.overdueColor),
      BillStatus.paid => ('Paga', AppTheme.paidColor),
      BillStatus.cancelled => ('Cancelada', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Bill Details Sheet ───────────────────────────────────────────────────────

class BillDetailsSheet extends ConsumerWidget {
  final Bill bill;

  const BillDetailsSheet({super.key, required this.bill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final notifier = ref.watch(billsNotifierProvider.notifier);
    final actionState = ref.watch(billsNotifierProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(bill.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(currencyFmt.format(bill.amount), style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.expenseColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _DetailRow(icon: Icons.calendar_today, label: 'Vencimento', value: DateFormat('dd/MM/yyyy').format(bill.dueDate)),
            if (bill.paidDate != null)
              _DetailRow(icon: Icons.check_circle, label: 'Pago em', value: DateFormat('dd/MM/yyyy').format(bill.paidDate!)),
            if (bill.notes != null && bill.notes!.isNotEmpty)
              _DetailRow(icon: Icons.notes, label: 'Observações', value: bill.notes!),
            const Spacer(),
            if (bill.status != BillStatus.paid)
              ElevatedButton.icon(
                onPressed: actionState.isLoading
                    ? null
                    : () async {
                        final paid = await notifier.markPaid(bill.id);
                        if (paid != null && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Conta marcada como paga! ✅'), backgroundColor: AppTheme.paidColor),
                          );
                        }
                      },
                icon: actionState.isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
                label: Text(actionState.isLoading ? 'Processando...' : 'Marcar como Pago'),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

// ─── Create Bill Sheet ────────────────────────────────────────────────────────

class CreateBillSheet extends ConsumerStatefulWidget {
  const CreateBillSheet({super.key});

  @override
  ConsumerState<CreateBillSheet> createState() => _CreateBillSheetState();
}

class _CreateBillSheetState extends ConsumerState<CreateBillSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _installmentsController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  String? _categoryId;
  RecurrenceType _recurrence = RecurrenceType.none;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _installmentsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Parse amount: strip currency symbols, convert comma → dot
    final raw = _amountController.text
        .replaceAll(RegExp(r'[^\d,]'), '')
        .replaceAll(',', '.');
    final amount = double.tryParse(raw) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor válido')),
      );
      return;
    }

    final installments = int.tryParse(_installmentsController.text.trim());

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'amount': amount,
      'due_date': DateFormat('yyyy-MM-dd').format(_dueDate),
      'recurrence': _recurrence.name,
      if (_categoryId != null) 'category_id': _categoryId,
      if (_notesController.text.trim().isNotEmpty)
        'notes': _notesController.text.trim(),
      if (_recurrence == RecurrenceType.none &&
          installments != null &&
          installments > 1)
        'total_installments': installments,
    };

    final bill = await ref.read(billsNotifierProvider.notifier).createBill(data);
    if (bill != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conta "${bill.name}" criada! ✅'),
          backgroundColor: AppTheme.paidColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider());
    final actionState = ref.watch(billsNotifierProvider);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      maxChildSize: 0.96,
      builder: (_, controller) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: controller,
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nova Conta',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // ── Nome ─────────────────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nome da conta *',
                  hintText: 'Ex: Aluguel, Luz, Internet',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),

              // ── Valor ────────────────────────────────────────────────────
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  CurrencyTextInputFormatter.currency(
                    locale: 'pt_BR',
                    symbol: 'R\$ ',
                    decimalDigits: 2,
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Valor *',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o valor' : null,
              ),
              const SizedBox(height: 16),

              // ── Data de vencimento ────────────────────────────────────────
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Vencimento *',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(dateFmt.format(_dueDate)),
                ),
              ),
              const SizedBox(height: 16),

              // ── Categoria ─────────────────────────────────────────────────
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (cats) => DropdownButtonFormField<String>(
                  value: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Sem categoria'),
                    ),
                    ...cats.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: _hexColor(c.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(c.name),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ),
              const SizedBox(height: 16),

              // ── Recorrência ───────────────────────────────────────────────
              DropdownButtonFormField<RecurrenceType>(
                value: _recurrence,
                decoration: const InputDecoration(
                  labelText: 'Recorrência',
                  prefixIcon: Icon(Icons.repeat),
                  border: OutlineInputBorder(),
                ),
                items: RecurrenceType.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(_recurrenceLabel(r)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _recurrence = v!),
              ),
              const SizedBox(height: 16),

              // ── Parcelas (só quando sem recorrência) ──────────────────────
              if (_recurrence == RecurrenceType.none)
                Column(
                  children: [
                    TextFormField(
                      controller: _installmentsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Nº de parcelas',
                        hintText: 'Deixe vazio para sem parcelamento',
                        prefixIcon: Icon(Icons.format_list_numbered),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final n = int.tryParse(v);
                        if (n == null || n < 2) return 'Mínimo 2 parcelas';
                        if (n > 360) return 'Máximo 360 parcelas';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // ── Observações ───────────────────────────────────────────────
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  hintText: 'Opcional',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 28),

              // ── Botões ────────────────────────────────────────────────────
              Row(
                children: [
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
                    child: ElevatedButton.icon(
                      onPressed: actionState.isLoading ? null : _submit,
                      icon: actionState.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                          actionState.isLoading ? 'Salvando...' : 'Criar Conta'),
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

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  String _recurrenceLabel(RecurrenceType r) => switch (r) {
        RecurrenceType.none => 'Sem recorrência',
        RecurrenceType.daily => 'Diária',
        RecurrenceType.weekly => 'Semanal',
        RecurrenceType.monthly => 'Mensal',
        RecurrenceType.yearly => 'Anual',
      };
}
