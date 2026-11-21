import 'package:subs/domain/people/person.dart';

final class RenamePersonCommand {
  const RenamePersonCommand({required this.personId, required this.name});

  final String personId;
  final String name;
}

abstract interface class RenamePerson {
  Future<Person> call(RenamePersonCommand command);
}
