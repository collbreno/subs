import 'package:subs/application/ports/inbound/watch_categories.dart';
import 'package:subs/application/ports/outbound/category_repository.dart';
import 'package:subs/domain/categories/category.dart';

final class WatchCategoriesService implements WatchCategories {
  const WatchCategoriesService(this._categories);

  final CategoryRepository _categories;

  @override
  Stream<List<Category>> call() => _categories.watchAll();
}
