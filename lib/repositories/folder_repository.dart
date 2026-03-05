import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/folder.dart';

class FolderRepository {
  Future<int> createFolder(Folder folder) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert(
      'folders',
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Folder>> getFolders() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('folders', orderBy: 'folder_name ASC');
    return rows.map((e) => Folder.fromMap(e)).toList();
  }

  Future<int> updateFolder(Folder folder) async {
    final db = await DatabaseHelper.instance.database;
    return db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<int> deleteFolder(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getCardCountForFolder(int folderId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM cards WHERE folder_id = ?',
      [folderId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}