import 'package:subs/application/ports/inbound/watch_people.dart';
import 'package:subs/application/ports/outbound/people_repository.dart';
import 'package:subs/domain/people/person.dart';

final class WatchPeopleService implements WatchPeople {
  const WatchPeopleService(this._people);

  final PeopleRepository _people;

  @override
  Stream<List<Person>> call() => _people.watchAll();
}
