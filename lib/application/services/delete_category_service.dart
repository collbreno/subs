import 'package:subs/application/ports/inbound/delete_category.dart';
import 'package:subs/application/ports/outbound/category_repository.dart';

final class DeleteCategoryService implements DeleteCategory {
  const DeleteCategoryService(this._categories);

  final CategoryRepository _categories;

  @override
  Future<void> call(String categoryId) => _categories.delete(categoryId);
}
