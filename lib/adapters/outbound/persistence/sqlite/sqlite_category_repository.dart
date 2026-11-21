import 'package:subs/adapters/outbound/persistence/sqlite/database_changes.dart';
import 'package:subs/adapters/outbound/persistence/sqlite/local_database.dart';
import 'package:subs/application/ports/outbound/category_repository.dart';
import 'package:subs/domain/categories/category.dart';

final class SqliteCategoryRepository implements CategoryRepository {
  const SqliteCategoryRepository(this._database, this._changes);

  final LocalDatabase _database;
  final DatabaseChanges _changes;

  @override
  Future<Category> create(Category category) async {
    _database.raw.execute(
      'INSERT INTO categories (id, name, icon_key) VALUES (?, ?, ?)',
      [category.id, category.name, category.iconKey],
    );
    _changes.notify();
    return category;
  }

  @override
  Future<Category> update({
    required String categoryId,
    required String name,
    required String iconKey,
  }) async {
    _database.raw.execute(
      '''
      UPDATE categories
      SET name = ?, icon_key = ?,
          updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
      WHERE id = ?
      ''',
      [name, iconKey, categoryId],
    );
    final rows = _database.raw.select(
      'SELECT id, name, icon_key FROM categories WHERE id = ?',
      [categoryId],
    );
    if (rows.isEmpty) throw StateError('Category not found');
    _changes.notify();
    return Category(
      id: rows.first['id'] as String,
      name: rows.first['name'] as String,
      iconKey: rows.first['icon_key'] as String,
    );
  }

  @override
  Future<void> delete(String categoryId) async {
    final categoryCount =
        _database.raw
                .select('SELECT COUNT(*) AS count FROM categories')
                .first['count']
            as int;
    if (categoryCount <= 1) {
      throw StateError('Keep at least one category.');
    }
    final usage =
        _database.raw.select(
              'SELECT COUNT(*) AS count FROM subscriptions WHERE category_id = ?',
              [categoryId],
            ).first['count']
            as int;
    if (usage > 0) {
      throw StateError('This category is used by a subscription.');
    }
    _database.raw.execute('DELETE FROM categories WHERE id = ?', [categoryId]);
    _changes.notify();
  }

  @override
  Stream<List<Category>> watchAll() => _changes.watch(_loadAll);

  List<Category> _loadAll() => _database.raw
      .select(
        'SELECT id, name, icon_key FROM categories ORDER BY name COLLATE NOCASE',
      )
      .map(
        (row) => Category(
          id: row['id'] as String,
          name: row['name'] as String,
          iconKey: row['icon_key'] as String,
        ),
      )
      .toList(growable: false);
}
