import 'package:subs/domain/people/person.dart';

final class CreatePersonCommand {
  const CreatePersonCommand({required this.name});

  final String name;
}

abstract interface class CreatePerson {
  Future<Person> call(CreatePersonCommand command);
}
