import 'package:flutter/material.dart';
import 'package:simple_biometric/model/req_checklog.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inTrax.db');
    final db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute(
          "CREATE TABLE Presence(id INTEGER PRIMARY KEY AUTOINCREMENT, checklog_id2 TEXT NOT NULL, checklog_timestamp TEXT NOT NULL, checklog_event TEXT NOT NULL, checklog_latitude TEXT NOT NULL, checklog_longitude TEXT NOT NULL, image TEXT NOT NULL, employee_id TEXT NOT NULL, address TEXT NOT NULL, machine_id TEXT NOT NULL, company_id TEXT NOT NULL)");
    });
    return db;
  }

  Future<int> insertPresence(ReqChecklog data) async {
    final Database db = await initDatabase();
    final id = await db.insert('Presence', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    debugPrint("row inserted -> $id");
    return id;
  }

  Future<List<ReqChecklog>> getPresences() async {
    final Database db = await initDatabase();
    const query = "SELECT * FROM Presence ORDER BY checklog_timestamp DESC";
    final List<Map<String, Object?>> queryResult = await db.rawQuery(query);
    debugPrint("List -> $queryResult");
    return queryResult.map((Map<String, Object?> map) {
      return ReqChecklog(
        checklog_id2: map['checklog_id2'] as String?,
        checklog_timestamp: map['checklog_timestamp'] as String?,
        checklog_event: map['checklog_event'] as String?,
        checklog_latitude: map['checklog_latitude'] as String?,
        checklog_longitude: map['checklog_longitude'] as String?,
        image: map['image'] as String?,
        employee_id: map['employee_id'] as String?,
        address: map['address'] as String?,
        machine_id: map['machine_id'] as String?,
        company_id: map['company_id'] as String?,
      );
    }).toList();
  }

  Future<int> deletePresence(String id) async {
    final Database db = await initDatabase();
    var result = 0;
    try {
      debugPrint("Delete data ID -> $id");
      result = await db
          .delete("Presence", where: "checklog_timestamp = ?", whereArgs: [id]);
      debugPrint("result delete -> $result");
    } catch (e) {
      debugPrint("Error delete data: $e");
    }
    return result;
  }
}
