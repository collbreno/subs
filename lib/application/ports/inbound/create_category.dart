import 'package:subs/domain/categories/category.dart';

final class CreateCategoryCommand {
  const CreateCategoryCommand({required this.name, required this.iconKey});

  final String name;
  final String iconKey;
}

abstract interface class CreateCategory {
  Future<Category> call(CreateCategoryCommand command);
}
