import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/wallet.dart';
import '../providers/wallets_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../main.dart' show hideValuesProvider;

// ─── Page ─────────────────────────────────────────────────────────────────────

class WalletsPage extends ConsumerStatefulWidget {
  const WalletsPage({super.key});

  @override
  ConsumerState<WalletsPage> createState() => _WalletsPageState();
}

class _WalletsPageState extends ConsumerState<WalletsPage> {
  Wallet? _selectedWallet;

  void _clearSelection() => setState(() => _selectedWallet = null);

  void _toggleSelection(Wallet w) {
    setState(() => _selectedWallet = _selectedWallet?.id == w.id ? null : w);
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final wallet = _selectedWallet;
    if (wallet == null) return;

    final confirmed = await AppFeedback.confirm(
      context,
      title: 'Excluir carteira',
      message:
          'Tem certeza que deseja excluir "${wallet.name}"? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppTheme.errorColor,
      icon: Icons.delete_rounded,
    );
    if (!confirmed || !mounted) return;

    _clearSelection();
    final ok =
        await ref.read(walletsNotifierProvider.notifier).deleteWallet(wallet.id);
    if (mounted) {
      ok
          ? AppFeedback.showSuccess(context, 'Carteira excluída.')
          : AppFeedback.showError(context, 'Erro ao excluir carteira.');
    }
  }

