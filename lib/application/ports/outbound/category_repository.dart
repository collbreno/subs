import 'package:subs/domain/categories/category.dart';

abstract interface class CategoryRepository {
  Future<Category> create(Category category);

  Future<Category> update({
    required String categoryId,
    required String name,
    required String iconKey,
  });

  Future<void> delete(String categoryId);

  Stream<List<Category>> watchAll();
}
