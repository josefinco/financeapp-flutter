import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../bills/presentation/providers/bills_provider.dart';
import '../../../bills/presentation/pages/bills_page.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingBillsProvider(days: 7));
    final now = DateTime.now();
    final billsAsync = ref.watch(billsProvider(month: now.month, year: now.year));
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinanceApp'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(upcomingBillsProvider);
          ref.invalidate(billsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary cards
            billsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
              data: (res) => Row(
                children: [
                  _SummaryCard(
                    label: 'A Pagar',
                    value: currencyFmt.format(res.totalPendingAmount),
                    color: AppTheme.pendingColor,
                    icon: Icons.pending_outlined,
                    flex: 2,
                  ),
                  const SizedBox(width: 8),
                  _SummaryCard(
                    label: 'Vencidas',
                    value: res.overdueCount.toString(),
                    color: AppTheme.overdueColor,
                    icon: Icons.warning_amber_outlined,
                  ),
                  const SizedBox(width: 8),
                  _SummaryCard(
                    label: 'Pendentes',
                    value: res.pendingCount.toString(),
                    color: AppTheme.expenseColor,
                    icon: Icons.receipt_long_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Upcoming bills
            Text('Próximos 7 dias', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            upcomingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erro: $e'),
              data: (bills) {
                if (bills.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 48, color: AppTheme.paidColor),
                          const SizedBox(height: 8),
                          Text('Nenhuma conta nos próximos 7 dias 🎉', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: bills.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BillCard(bill: b),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final int flex;

  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon, this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
