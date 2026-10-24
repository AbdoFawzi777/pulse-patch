import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/sqlite3.dart';
import '../../domain/entities/reminder_record.dart';
import '../drift/app_database.dart';
import 'session_repository.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReminderRepository(db);
});

class ReminderRepository {
  ReminderRepository(this._db);

  final AppDatabase _db;

  Future<int> insertReminder(ReminderRecord reminder) async {
    try {
      final db = _db.rawDb;
      db.execute(
        '''
        INSERT INTO reminders (hour, minute, label, is_enabled, days_of_week)
        VALUES (?, ?, ?, ?, ?);
      ''',
        [
          reminder.hour,
          reminder.minute,
          reminder.label,
          reminder.isEnabled ? 1 : 0,
          reminder.daysOfWeek.join(','),
        ],
      );
      return db.lastInsertRowId;
    } catch (e) {
      throw StorageException('Failed to insert reminder', e);
    }
  }

  List<ReminderRecord> getAllReminders() {
    try {
      final rows = _db.rawDb.select(
        'SELECT * FROM reminders ORDER BY hour, minute ASC;',
      );
      return rows.map(_mapReminderRow).toList();
    } catch (e) {
      throw StorageException('Failed to query reminders', e);
    }
  }

  Future<void> updateReminder(ReminderRecord reminder) async {
    if (reminder.id == null) return;
    try {
      _db.rawDb.execute(
        '''
        UPDATE reminders
        SET hour = ?, minute = ?, label = ?, is_enabled = ?, days_of_week = ?
        WHERE id = ?;
      ''',
        [
          reminder.hour,
          reminder.minute,
          reminder.label,
          reminder.isEnabled ? 1 : 0,
          reminder.daysOfWeek.join(','),
          reminder.id,
        ],
      );
    } catch (e) {
      throw StorageException('Failed to update reminder: ${reminder.id}', e);
    }
  }

  Future<void> deleteReminder(int id) async {
    try {
      _db.rawDb.execute('DELETE FROM reminders WHERE id = ?;', [id]);
    } catch (e) {
      throw StorageException('Failed to delete reminder: $id', e);
    }
  }

  ReminderRecord _mapReminderRow(Row r) {
    final daysStr = r['days_of_week'] as String;
    return ReminderRecord(
      id: r['id'] as int,
      hour: r['hour'] as int,
      minute: r['minute'] as int,
      label: r['label'] as String,
      isEnabled: (r['is_enabled'] as int) == 1,
      daysOfWeek: daysStr.isNotEmpty
          ? daysStr.split(',').map(int.parse).toList()
          : const [],
    );
  }
}
