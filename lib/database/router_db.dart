import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/router_model.dart';

class RouterDB {
  static final RouterDB instance = RouterDB._init();
  static Database? _database;

  RouterDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('router.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE routers (
  id $idType,
  name $textType,
  ip $textType,
  username $textType,
  password $textType,
  port $intType
)
''');
  }

  Future<int> insertRouter(RouterModel router) async {
    final db = await instance.database;
    return await db.insert('routers', router.toMap());
  }

  Future<List<RouterModel>> getAllRouters() async {
    final db = await instance.database;
    final result = await db.query('routers');
    return result.map((map) => RouterModel.fromMap(map)).toList();
  }

  Future<int> updateRouter(RouterModel router) async {
    final db = await instance.database;
    return db.update(
      'routers',
      router.toMap(),
      where: 'id = ?',
      whereArgs: [router.id],
    );
  }

  Future<int> deleteRouter(int id) async {
    final db = await instance.database;
    return await db.delete('routers', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
