import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../providers/categories_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';

// ─── Icon & Color Maps ────────────────────────────────────────────────────────

/// Maps backend icon string names → Flutter IconData.
const Map<String, IconData> kIconMap = {
  'restaurant':             Icons.restaurant_rounded,
  'directions_car':         Icons.directions_car_rounded,
  'home':                   Icons.home_rounded,
  'local_hospital':         Icons.local_hospital_rounded,
  'school':                 Icons.school_rounded,
  'sports_esports':         Icons.sports_esports_rounded,
  'checkroom':              Icons.checkroom_rounded,
  'miscellaneous_services': Icons.miscellaneous_services_rounded,
  'payments':               Icons.payments_rounded,
  'computer':               Icons.computer_rounded,
  'trending_up':            Icons.trending_up_rounded,
  'more_horiz':             Icons.more_horiz_rounded,
  'attach_money':           Icons.attach_money_rounded,
  'shopping_cart':          Icons.shopping_cart_rounded,
  'fitness_center':         Icons.fitness_center_rounded,
  'flight':                 Icons.flight_rounded,
  'pets':                   Icons.pets_rounded,
  'celebration':            Icons.celebration_rounded,
};

/// Maps backend icon string names → Portuguese display labels.
const Map<String, String> kIconLabels = {
  'restaurant':             'Alimentação',
  'directions_car':         'Transporte',
  'home':                   'Moradia',
  'local_hospital':         'Saúde',
  'school':                 'Educação',
  'sports_esports':         'Jogos',
  'checkroom':              'Vestuário',
  'miscellaneous_services': 'Serviços',
  'payments':               'Contas',
  'computer':               'Tecnologia',
  'trending_up':            'Investimento',
  'more_horiz':             'Outros',
  'attach_money':           'Salário',
  'shopping_cart':          'Compras',
  'fitness_center':         'Academia',
  'flight':                 'Viagem',
  'pets':                   'Pets',
  'celebration':            'Lazer',
};

/// Preset palette – 18 swatches used in the color picker.
const List<Color> kPresetColors = [
  Color(0xFFE53935), Color(0xFFE91E63), Color(0xFF9C27B0),
  Color(0xFF673AB7), Color(0xFF3F51B5), Color(0xFF2196F3),
  Color(0xFF03A9F4), Color(0xFF00BCD4), Color(0xFF009688),
  Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFCDDC39),
  Color(0xFFFFEB3B), Color(0xFFFFC107), Color(0xFFFF9800),
  Color(0xFFFF5722), Color(0xFF795548), Color(0xFF607D8B),
];

/// Converts Color → backend hex string `#RRGGBB`.
String colorToHex(Color c) =>
    '#${(c.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Parses backend hex string `#RRGGBB` → Color.
Color hexToColor(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xff')));
  } catch (_) {
    return const Color(0xFF2196F3);
  }
}

/// Returns the icon for an icon string (falls back to category icon).
IconData iconDataFor(String name) => kIconMap[name] ?? Icons.category_rounded;

// ─── Page ─────────────────────────────────────────────────────────────────────

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreate() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _CategorySheet(),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          // ── Gradient App Bar ──────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0B3D2E), Color(0xFF1B6B45), Color(0xFF1A3A5C)],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 64),
              title: const Text(
                'Categorias',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: isDark ? const Color(0xFF0D0D0F) : Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.incomeColor,
                  unselectedLabelColor: isDark ? Colors.white38 : Colors.grey,
                  indicatorColor: AppTheme.incomeColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Todos'),
                    Tab(text: 'Despesas'),
                    Tab(text: 'Receitas'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _CategoryList(typeFilter: null),
            _CategoryList(typeFilter: CategoryType.expense),
            _CategoryList(typeFilter: CategoryType.income),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppTheme.incomeColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nova Categoria',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─── Category List ────────────────────────────────────────────────────────────

class _CategoryList extends ConsumerWidget {
  final CategoryType? typeFilter;
  const _CategoryList({this.typeFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoriesProvider(type: typeFilter));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 12),
              Text('Erro ao carregar: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.errorColor)),
            ],
          ),
        ),
      ),
      data: (categories) {
        if (categories.isEmpty) {
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
                  child: Icon(Icons.category_outlined,
                      size: 40, color: AppTheme.incomeColor.withOpacity(0.6)),
                ),
                const SizedBox(height: 16),
                Text('Nenhuma categoria',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Crie sua primeira categoria',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppTheme.incomeColor,
          onRefresh: () async => ref.invalidate(categoriesProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _CategoryCard(category: categories[i]),
          ),
        );
      },
    );
  }
}

// ─── Category Card ────────────────────────────────────────────────────────────

class _CategoryCard extends ConsumerWidget {
  final Category category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color  = hexToColor(category.color);

