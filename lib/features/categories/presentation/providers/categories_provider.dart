import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/category.dart';
import '../../data/datasources/categories_remote_datasource.dart';
import '../../../../core/network/dio_client.dart';

part 'categories_provider.g.dart';

@riverpod
CategoriesRemoteDatasource categoriesDatasource(CategoriesDatasourceRef ref) {
  return CategoriesRemoteDatasource(createDio());
}

@riverpod
Future<List<Category>> categories(CategoriesRef ref, {CategoryType? type}) async {
  final ds = ref.watch(categoriesDatasourceProvider);
  return ds.getCategories(type: type?.name);
}

@riverpod
class CategoriesNotifier extends _$CategoriesNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Category?> createCategory(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(categoriesDatasourceProvider);
      final category = await ds.createCategory(data);
      state = const AsyncData(null);
      ref.invalidate(categoriesProvider);
      return category;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<Category?> updateCategory(String id, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(categoriesDatasourceProvider);
      final category = await ds.updateCategory(id, data);
      state = const AsyncData(null);
      ref.invalidate(categoriesProvider);
      return category;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> deleteCategory(String id) async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(categoriesDatasourceProvider);
      await ds.deleteCategory(id);
      state = const AsyncData(null);
      ref.invalidate(categoriesProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
