/// Why this file exists:
/// Implementation of UnitRepository contract interfacing with sqflite.
/// Follows [Architecture Rule AR-302] and logs Unit audit updates.
library;

import '../../../../core/database/database_helper.dart';
import '../../../../core/common/enums/unit_status.dart';
import '../../domain/entities/unit.dart';
import '../../domain/entities/unit_type.dart';
import '../../domain/repositories/unit_repository.dart';
import '../models/unit_model.dart';

class UnitRepositoryImpl implements UnitRepository {
  final _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<Unit>> getUnits({required int propertyId, bool includeArchived = false}) async {
    final db = await _dbHelper.executor;
    final List<Map<String, dynamic>> maps;
    if (includeArchived) {
      maps = await db.query(
        'units',
        where: 'property_id = ?',
        whereArgs: [propertyId],
        orderBy: 'unit_number ASC',
      );
    } else {
      maps = await db.query(
        'units',
        where: 'property_id = ? AND deleted_at IS NULL',
        whereArgs: [propertyId],
        orderBy: 'unit_number ASC',
      );
    }
    return maps.map((map) => UnitModel.fromMap(map)).toList();
  }

  @override
  Future<Unit?> getUnitById(int id) async {
    final db = await _dbHelper.executor;
    final maps = await db.query(
      'units',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UnitModel.fromMap(maps.first);
  }

  @override
  Future<Unit?> getUnitByUuid(String uuid) async {
    final db = await _dbHelper.executor;
    final maps = await db.query(
      'units',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UnitModel.fromMap(maps.first);
  }

  @override
  Future<int> createUnit(Unit unit) async {
    final db = await _dbHelper.executor;
    final id = await db.insert('units', UnitModel.toMap(unit));
    return id;
  }

  @override
  Future<void> updateUnit(Unit unit) async {
    if (unit.id == null) return;
    final db = await _dbHelper.executor;

    await db.update(
      'units',
      UnitModel.toMap(unit),
      where: 'id = ?',
      whereArgs: [unit.id],
    );
  }

  @override
  Future<void> archiveUnit(int id) async {
    final db = await _dbHelper.executor;
    final nowString = DateTime.now().toIso8601String();

    await db.update(
      'units',
      {
        'deleted_at': nowString,
        'status': UnitStatus.archived.toJson(),
        'updated_at': nowString,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateUnitStatus({required int unitId, required String status}) async {
    final db = await _dbHelper.executor;
    await db.update(
      'units',
      {'status': status},
      where: 'id = ?',
      whereArgs: [unitId],
    );
  }

  @override
  Future<List<UnitType>> getUnitTypes() async {
    final db = await _dbHelper.executor;
    final maps = await db.query('unit_types', orderBy: 'name ASC');
    return maps.map((map) {
      return UnitType(
        id: map['id'] as int,
        name: map['name'] as String,
        description: map['description'] as String?,
      );
    }).toList();
  }
}
