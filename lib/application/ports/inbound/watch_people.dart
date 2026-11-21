import 'package:subs/domain/people/person.dart';

abstract interface class WatchPeople {
  Stream<List<Person>> call();
}
