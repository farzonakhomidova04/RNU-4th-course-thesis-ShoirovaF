import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/tourist_object.dart';

class LocalDbService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // Initialize FFI for Windows
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, 'shohimardon_tour.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tourist_objects(
            id TEXT PRIMARY KEY,
            nameUz TEXT,
            nameRu TEXT,
            nameEn TEXT,
            descriptionUz TEXT,
            descriptionRu TEXT,
            descriptionEn TEXT,
            lat REAL,
            lng REAL,
            imageUrl TEXT,
            category TEXT,
            isRecommended INTEGER,
            rating REAL DEFAULT 0.0,
            reviewCount INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE tourist_objects ADD COLUMN rating REAL DEFAULT 0.0');
          await db.execute('ALTER TABLE tourist_objects ADD COLUMN reviewCount INTEGER DEFAULT 0');
        }
      },
    );
  }

  Future<void> insertTouristObject(TouristObject object) async {
    final db = await database;
    await db.insert(
      'tourist_objects',
      object.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMultipleTouristObjects(List<TouristObject> objects) async {
    final db = await database;
    Batch batch = db.batch();
    for (var object in objects) {
      batch.insert(
        'tourist_objects',
        object.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<TouristObject>> getAllTouristObjects() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tourist_objects');
    return List.generate(maps.length, (i) {
      return TouristObject.fromMap(maps[i]);
    });
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('tourist_objects');
  }
}
