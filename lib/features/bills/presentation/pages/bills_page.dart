import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/bill.dart';
import '../providers/bills_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────

class BillsPage extends ConsumerStatefulWidget {
  const BillsPage({super.key});

  @override
  ConsumerState<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends ConsumerState<BillsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _month;
  late int _year;
  String? _selectedCategoryId; // null = "Todas"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final now = DateTime.now();
    _month = now.month;
    _year  = now.year;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: _GradientFab(
        onTap: () => _openCreateSheet(context),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          // ── Sticky month nav + tabs ───────────────────────────────────────
          SliverAppBar(
            pinned: true,
            toolbarHeight: 0,
            expandedHeight: 0,
            backgroundColor: isDark ? const Color(0xFF0D0D0F) : Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(112),
              child: Column(
                children: [
                  // Month navigation
                  Container(
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
                                        : (isDark ? Colors.white : const Color(0xFF1B2B3A)),
                                  ),
                                ),
                                Text(
                                  '$_year',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white38 : Colors.grey.shade500,
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
                  // Tab bar
                  Container(
                    color: isDark ? const Color(0xFF0D0D0F) : Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.incomeColor,
                      unselectedLabelColor: isDark ? Colors.white38 : Colors.grey,
                      indicatorColor: AppTheme.incomeColor,
                      indicatorWeight: 3,
                      labelStyle:
                          const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      tabs: const [
                        Tab(text: 'Pendentes'),
                        Tab(text: 'Vencidas'),
                        Tab(text: 'Pagas'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Category filter chips ─────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryFilterDelegate(
              selectedCategoryId: _selectedCategoryId,
              onCategorySelected: (id) => setState(() => _selectedCategoryId = id),
              isDark: isDark,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _BillsList(
              status: BillStatus.pending,
              month: _month,
              year: _year,
              categoryId: _selectedCategoryId,
            ),
            _BillsList(
              status: BillStatus.overdue,
              month: _month,
              year: _year,
              categoryId: _selectedCategoryId,
            ),
            _BillsList(
              status: BillStatus.paid,
              month: _month,
              year: _year,
              categoryId: _selectedCategoryId,
            ),
          ],
        ),
      ),
    );
  }

  void _goToCurrentMonth() {
    final now = DateTime.now();
    setState(() { _month = now.month; _year = now.year; });
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateBillSheet(),
    );
  }
}

// ─── Category Filter (SliverPersistentHeaderDelegate) ─────────────────────────

class _CategoryFilterDelegate extends SliverPersistentHeaderDelegate {
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final bool isDark;

  const _CategoryFilterDelegate({
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.isDark,
  });

  @override double get minExtent => 52;
  @override double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _CategoryFilterBar(
      selectedCategoryId: selectedCategoryId,
      onCategorySelected: onCategorySelected,
      isDark: isDark,
    );
  }

  @override
  bool shouldRebuild(_CategoryFilterDelegate old) =>
      old.selectedCategoryId != selectedCategoryId || old.isDark != isDark;
}

class _CategoryFilterBar extends ConsumerWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final bool isDark;

