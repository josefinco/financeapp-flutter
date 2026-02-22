import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/bill.dart';
import '../providers/bills_provider.dart';
import '../../../../core/theme/app_theme.dart';

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
    final dateFmt = DateFormat('dd/MM/yyyy');
    final color = _statusColor(bill.status);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetails(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bill.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: bill.status == BillStatus.paid
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                          ),
                        ),
                        Text(
                          currencyFmt.format(bill.amount),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Vence: ${dateFmt.format(bill.dueDate)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                        const Spacer(),
                        _StatusChip(status: bill.status),
                      ],
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

  Color _statusColor(BillStatus s) => switch (s) {
        BillStatus.pending => AppTheme.pendingColor,
        BillStatus.overdue => AppTheme.overdueColor,
        BillStatus.paid => AppTheme.paidColor,
        BillStatus.cancelled => Colors.grey,
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
        color: color.withOpacity(0.12),
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

// ─── Create Bill Sheet (placeholder — implement with form_builder) ─────────────

class CreateBillSheet extends StatelessWidget {
  const CreateBillSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Formulário de criação de conta — próxima etapa'));
  }
}