    Widget card = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171720) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF232333) : const Color(0xFFE8EBF0),
        ),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openEdit(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // ── Icon avatar ─────────────────────────────────────────
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(iconDataFor(category.icon), color: color, size: 22),
                ),
                const SizedBox(width: 14),

                // ── Name + type badge ────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            category.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (category.isDefault) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.star_rounded, size: 14, color: Colors.amber[600]),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      _TypeBadge(type: category.type, color: color),
                    ],
                  ),
                ),

                // ── Actions ──────────────────────────────────────────────
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                  onPressed: () => _openEdit(context),
                ),
                if (!category.isDefault)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppTheme.errorColor.withOpacity(0.7),
                    onPressed: () => _confirmDelete(context, ref),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return card;
  }

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(existing: category),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppFeedback.confirmDelete(
      context,
      title: 'Remover Categoria',
      subtitle: 'Deseja remover "${category.name}"? Essa ação não pode ser desfeita.',
    );
    if (!confirmed || !context.mounted) return;

    final ok = await ref
        .read(categoriesNotifierProvider.notifier)
        .deleteCategory(category.id);

    if (context.mounted) {
      if (ok) {
        AppFeedback.showSuccess(context, 'Categoria removida');
      } else {
        AppFeedback.showError(context, 'Erro ao remover categoria');
      }
    }
  }
}

// ─── Type Badge ───────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final CategoryType type;
  final Color color;
  const _TypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      CategoryType.income  => 'Receita',
      CategoryType.expense => 'Despesa',
      CategoryType.both    => 'Ambos',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Category Sheet (Create / Edit) ──────────────────────────────────────────

class _CategorySheet extends ConsumerStatefulWidget {
  final Category? existing;
  const _CategorySheet({this.existing});

  @override
  ConsumerState<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<_CategorySheet> {
  late TextEditingController _nameCtrl;
  late CategoryType _type;
  late Color _color;
  late String _icon;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _type     = e?.type  ?? CategoryType.expense;
    _color    = e != null ? hexToColor(e.color) : kPresetColors[5];
    _icon     = e?.icon  ?? 'more_horiz';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF1E1E2C) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ────────────────────────────────────────────────
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

            // ── Title ──────────────────────────────────────────────────────
            Text(
              _isEdit ? 'Editar Categoria' : 'Nova Categoria',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 24),

            // ── Preview chip ────────────────────────────────────────────────
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _color.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconDataFor(_icon), color: _color, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      _nameCtrl.text.isEmpty ? 'Pré-visualização' : _nameCtrl.text,
                      style: TextStyle(
                        color: _color,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Name ───────────────────────────────────────────────────────
            _Label('Nome'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Ex: Alimentação',
                filled: true,
                fillColor: isDark ? const Color(0xFF12121A) : const Color(0xFFF2F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.incomeColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // ── Type ───────────────────────────────────────────────────────
            _Label('Tipo'),
            const SizedBox(height: 8),
            Row(
              children: CategoryType.values.map((t) {
                final active = _type == t;
                final label  = switch (t) {
                  CategoryType.expense => 'Despesa',
                  CategoryType.income  => 'Receita',
                  CategoryType.both    => 'Ambos',
                };
                final chipColor = switch (t) {
                  CategoryType.expense => AppTheme.errorColor,
                  CategoryType.income  => AppTheme.incomeColor,
                  CategoryType.both    => Colors.blueGrey,
                };
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: active ? chipColor.withOpacity(0.12) : (isDark ? const Color(0xFF12121A) : const Color(0xFFF2F5F9)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active ? chipColor : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active ? chipColor : (isDark ? Colors.white54 : Colors.grey),
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Color ──────────────────────────────────────────────────────
            _Label('Cor'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kPresetColors.map((c) {
                final selected = _color.value == c.value;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]
                          : [],
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Icon ───────────────────────────────────────────────────────
            _Label('Ícone'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: kIconMap.entries.map((entry) {
                final selected = _icon == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _icon = entry.key),
                  child: Tooltip(
                    message: kIconLabels[entry.key] ?? entry.key,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: selected
                            ? _color.withOpacity(0.15)
                            : (isDark ? const Color(0xFF12121A) : const Color(0xFFF2F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? _color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        entry.value,
                        color: selected ? _color : (isDark ? Colors.white38 : Colors.grey.shade400),
                        size: 22,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ── Submit ─────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B6B45), Color(0xFF2196F3)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _isEdit ? 'Salvar Alterações' : 'Criar Categoria',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppFeedback.showWarning(context, 'Digite o nome da categoria');
      return;
    }

    setState(() => _saving = true);

    final data = {
      'name':  name,
      'type':  _type.name, // backend expects lowercase: "income", "expense", "both"
      'color': colorToHex(_color),
      'icon':  _icon,
    };

    final notifier = ref.read(categoriesNotifierProvider.notifier);
    Category? result;

    if (_isEdit) {
      result = await notifier.updateCategory(widget.existing!.id, data);
    } else {
      result = await notifier.createCategory(data);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);

    if (result != null) {
      AppFeedback.showSuccess(
        context,
        _isEdit ? 'Categoria atualizada' : 'Categoria criada',
      );
    } else {
      AppFeedback.showError(
        context,
        _isEdit ? 'Erro ao atualizar categoria' : 'Erro ao criar categoria',
      );
    }
  }
}

// ─── Label ────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
    );
  }
}