  const _CategoryFilterBar({
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider());
    final bg     = isDark ? const Color(0xFF0D0D0F) : Colors.white;
    final border = isDark ? const Color(0xFF232333) : const Color(0xFFE8EBF0);

    return Container(
      height: 52,
      color: bg,
      child: Column(
        children: [
          Divider(height: 1, thickness: 1, color: border),
          Expanded(
            child: categoriesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (cats) {
                final items = <Category?>[null, ...cats];
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat      = items[i];
                    final selected = selectedCategoryId == cat?.id;
                    final chipColor = cat == null
                        ? AppTheme.incomeColor
                        : _hexColor(cat.color);

                    return GestureDetector(
                      onTap: () => onCategorySelected(cat?.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? chipColor.withOpacity(0.15)
                              : (isDark
                                  ? const Color(0xFF171720)
                                  : const Color(0xFFF2F5F9)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? chipColor : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (cat != null)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: chipColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Text(
                              cat?.name ?? 'Todas',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    selected ? FontWeight.w700 : FontWeight.w500,
                                color: selected
                                    ? chipColor
                                    : (isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _hexColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); }
    catch (_) { return Colors.grey; }
  }
}

// ─── Bills List ───────────────────────────────────────────────────────────────

class _BillsList extends ConsumerStatefulWidget {
  final BillStatus status;
  final int month;
  final int year;
  final String? categoryId;

  const _BillsList({
    required this.status,
    required this.month,
    required this.year,
    this.categoryId,
  });

  @override
  ConsumerState<_BillsList> createState() => _BillsListState();
}

class _BillsListState extends ConsumerState<_BillsList> {
  String? _selectedBillId;

  void _clearSelection() => setState(() => _selectedBillId = null);

  void _toggleSelection(String id) {
    setState(() => _selectedBillId = _selectedBillId == id ? null : id);
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final id = _selectedBillId;
    if (id == null) return;

    final confirmed = await AppFeedback.confirm(
      context,
      title: 'Excluir conta',
      message: 'Tem certeza que deseja excluir esta conta? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppTheme.errorColor,
      icon: Icons.delete_rounded,
    );
    if (!confirmed || !mounted) return;

    _clearSelection();
    final ok = await ref.read(billsNotifierProvider.notifier).deleteBill(id);
    if (mounted) {
      if (ok) {
        AppFeedback.showSuccess(context, 'Conta excluída.');
      } else {
        AppFeedback.showError(context, 'Erro ao excluir conta.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(billsProvider(
      status: widget.status,
      month: widget.month,
      year: widget.year,
      categoryId: widget.categoryId,
    ));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return billsAsync.when(
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
        final bills = response.items;
        final currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

        final filteredCount = bills.length;
        final filteredAmount = bills.fold(0.0, (sum, b) => sum + b.amount);

        Widget? summaryBar;
        if (filteredCount > 0) {
          summaryBar = _SummaryBar(
            count: filteredCount,
            amount: filteredAmount,
            status: widget.status,
            currFmt: currFmt,
          );
        }

        if (bills.isEmpty) {
          return Column(
            children: [
              if (summaryBar != null) summaryBar,
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _statusColor(widget.status).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_statusIcon(widget.status),
                            size: 36,
                            color: _statusColor(widget.status).withOpacity(0.5)),
                      ),
                      const SizedBox(height: 16),
                      Text('Nenhuma conta ${_statusLabel(widget.status)}',
                          style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return Stack(
          children: [
            Column(
              children: [
                if (summaryBar != null) summaryBar,
                Expanded(
                  child: GestureDetector(
                    // Toque fora do card desmarca a seleção
                    onTap: _selectedBillId != null ? _clearSelection : null,
                    behavior: HitTestBehavior.translucent,
                    child: RefreshIndicator(
                      color: AppTheme.incomeColor,
                      onRefresh: () async => ref.invalidate(billsProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: bills.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final bill = bills[i];
                          final isSelected = _selectedBillId == bill.id;
                          return BillCard(
                            bill: bill,
                            isSelected: isSelected,
                            onTap: () {
                              if (_selectedBillId != null) {
                                _clearSelection();
                              } else {
                                _showDetails(context, bill);
                              }
                            },
                            onLongPress: () => _toggleSelection(bill.id),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Barra de exclusão flutuante ──────────────────────────────
            if (_selectedBillId != null)
              Positioned(
                bottom: 16,
                left: 24,
                right: 24,
                child: _DeleteBar(
                  isDark: isDark,
                  onCancel: _clearSelection,
                  onDelete: () => _deleteSelected(context),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showDetails(BuildContext context, Bill bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BillDetailsSheet(bill: bill),
    );
  }

  String _statusLabel(BillStatus s) => switch (s) {
        BillStatus.pending   => 'pendente',
        BillStatus.overdue   => 'vencida',
        BillStatus.paid      => 'paga',
        BillStatus.cancelled => 'cancelada',
      };

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
}

// ─── Summary Bar ──────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final int count;
  final double amount;
  final BillStatus status;
  final NumberFormat currFmt;

  const _SummaryBar({
    required this.count,
    required this.amount,
    required this.status,
    required this.currFmt,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BillStatus.pending   => AppTheme.pendingColor,
      BillStatus.overdue   => AppTheme.errorColor,
      BillStatus.paid      => AppTheme.incomeColor,
      BillStatus.cancelled => Colors.grey,
    };
    final label = switch (status) {
      BillStatus.pending   => '$count pendente${count == 1 ? '' : 's'}',
      BillStatus.overdue   => '$count vencida${count == 1 ? '' : 's'}',
      BillStatus.paid      => '$count paga${count == 1 ? '' : 's'}',
      BillStatus.cancelled => '$count cancelada${count == 1 ? '' : 's'}',
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ),
          if (amount > 0)
            Text(currFmt.format(amount),
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

// ─── Bill Card ────────────────────────────────────────────────────────────────

class BillCard extends ConsumerWidget {
  final Bill bill;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const BillCard({
    super.key,
    required this.bill,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt     = DateFormat('dd/MM/yyyy');
    final color       = _statusColor(bill.status);
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final isPaid      = bill.status == BillStatus.paid;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        // Destaque sutil ao selecionar
        boxShadow: isSelected
            ? [BoxShadow(color: AppTheme.errorColor.withOpacity(0.25), blurRadius: 14, spreadRadius: 1)]
            : (isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3))]),
      ),
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap ?? () => _showDetails(context, ref),
        onLongPress: onLongPress,
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF2A1A1A) : const Color(0xFFFFF3F3))
                : (isDark ? const Color(0xFF171720) : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppTheme.errorColor.withOpacity(0.5)
                  : color.withOpacity(isPaid ? 0.1 : 0.2),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              decoration:
                                  isPaid ? TextDecoration.lineThrough : null,
                              decorationColor: color,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            dateFmt.format(bill.dueDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(status: bill.status),
                          if (bill.recurrence != RecurrenceType.none) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.repeat_rounded,
                                size: 12,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade400),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Ícone de selecionado ou valor
                isSelected
                    ? Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.errorColor.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 18, color: AppTheme.errorColor),
                      )
                    : Text(
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
    ),   // InkWell
  );     // AnimatedContainer
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

// ─── Delete Bar ──────────────────────────────────────────────────────────────

class _DeleteBar extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final bool isDark;

  const _DeleteBar({
    required this.onCancel,
    required this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícone + texto
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.errorColor, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '1 conta selecionada',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          // Botão cancelar
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botão excluir
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.delete_rounded, color: Colors.white, size: 15),
                  SizedBox(width: 5),
                  Text(
                    'Excluir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
      BillStatus.pending   => ('Pendente',  AppTheme.pendingColor),
      BillStatus.overdue   => ('Vencida',   AppTheme.overdueColor),
      BillStatus.paid      => ('Paga',      AppTheme.paidColor),
      BillStatus.cancelled => ('Cancelada', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
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
    final notifier    = ref.watch(billsNotifierProvider.notifier);
    final actionState = ref.watch(billsNotifierProvider);
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final color       = _billColor(bill.status);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_billIcon(bill.status), color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      _StatusChip(status: bill.status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Valor',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.grey)),
                        const SizedBox(height: 4),
                        Text(currencyFmt.format(bill.amount),
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: color)),
                      ],
                    ),
                  ),
                  if (bill.recurrence != RecurrenceType.none)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Recorrência',
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : Colors.grey)),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.repeat_rounded,
                              size: 14, color: AppTheme.incomeColor),
                          const SizedBox(width: 4),
                          Text(_recurrenceLabel(bill.recurrence),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.incomeColor)),
                        ]),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Vencimento',
                value: DateFormat('dd/MM/yyyy').format(bill.dueDate)),
            if (bill.paidDate != null)
              _DetailRow(
                  icon: Icons.check_circle_rounded,
                  label: 'Pago em',
                  value: DateFormat('dd/MM/yyyy').format(bill.paidDate!)),
            if (bill.totalInstallments != null)
              _DetailRow(
                  icon: Icons.format_list_numbered_rounded,
                  label: 'Parcela',
                  value: '${bill.installmentNumber}/${bill.totalInstallments}'),
            if (bill.notes != null && bill.notes!.isNotEmpty)
              _DetailRow(
                  icon: Icons.notes_rounded,
                  label: 'Observações',
                  value: bill.notes!),
            const SizedBox(height: 24),
            if (bill.status != BillStatus.paid)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1B6B45), Color(0xFF2196F3)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: actionState.isLoading
                        ? null
                        : () async {
                            final paid = await notifier.markPaid(bill.id);
                            if (paid != null && context.mounted) {
                              Navigator.pop(context);
                              AppFeedback.showSuccess(
                                  context, 'Conta marcada como paga!');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: actionState.isLoading
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline_rounded,
                            color: Colors.white),
                    label: Text(
                      actionState.isLoading
                          ? 'Processando...'
                          : 'Marcar como Pago',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _billColor(BillStatus s) => switch (s) {
        BillStatus.pending   => AppTheme.pendingColor,
        BillStatus.overdue   => AppTheme.overdueColor,
        BillStatus.paid      => AppTheme.paidColor,
        BillStatus.cancelled => Colors.grey,
      };

  IconData _billIcon(BillStatus s) => switch (s) {
        BillStatus.pending   => Icons.hourglass_top_rounded,
        BillStatus.overdue   => Icons.warning_amber_rounded,
        BillStatus.paid      => Icons.check_circle_rounded,
        BillStatus.cancelled => Icons.cancel_outlined,
      };

  String _recurrenceLabel(RecurrenceType r) => switch (r) {
        RecurrenceType.none    => 'Nenhuma',
        RecurrenceType.daily   => 'Diária',
        RecurrenceType.weekly  => 'Semanal',
        RecurrenceType.monthly => 'Mensal',
        RecurrenceType.yearly  => 'Anual',
      };
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: isDark ? Colors.white38 : Colors.grey.shade400),
          const SizedBox(width: 10),
          Text('$label: ',
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13))),
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
  final _formKey                = GlobalKey<FormState>();
  final _nameController         = TextEditingController();
  final _amountController       = TextEditingController();
  final _installmentsController = TextEditingController();
  final _notesController        = TextEditingController();

  DateTime _dueDate   = DateTime.now().add(const Duration(days: 1));
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

    // Parse the raw decimal value typed by the user.
    // Accepts both comma and dot as decimal separator (e.g. "1.500,00" or "150.00").
    final rawAmount = _amountController.text.trim();
    double amount = 0.0;
    if (rawAmount.contains(',') && rawAmount.contains('.')) {
      // Brazilian format: "1.500,00" — remove dots (thousands), comma → dot
      amount = double.tryParse(
              rawAmount.replaceAll('.', '').replaceAll(',', '.')) ??
          0.0;
    } else {
      // Simple format: "150,00" or "150.00"
      amount = double.tryParse(rawAmount.replaceAll(',', '.')) ?? 0.0;
    }

    if (amount <= 0) {
      AppFeedback.showError(context, 'Informe um valor válido maior que zero.');
      return;
    }

    final installments = int.tryParse(_installmentsController.text.trim());
    final data = <String, dynamic>{
      'name':       _nameController.text.trim(),
      'amount':     amount,
      'due_date':   DateFormat('yyyy-MM-dd').format(_dueDate),
      'recurrence': _recurrence.name,
      if (_categoryId != null) 'category_id': _categoryId,
      if (_notesController.text.trim().isNotEmpty)
        'notes': _notesController.text.trim(),
      if (_recurrence == RecurrenceType.none &&
          installments != null &&
          installments > 1)
        'total_installments': installments,
    };

    final bill =
        await ref.read(billsNotifierProvider.notifier).createBill(data);
    if (bill != null && mounted) {
      Navigator.pop(context);
      AppFeedback.showSuccess(context, 'Conta "${bill.name}" criada!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider());
    final actionState     = ref.watch(billsNotifierProvider);
    final isDark          = Theme.of(context).brightness == Brightness.dark;
    final dateFmt         = DateFormat('dd/MM/yyyy');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      maxChildSize: 0.96,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(
                24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            children: [
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
              Text('Nova Conta',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 24),

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

              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  // Allow digits, commas, and dots — no other characters.
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Valor *',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                  hintText: '0,00',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o valor';
                  final parsed =
                      double.tryParse(v.trim().replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

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
                        value: null, child: Text('Sem categoria')),
                    ...cats.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(children: [
                            Container(
                              width: 12,
                              height: 12,
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
              const SizedBox(height: 16),

              DropdownButtonFormField<RecurrenceType>(
                value: _recurrence,
                decoration: const InputDecoration(
                  labelText: 'Recorrência',
                  prefixIcon: Icon(Icons.repeat),
                  border: OutlineInputBorder(),
                ),
                items: RecurrenceType.values
                    .map((r) => DropdownMenuItem(
                        value: r, child: Text(_recurrenceLabel(r))))
                    .toList(),
                onChanged: (v) => setState(() => _recurrence = v!),
              ),
              const SizedBox(height: 16),

              if (_recurrence == RecurrenceType.none)
                Column(children: [
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
                ]),

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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: actionState.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: actionState.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check, color: Colors.white),
                      label: Text(
                          actionState.isLoading ? 'Salvando...' : 'Criar Conta',
                          style: const TextStyle(color: Colors.white)),
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

  Color _hexColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); }
    catch (_) { return Colors.grey; }
  }

  String _recurrenceLabel(RecurrenceType r) => switch (r) {
        RecurrenceType.none    => 'Sem recorrência',
        RecurrenceType.daily   => 'Diária',
        RecurrenceType.weekly  => 'Semanal',
        RecurrenceType.monthly => 'Mensal',
        RecurrenceType.yearly  => 'Anual',
      };
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
