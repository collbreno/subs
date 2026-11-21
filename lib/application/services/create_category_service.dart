import 'package:subs/application/ports/inbound/create_category.dart';
import 'package:subs/application/ports/outbound/category_repository.dart';
import 'package:subs/application/ports/outbound/id_generator.dart';
import 'package:subs/domain/categories/category.dart';

final class CreateCategoryService implements CreateCategory {
  const CreateCategoryService(this._categories, this._ids);

  final CategoryRepository _categories;
  final IdGenerator _ids;

  @override
  Future<Category> call(CreateCategoryCommand command) {
    final name = command.name.trim();
    if (name.isEmpty) throw ArgumentError('Name must not be blank');
    return _categories.create(
      Category(id: _ids.next(), name: name, iconKey: command.iconKey),
    );
  }
}
