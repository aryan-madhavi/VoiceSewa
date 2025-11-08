import 'package:sqflite/sqflite.dart';

class WorkerProfile {
  final String workerId; 
  final String name;
  final String phone;
  final String language; 
  final String skillCategory; 
  final String? bio;
  final int updatedAt; 
  
  WorkerProfile({
    required this.workerId,
    required this.name,
    required this.phone,
    required this.language,
    required this.skillCategory,
    required this.updatedAt,
    this.bio,
  });

  Map<String, Object?> toMap() => {
    'worker_id': workerId,
    'name': name,
    'phone': phone,
    'language': language,
    'skill_category': skillCategory,
    'bio': bio,
    'updated_at': updatedAt,
  };

  static WorkerProfile fromMap(Map<String, Object?> m) => WorkerProfile(
    workerId: m['worker_id'] as String,
    name: m['name'] as String,
    phone: m['phone'] as String,
    language: m['language'] as String,
    skillCategory: m['skill_category'] as String,
    bio: m['bio'] as String?,
    updatedAt: m['updated_at'] as int,
  );
}

class WorkerProfileTable {
  static const table = 'worker_profile';
  static const createSql = '''
  CREATE TABLE IF NOT EXISTS $table(
    worker_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    language TEXT NOT NULL,
    skill_category TEXT NOT NULL,
    bio TEXT,
    updated_at INTEGER NOT NULL
  );
  ''';

  final Database db;
  WorkerProfileTable(this.db);

  Future<int> upsert(WorkerProfile p) async {
    return db.insert(table, p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<WorkerProfile?> get(String workerId) async {
    final rows = await db.query(table, where: 'worker_id=?', whereArgs: [workerId], limit: 1);
    if (rows.isEmpty) return null;
    return WorkerProfile.fromMap(rows.first);
  }

  Future<List<WorkerProfile>> all() async {
    final rows = await db.query(table, orderBy: 'updated_at DESC');
    return rows.map(WorkerProfile.fromMap).toList();
  }

  Future<int> delete(String workerId) => db.delete(table, where: 'worker_id=?', whereArgs: [workerId]);
}
