import 'package:subs/adapters/outbound/persistence/sqlite/database_changes.dart';
import 'package:subs/adapters/outbound/persistence/sqlite/local_database.dart';
import 'package:subs/application/ports/outbound/people_repository.dart';
import 'package:subs/domain/people/person.dart';

final class SqlitePeopleRepository implements PeopleRepository {
  const SqlitePeopleRepository(this._database, this._changes);

  final LocalDatabase _database;
  final DatabaseChanges _changes;

  @override
  Future<Person> create(Person person) async {
    _database.raw.execute(
      'INSERT INTO people (id, name, is_current_user) VALUES (?, ?, ?)',
      [person.id, person.name, person.isCurrentUser ? 1 : 0],
    );
    _changes.notify();
    return person;
  }

  @override
  Future<bool> exists(String personId) async => _database.raw.select(
    'SELECT 1 FROM people WHERE id = ? LIMIT 1',
    [personId],
  ).isNotEmpty;

  @override
  Future<Person> updateName({
    required String personId,
    required String name,
  }) async {
    _database.raw.execute(
      '''
      UPDATE people
      SET name = ?, updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
      WHERE id = ?
      ''',
      [name, personId],
    );
    final rows = _database.raw.select(
      'SELECT id, name, is_current_user FROM people WHERE id = ?',
      [personId],
    );
    if (rows.isEmpty) throw StateError('Person not found');
    _changes.notify();
    final row = rows.first;
    return Person(
      id: row['id'] as String,
      name: row['name'] as String,
      isCurrentUser: row['is_current_user'] == 1,
    );
  }

  @override
  Stream<List<Person>> watchAll() => _changes.watch(_loadAll);

  List<Person> _loadAll() => _database.raw
      .select('''
        SELECT id, name, is_current_user
        FROM people
        ORDER BY is_current_user DESC, name COLLATE NOCASE
      ''')
      .map(
        (row) => Person(
          id: row['id'] as String,
          name: row['name'] as String,
          isCurrentUser: row['is_current_user'] == 1,
        ),
      )
      .toList(growable: false);
}
