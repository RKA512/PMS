/// Why this file exists:
/// Implementation of PropertyRepository contract.
/// Standard SQLite interactions using the database helper.
/// Triggers AP-1000 Property Audit Rules on changes.
library;

import '../../../../core/database/database_helper.dart';
import '../../../../core/services/audit_service.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_type.dart';
import '../../domain/entities/property_settings.dart';
import '../../domain/repositories/property_repository.dart';
import '../models/property_model.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<Property>> getProperties({bool includeArchived = false}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps;
    if (includeArchived) {
      maps = await db.query('properties', orderBy: 'name ASC');
    } else {
      maps = await db.query(
        'properties',
        where: 'deleted_at IS NULL',
        orderBy: 'name ASC',
      );
    }
    return maps.map((map) => PropertyModel.fromMap(map)).toList();
  }

  @override
  Future<Property?> getPropertyById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'properties',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PropertyModel.fromMap(maps.first);
  }

  @override
  Future<Property?> getPropertyByUuid(String uuid) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'properties',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PropertyModel.fromMap(maps.first);
  }

  @override
  Future<int> createProperty(Property property) async {
    final db = await _dbHelper.database;
    final id = await db.insert('properties', PropertyModel.toMap(property));
    
    // Log Audit Event
    await AuditService.instance.log(
      propertyId: id,
      userId: 1, // Defaulting to system admin/owner for initial setup flow as standard
      entityType: 'Property',
      entityId: id,
      action: 'Create Property',
      description: 'Created property: ${property.name} with currency ${property.currencyCode}',
      newValues: PropertyModel.toMap(property..copyWith(id: id)),
    );

    return id;
  }

  @override
  Future<void> updateProperty(Property property) async {
    if (property.id == null) return;
    final db = await _dbHelper.database;
    
    final oldProperty = await getPropertyById(property.id!);
    final oldMap = oldProperty != null ? PropertyModel.toMap(oldProperty) : null;

    await db.update(
      'properties',
      PropertyModel.toMap(property),
      where: 'id = ?',
      whereArgs: [property.id],
    );

    // Log Audit Event
    await AuditService.instance.log(
      propertyId: property.id!,
      userId: 1,
      entityType: 'Property',
      entityId: property.id!,
      action: 'Update Property',
      description: 'Updated property: ${property.name}',
      oldValues: oldMap,
      newValues: PropertyModel.toMap(property),
    );
  }

  @override
  Future<void> archiveProperty(int id) async {
    final db = await _dbHelper.database;
    final nowString = DateTime.now().toIso8601String();
    
    final property = await getPropertyById(id);
    if (property == null) return;
    final oldMap = PropertyModel.toMap(property);

    await db.update(
      'properties',
      {
        'deleted_at': nowString,
        'status': 'Archived',
        'updated_at': nowString,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    // Log Audit Event
    await AuditService.instance.log(
      propertyId: id,
      userId: 1,
      entityType: 'Property',
      entityId: id,
      action: 'Archive Property',
      description: 'Archived property: ${property.name}',
      oldValues: oldMap,
      newValues: {
        'deleted_at': nowString,
        'status': 'Archived',
        'updated_at': nowString,
      },
    );
  }

  @override
  Future<List<PropertyType>> getPropertyTypes() async {
    final db = await _dbHelper.database;
    final maps = await db.query('property_types', orderBy: 'name ASC');
    return maps.map((map) {
      return PropertyType(
        id: map['id'] as int,
        name: map['name'] as String,
        description: map['description'] as String?,
      );
    }).toList();
  }

  @override
  Future<List<PropertySettings>> getPropertySettings(int propertyId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'property_settings',
      where: 'property_id = ?',
      whereArgs: [propertyId],
    );
    return maps.map((map) {
      return PropertySettings(
        id: map['id'] as int?,
        propertyId: map['property_id'] as int,
        settingKey: map['setting_key'] as String,
        settingValue: map['setting_value'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
    }).toList();
  }

  @override
  Future<void> savePropertySetting(int propertyId, String key, String value) async {
    final db = await _dbHelper.database;
    final nowString = DateTime.now().toIso8601String();

    final existing = await db.query(
      'property_settings',
      where: 'property_id = ? AND setting_key = ?',
      whereArgs: [propertyId, key],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('property_settings', {
        'property_id': propertyId,
        'setting_key': key,
        'setting_value': value,
        'created_at': nowString,
        'updated_at': nowString,
      });
    } else {
      await db.update(
        'property_settings',
        {
          'setting_value': value,
          'updated_at': nowString,
        },
        where: 'property_id = ? AND setting_key = ?',
        whereArgs: [propertyId, key],
      );
    }
  }

  @override
  Future<String?> getPropertySettingValue(int propertyId, String key) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'property_settings',
      columns: ['setting_value'],
      where: 'property_id = ? AND setting_key = ?',
      whereArgs: [propertyId, key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['setting_value'] as String?;
  }
}