  void _openEdit(BuildContext context, Wallet wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _WalletFormSheet(wallet: wallet),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final walletsAsync = ref.watch(walletsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: _GradientFab(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const _WalletFormSheet(),
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          // ── Sticky header ─────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            toolbarHeight: 0,
            expandedHeight: 0,
            backgroundColor: isDark ? const Color(0xFF0D0D0F) : Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Container(
                color: isDark ? const Color(0xFF0D0D0F) : Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Carteiras',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: isDark ? Colors.white : const Color(0xFF1B2B3A),
                              ),
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, _) {
                              final hide = ref.watch(hideValuesProvider);
                              return IconButton(
                                icon: Icon(
                                  hide
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 20,
                                ),
                                onPressed: () => ref
                                    .read(hideValuesProvider.notifier)
                                    .state = !hide,
                                splashRadius: 20,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark
                          ? const Color(0xFF232333)
                          : const Color(0xFFE8EBF0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: walletsAsync.when(
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
          data: (wallets) {
            final currFmt =
                NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
            final total =
                wallets.fold(0.0, (sum, w) => sum + w.balance);

            return Stack(
              children: [
                wallets.isEmpty
                    ? _EmptyState()
                    : GestureDetector(
                        onTap: _selectedWallet != null ? _clearSelection : null,
                        behavior: HitTestBehavior.translucent,
                        child: RefreshIndicator(
                          color: AppTheme.incomeColor,
                          onRefresh: () async =>
                              ref.invalidate(walletsProvider),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                            children: [
                              // ── Total card ──────────────────────────────
                              _TotalCard(
                                  total: total, currFmt: currFmt, isDark: isDark),
                              const SizedBox(height: 16),

                              // ── Wallet cards ────────────────────────────
                              ...wallets.map((w) {
                                final isSelected = _selectedWallet?.id == w.id;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _WalletCard(
                                    wallet: w,
                                    isSelected: isSelected,
                                    currFmt: currFmt,
                                    isDark: isDark,
                                    onTap: () {
                                      if (_selectedWallet != null) {
                                        _clearSelection();
                                      } else {
                                        _openEdit(context, w);
                                      }
                                    },
                                    onLongPress: () => _toggleSelection(w),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),

                // ── Action bar (long press) ──────────────────────────────
                if (_selectedWallet != null)
                  Positioned(
                    bottom: 16,
                    left: 24,
                    right: 24,
                    child: _ActionBar(
                      isDark: isDark,
                      walletName: _selectedWallet!.name,
                      onCancel: _clearSelection,
                      onEdit: () {
                        final w = _selectedWallet!;
                        _clearSelection();
                        _openEdit(context, w);
                      },
                      onDelete: () => _deleteSelected(context),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.incomeColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_rounded,
                size: 36, color: AppTheme.incomeColor.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text('Nenhuma carteira cadastrada',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Toque no botão + para adicionar sua primeira carteira',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white38
                    : Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ─── Total Card ───────────────────────────────────────────────────────────────

class _TotalCard extends ConsumerWidget {
  final double total;
  final NumberFormat currFmt;
  final bool isDark;

  const _TotalCard(
      {required this.total, required this.currFmt, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideValues = ref.watch(hideValuesProvider);
    final isPositive = total >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B6B45),
            const Color(0xFF1A3A5C),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B6B45).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text('Saldo Total',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hideValues ? 'R\$ ••••' : currFmt.format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          if (!isPositive)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 12),
                  SizedBox(width: 4),
                  Text('Saldo negativo',
                      style:
                          TextStyle(color: Colors.orange, fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Wallet Card ──────────────────────────────────────────────────────────────

class _WalletCard extends ConsumerWidget {
  final Wallet wallet;
  final bool isSelected;
  final NumberFormat currFmt;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _WalletCard({
    required this.wallet,
    required this.isSelected,
    required this.currFmt,
    required this.isDark,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideValues = ref.watch(hideValuesProvider);
    final color = _walletColor(wallet.type);
    final isNegative = wallet.balance < 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: isSelected
            ? [
                BoxShadow(
                    color: AppTheme.errorColor.withOpacity(0.25),
                    blurRadius: 14,
                    spreadRadius: 1)
              ]
            : (isDark
                ? []
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 3))
                  ]),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? const Color(0xFF2A1A1A)
                      : const Color(0xFFFFF3F3))
                  : (isDark ? const Color(0xFF171720) : Colors.white),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? AppTheme.errorColor.withOpacity(0.5)
                    : color.withOpacity(0.2),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // ── Icon ──────────────────────────────────────────────
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_walletIcon(wallet.type),
                        color: color, size: 22),
                  ),
                  const SizedBox(width: 14),

                  // ── Name + type ───────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        _TypeChip(
                            type: wallet.type, color: color),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ── Balance or check ──────────────────────────────────
                  isSelected
                      ? Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppTheme.errorColor.withOpacity(0.5)),
                          ),
                          child: const Icon(Icons.check_rounded,
                              size: 18, color: AppTheme.errorColor),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              hideValues
                                  ? 'R\$ ••••'
                                  : currFmt.format(wallet.balance),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: isNegative
                                    ? AppTheme.errorColor
                                    : (isDark
                                        ? Colors.white
                                        : const Color(0xFF1B2B3A)),
                              ),
                            ),
                            if (!hideValues && wallet.initialBalance != wallet.balance)
                              Text(
                                'Inicial: ${currFmt.format(wallet.initialBalance)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey.shade400,
                                ),
                              ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _walletColor(WalletType t) => switch (t) {
        WalletType.checking    => const Color(0xFF2196F3),
        WalletType.savings     => const Color(0xFF1B6B45),
        WalletType.cash        => const Color(0xFFFF9800),
        WalletType.investment  => const Color(0xFF9C27B0),
        WalletType.credit_card => const Color(0xFFE53935),
      };

  IconData _walletIcon(WalletType t) => switch (t) {
        WalletType.checking    => Icons.account_balance_rounded,
        WalletType.savings     => Icons.savings_rounded,
        WalletType.cash        => Icons.payments_rounded,
        WalletType.investment  => Icons.trending_up_rounded,
        WalletType.credit_card => Icons.credit_card_rounded,
      };
}

// ─── Type Chip ────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final WalletType type;
  final Color color;
  const _TypeChip({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Action Bar (long press) ──────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final bool isDark;
  final String walletName;
  final VoidCallback onCancel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActionBar({
    required this.isDark,
    required this.walletName,
    required this.onCancel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: AppTheme.errorColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              walletName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Cancelar
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          // Editar
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.incomeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit_rounded,
                      color: AppTheme.incomeColor, size: 15),
                  SizedBox(width: 4),
                  Text('Editar',
                      style: TextStyle(
                          color: AppTheme.incomeColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Excluir
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.delete_rounded, color: Colors.white, size: 15),
                  SizedBox(width: 4),
                  Text('Excluir',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wallet Form Sheet (create & edit) ────────────────────────────────────────

class _WalletFormSheet extends ConsumerStatefulWidget {
  final Wallet? wallet; // null = create, non-null = edit

  const _WalletFormSheet({this.wallet});

  @override
  ConsumerState<_WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<_WalletFormSheet> {
  final _formKey       = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late WalletType  _type;
  late String      _color;

  bool get _isEdit => widget.wallet != null;

  static const _colors = [
    '#2196F3', // azul (checking)
    '#1B6B45', // verde escuro (savings)
    '#FF9800', // laranja (cash)
    '#9C27B0', // roxo (investment)
    '#E53935', // vermelho (credit_card)
    '#00BCD4', // ciano
    '#FF5722', // laranja escuro
    '#607D8B', // cinza azulado
  ];

  @override
  void initState() {
    super.initState();
    final w = widget.wallet;
    _nameController    = TextEditingController(text: w?.name ?? '');
    _balanceController = TextEditingController(
        text: w != null
            ? w.initialBalance.toStringAsFixed(2).replaceAll('.', ',')
            : '0,00');
    _type  = w?.type  ?? WalletType.checking;
    _color = w?.color ?? '#2196F3';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final raw = _balanceController.text.trim();
    double balance;
    if (raw.contains(',') && raw.contains('.')) {
      balance = double.tryParse(raw.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
    } else {
      balance = double.tryParse(raw.replaceAll(',', '.')) ?? 0.0;
    }

    final data = <String, dynamic>{
      'name':            _nameController.text.trim(),
      'type':            _type.name,
      'color':           _color,
      'icon':            _walletIcon(_type),
      if (!_isEdit) 'initial_balance': balance,
    };

    final notifier = ref.read(walletsNotifierProvider.notifier);
    if (_isEdit) {
      final updated = await notifier.updateWallet(widget.wallet!.id, data);
      if (updated != null && mounted) {
        Navigator.pop(context);
        AppFeedback.showSuccess(context, 'Carteira atualizada!');
      }
    } else {
      final created = await notifier.createWallet(data);
      if (created != null && mounted) {
        Navigator.pop(context);
        AppFeedback.showSuccess(context, 'Carteira "${created.name}" criada!');
      }
    }
  }

  String _walletIcon(WalletType t) => switch (t) {
        WalletType.checking    => 'account_balance',
        WalletType.savings     => 'savings',
        WalletType.cash        => 'payments',
        WalletType.investment  => 'trending_up',
        WalletType.credit_card => 'credit_card',
      };

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(walletsNotifierProvider);
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
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
                _isEdit ? 'Editar Carteira' : 'Nova Carteira',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 24),

              // ── Nome ─────────────────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nome da carteira *',
                  hintText: 'Ex: Nubank, Carteira, Bradesco',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),

              // ── Tipo ─────────────────────────────────────────────────────
              DropdownButtonFormField<WalletType>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo *',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: WalletType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(_iconForType(t),
                                  size: 18,
                                  color: _colorForType(t)),
                              const SizedBox(width: 10),
                              Text(t.label),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _type  = v;
                    _color = _defaultColorForType(v);
                  });
                },
              ),
              const SizedBox(height: 16),

              // ── Saldo inicial (só em criação) ─────────────────────────────
              if (!_isEdit) ...[
                TextFormField(
                  controller: _balanceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Saldo inicial',
                    prefixIcon: Icon(Icons.attach_money),
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                    hintText: '0,00',
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Cor ───────────────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cor',
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white54
                              : Colors.grey.shade600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _colors.map((hex) {
                      final c     = _hexColor(hex);
                      final isSel = _color == hex;
                      return GestureDetector(
                        onTap: () => setState(() => _color = hex),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: isSel
                                ? Border.all(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    width: 3)
                                : null,
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                        color: c.withOpacity(0.5),
                                        blurRadius: 8)
                                  ]
                                : null,
                          ),
                          child: isSel
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Botões ────────────────────────────────────────────────────
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
                        actionState.isLoading
                            ? 'Salvando...'
                            : (_isEdit
                                ? 'Salvar Alterações'
                                : 'Criar Carteira'),
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

  IconData _iconForType(WalletType t) => switch (t) {
        WalletType.checking    => Icons.account_balance_rounded,
        WalletType.savings     => Icons.savings_rounded,
        WalletType.cash        => Icons.payments_rounded,
        WalletType.investment  => Icons.trending_up_rounded,
        WalletType.credit_card => Icons.credit_card_rounded,
      };

  Color _colorForType(WalletType t) => switch (t) {
        WalletType.checking    => const Color(0xFF2196F3),
        WalletType.savings     => const Color(0xFF1B6B45),
        WalletType.cash        => const Color(0xFFFF9800),
        WalletType.investment  => const Color(0xFF9C27B0),
        WalletType.credit_card => const Color(0xFFE53935),
      };

  String _defaultColorForType(WalletType t) => switch (t) {
        WalletType.checking    => '#2196F3',
        WalletType.savings     => '#1B6B45',
        WalletType.cash        => '#FF9800',
        WalletType.investment  => '#9C27B0',
        WalletType.credit_card => '#E53935',
      };

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
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
