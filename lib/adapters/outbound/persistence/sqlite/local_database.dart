import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

final class LocalDatabase {
  LocalDatabase._(this.raw);

  LocalDatabase.testing(this.raw);

  final Database raw;

  static Future<LocalDatabase> open() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}${Platform.pathSeparator}subs.sqlite';
    final raw = sqlite3.open(path);
    raw.execute('PRAGMA foreign_keys = ON;');

    final version = raw.select('PRAGMA user_version').first.values.first as int;
    if (version == 0) {
      final migration = await rootBundle.loadString(
        'database/migrations/001_initial_schema.sql',
      );
      raw.execute(migration);
    }
    if (version < 2) {
      final migration = await rootBundle.loadString(
        'database/migrations/002_allow_current_user_zero_weight.sql',
      );
      raw.execute(migration);
    }
    if (version < 3) {
      final migration = await rootBundle.loadString(
        'database/migrations/003_add_category_icons.sql',
      );
      raw.execute(migration);
    }

    final database = LocalDatabase._(raw);
    database._seedFirstRunData();
    return database;
  }

  void _seedFirstRunData() {
    raw.execute('''
      BEGIN IMMEDIATE;
      INSERT OR IGNORE INTO people (id, name, is_current_user)
      VALUES ('current-user', 'Me', 1);
      INSERT INTO categories (id, name, icon_key)
      SELECT id, name, icon_key FROM (
        SELECT 'other' AS id, 'Other' AS name, 'category' AS icon_key
        UNION ALL SELECT 'utilities', 'Utilities', 'bolt'
        UNION ALL SELECT 'entertainment', 'Entertainment', 'movie'
      )
      WHERE NOT EXISTS (SELECT 1 FROM categories);
      COMMIT;
    ''');
  }

  void close() => raw.close();
}
