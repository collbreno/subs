import 'package:subs/domain/people/person.dart';

abstract interface class PeopleRepository {
  Future<Person> create(Person person);

  Future<Person> updateName({required String personId, required String name});

  Future<bool> exists(String personId);

  Stream<List<Person>> watchAll();
}
