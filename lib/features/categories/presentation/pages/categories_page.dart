import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../providers/categories_provider.dart';
import '../../../../core/theme/app_theme.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
      ),
      body: _CategoriesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateCategorySheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openCreateCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateCategorySheet(),
    );
  }
}

// ─── Categories List ──────────────────────────────────────────────────────

class _CategoriesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider());

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro ao carregar categorias: $e')),
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma categoria',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(categoriesProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryCard(category: category);
            },
          ),
        );
      },
    );
  }
}

// ─── Category Card ────────────────────────────────────────────────────────

class _CategoryCard extends ConsumerWidget {
  final Category category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = _parseColor(category.color);

    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context, ref),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _parseIcon(category.icon),
                    color: categoryColor,
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
                      category.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _categoryTypeLabel(category.type),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: categoryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (category.isDefault)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.star, color: Colors.amber[600], size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Categoria'),
        content: Text('Deseja remover a categoria "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(categoriesNotifierProvider.notifier).deleteCategory(category.id);
            },
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _categoryTypeLabel(CategoryType type) {
    return switch (type) {
      CategoryType.income => 'Renda',
      CategoryType.expense => 'Despesa',
      CategoryType.both => 'Ambos',
    };
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    } catch (_) {
      return Colors.blue;
    }
  }

  IconData _parseIcon(String iconString) {
    final iconMap = {
      'shopping': Icons.shopping_cart,
      'food': Icons.restaurant,
      'transport': Icons.directions_car,
      'health': Icons.health_and_safety,
      'entertainment': Icons.sports_esports,
      'bills': Icons.receipt,
      'salary': Icons.attach_money,
      'investment': Icons.trending_up,
      'other': Icons.category,
    };
    return iconMap[iconString] ?? Icons.category;
  }
}

// ─── Create Category Sheet ─────────────────────────────────────────────────

class CreateCategorySheet extends ConsumerStatefulWidget {
  const CreateCategorySheet({super.key});

  @override
  ConsumerState<CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends ConsumerState<CreateCategorySheet> {
  late TextEditingController _nameController;
  CategoryType _selectedType = CategoryType.expense;
  Color _selectedColor = Colors.blue;
  String _selectedIcon = 'other';

  static const List<Color> _presetColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.amber,
    Colors.teal,
  ];

  static const Map<String, String> _icons = {
    'shopping': 'Shopping',
    'food': 'Alimentação',
    'transport': 'Transporte',
    'health': 'Saúde',
    'entertainment': 'Entretenimento',
    'bills': 'Contas',
    'salary': 'Salário',
    'investment': 'Investimento',
    'other': 'Outro',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
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
            'Nova Categoria',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Nome da categoria',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Text('Tipo', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButton<CategoryType>(
            value: _selectedType,
            isExpanded: true,
            items: CategoryType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_categoryTypeLabel(type)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
              }
            },
          ),
          const SizedBox(height: 16),
          Text('Cor', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: _presetColors.map((color) {
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color ? Colors.black : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Ícone', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _selectedIcon,
            isExpanded: true,
            items: _icons.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedIcon = value);
              }
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Criar Categoria'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome da categoria')),
      );
      return;
    }

    final data = {
      'name': _nameController.text.trim(),
      'type': _selectedType.name,
      'color': _selectedColor.value.toRadixString(16).padLeft(8, '0'),
      'icon': _selectedIcon,
    };

    final result = await ref.read(categoriesNotifierProvider.notifier).createCategory(data);
    
    if (mounted) {
      Navigator.pop(context);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoria criada com sucesso')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao criar categoria')),
        );
      }
    }
  }

  String _categoryTypeLabel(CategoryType type) {
    return switch (type) {
      CategoryType.income => 'Renda',
      CategoryType.expense => 'Despesa',
      CategoryType.both => 'Ambos',
    };
  }
}
