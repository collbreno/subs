import 'package:equatable/equatable.dart';

final class Person extends Equatable {
  const Person({
    required this.id,
    required this.name,
    this.isCurrentUser = false,
  });

  final String id;
  final String name;
  final bool isCurrentUser;

  @override
  List<Object?> get props => [id, name, isCurrentUser];
}
