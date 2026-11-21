import 'package:subs/application/ports/inbound/rename_person.dart';
import 'package:subs/application/ports/outbound/people_repository.dart';
import 'package:subs/domain/people/person.dart';

final class RenamePersonService implements RenamePerson {
  const RenamePersonService(this._people);

  final PeopleRepository _people;

  @override
  Future<Person> call(RenamePersonCommand command) {
    final name = command.name.trim();
    if (name.isEmpty) throw ArgumentError('Name must not be blank');
    return _people.updateName(personId: command.personId, name: name);
  }
}
