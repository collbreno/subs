import 'package:subs/application/ports/inbound/create_person.dart';
import 'package:subs/application/ports/outbound/id_generator.dart';
import 'package:subs/application/ports/outbound/people_repository.dart';
import 'package:subs/domain/people/person.dart';

final class CreatePersonService implements CreatePerson {
  const CreatePersonService(this._people, this._ids);

  final PeopleRepository _people;
  final IdGenerator _ids;

  @override
  Future<Person> call(CreatePersonCommand command) {
    final name = command.name.trim();
    if (name.isEmpty) throw ArgumentError('Name must not be blank');

    return _people.create(Person(id: _ids.next(), name: name));
  }
}
