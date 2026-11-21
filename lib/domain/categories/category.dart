import 'package:equatable/equatable.dart';

final class Category extends Equatable {
  const Category({required this.id, required this.name, required this.iconKey});

  final String id;
  final String name;
  final String iconKey;

  @override
  List<Object?> get props => [id, name, iconKey];
}
