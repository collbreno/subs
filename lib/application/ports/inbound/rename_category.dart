import 'package:subs/domain/categories/category.dart';

final class RenameCategoryCommand {
  const RenameCategoryCommand({
    required this.categoryId,
    required this.name,
    required this.iconKey,
  });

  final String categoryId;
  final String name;
  final String iconKey;
}

abstract interface class RenameCategory {
  Future<Category> call(RenameCategoryCommand command);
}
