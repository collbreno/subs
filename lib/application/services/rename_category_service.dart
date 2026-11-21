import 'package:subs/application/ports/inbound/rename_category.dart';
import 'package:subs/application/ports/outbound/category_repository.dart';
import 'package:subs/domain/categories/category.dart';

final class RenameCategoryService implements RenameCategory {
  const RenameCategoryService(this._categories);

  final CategoryRepository _categories;

  @override
  Future<Category> call(RenameCategoryCommand command) {
    final name = command.name.trim();
    if (name.isEmpty) throw ArgumentError('Name must not be blank');
    return _categories.update(
      categoryId: command.categoryId,
      name: name,
      iconKey: command.iconKey,
    );
  }
}
