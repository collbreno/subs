import 'package:subs/domain/categories/category.dart';

abstract interface class WatchCategories {
  Stream<List<Category>> call();
}
