// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/drift/app_database.dart';

void main() {
  test('dump real sqlite schema from AppDatabase', () {
    final db = AppDatabase.inMemory();
    final rows = db.rawDb.select(
      "SELECT type, name, sql FROM sqlite_master WHERE type IN ('table', 'index') AND name NOT LIKE 'sqlite_%' ORDER BY type, name;",
    );

    print('=== REAL SQLITE SCHEMA DUMP FROM APP_DATABASE ===');
    for (final row in rows) {
      print('[${row['type']}] ${row['name']}:');
      print(row['sql']);
      print('--------------------------------------------------');
    }

    final pragmaFk = db.rawDb.select('PRAGMA foreign_keys;');
    print('PRAGMA foreign_keys: ${pragmaFk.first.values.first}');

    final pragmaVer = db.rawDb.select('PRAGMA user_version;');
    print('PRAGMA user_version: ${pragmaVer.first.values.first}');

    // Let's also inspect column details using PRAGMA table_info
    final tables = rows
        .where((r) => r['type'] == 'table')
        .map((r) => r['name'] as String)
        .toList();

    print('=== PRAGMA table_info DUMP ===');
    for (final t in tables) {
      print('--- Table: $t ---');
      final cols = db.rawDb.select('PRAGMA table_info($t);');
      for (final c in cols) {
        print(
          'cid: ${c['cid']} | name: ${c['name']} | type: ${c['type']} | notnull: ${c['notnull']} | dflt_value: ${c['dflt_value']} | pk: ${c['pk']}',
        );
      }
      final fks = db.rawDb.select('PRAGMA foreign_key_list($t);');
      if (fks.isNotEmpty) {
        print('  Foreign Keys:');
        for (final fk in fks) {
          print(
            '  id: ${fk['id']} | from: ${fk['from']} -> to table: ${fk['table']}(${fk['to']}) | on_delete: ${fk['on_delete']}',
          );
        }
      }
    }
  });
}
