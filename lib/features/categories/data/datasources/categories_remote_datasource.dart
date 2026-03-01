import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../domain/entities/category.dart';

part 'categories_remote_datasource.g.dart';

@RestApi()
abstract class CategoriesRemoteDatasource {
  factory CategoriesRemoteDatasource(Dio dio) = _CategoriesRemoteDatasource;

  @GET('/categories')
  Future<List<Category>> getCategories({
    @Query('type') String? type,
  });

  @GET('/categories/{id}')
  Future<Category> getCategory(@Path('id') String id);

  @POST('/categories')
  Future<Category> createCategory(@Body() Map<String, dynamic> body);

  @PATCH('/categories/{id}')
  Future<Category> updateCategory(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/categories/{id}')
  Future<void> deleteCategory(@Path('id') String id);
}
