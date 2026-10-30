import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/drift/app_database.dart';
import 'session_repository.dart';
import '../../domain/profile/user_profile.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return UserProfileRepository(db);
});

class UserProfileRepository {
  UserProfileRepository(this._db);
  final AppDatabase _db;

  Future<UserProfile?> getProfile() async {
    final rows = _db.rawDb.select(
      'SELECT * FROM user_profiles ORDER BY updated_at DESC LIMIT 1;',
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return UserProfile(
      id: r['id'] as String,
      fullName: r['full_name'] as String,
      age: r['age'] as int,
      gender: r['gender'] as String,
      heightCm: (r['height_cm'] as num).toDouble(),
      weightKg: (r['weight_kg'] as num).toDouble(),
      baselineSbp: r['baseline_sbp'] != null ? (r['baseline_sbp'] as num).toDouble() : null,
      baselineDbp: r['baseline_dbp'] != null ? (r['baseline_dbp'] as num).toDouble() : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    _db.rawDb.execute(
      '''
      INSERT OR REPLACE INTO user_profiles (
        id, full_name, age, gender, height_cm, weight_kg, baseline_sbp, baseline_dbp, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        profile.id,
        profile.fullName,
        profile.age,
        profile.gender,
        profile.heightCm,
        profile.weightKg,
        profile.baselineSbp,
        profile.baselineDbp,
        profile.createdAt.millisecondsSinceEpoch,
        profile.updatedAt.millisecondsSinceEpoch,
      ],
    );
  }
}
