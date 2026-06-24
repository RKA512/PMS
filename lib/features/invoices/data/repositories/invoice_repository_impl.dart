/// Why the file exists:
/// Implements [InvoiceRepository] using sqflite, managing transactions,
/// ensuring safe updates, freezing totals, dynamic outstanding calculations, and audit logging.
library;

import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/common/enums/invoice_status.dart';
import '../../../../core/common/models/money.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_adjustment.dart';
import '../../domain/entities/invoice_line.dart';
import '../models/invoice_model.dart';
import '../models/invoice_line_model.dart';
import '../models/invoice_adjustment_model.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final _dbHelper = DatabaseHelper.instance;

  InvoiceRepositoryImpl();

  @override
  Future<Invoice?> getInvoiceById(int id) async {
    try {
      final db = await _dbHelper.database;
      final invoiceMaps = await db.query(
        'invoices',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (invoiceMaps.isEmpty) return null;

      final lineMaps = await db.query(
        'invoice_lines',
        where: 'invoice_id = ?',
        whereArgs: [id],
      );

      final adjustmentMaps = await db.query(
        'invoice_adjustments',
        where: 'invoice_id = ?',
        whereArgs: [id],
      );

      final lines = lineMaps.map((m) => InvoiceLineModel.fromMap(m)).toList();
      final adjustments = adjustmentMaps.map((m) => InvoiceAdjustmentModel.fromMap(m)).toList();

      return InvoiceModel.fromMap(
        invoiceMaps.first,
        lines: lines,
        adjustments: adjustments,
      );
    } catch (e) {
      throw DatabaseFailure(
        code: 'GET_INVOICE_BY_ID_FAILED',
        message: 'حدث خطأ أثناء جلب الفاتورة من قاعدة البيانات: $e',
      );
    }
  }

  @override
  Future<Invoice?> getInvoiceByBookingId(int bookingId) async {
    try {
      final db = await _dbHelper.database;
      final invoiceMaps = await db.query(
        'invoices',
        where: 'booking_id = ?',
        whereArgs: [bookingId],
        limit: 1,
      );

      if (invoiceMaps.isEmpty) return null;
      final id = invoiceMaps.first['id'] as int;

      final lineMaps = await db.query(
        'invoice_lines',
        where: 'invoice_id = ?',
        whereArgs: [id],
      );

      final adjustmentMaps = await db.query(
        'invoice_adjustments',
        where: 'invoice_id = ?',
        whereArgs: [id],
      );

      final lines = lineMaps.map((m) => InvoiceLineModel.fromMap(m)).toList();
      final adjustments = adjustmentMaps.map((m) => InvoiceAdjustmentModel.fromMap(m)).toList();

      return InvoiceModel.fromMap(
        invoiceMaps.first,
        lines: lines,
        adjustments: adjustments,
      );
    } catch (e) {
      throw DatabaseFailure(
        code: 'GET_INVOICE_BY_BOOKING_FAILED',
        message: 'حدث خطأ أثناء جلب فاتورة الحجز: $e',
      );
    }
  }

  @override
  Future<List<Invoice>> getInvoices(int accountId) async {
    try {
      final db = await _dbHelper.database;
      
      // Invoices belong to bookings, which belong to properties, which belong to accounts.
      final maps = await db.rawQuery('''
        SELECT i.* FROM invoices i
        JOIN bookings b ON i.booking_id = b.id
        JOIN properties p ON b.property_id = p.id
        WHERE p.account_id = ?
        ORDER BY i.created_at DESC
      ''', [accountId]);

      if (maps.isEmpty) return const [];

      final invoiceIds = maps.map((row) => row['id'] as int).toList();
      final placeholders = List.filled(invoiceIds.length, '?').join(', ');

      // Batch query lines & adjustments for all retrieved invoices of this account
      final lineMaps = await db.rawQuery('''
        SELECT * FROM invoice_lines WHERE invoice_id IN ($placeholders)
      ''', invoiceIds);

      final adjustmentMaps = await db.rawQuery('''
        SELECT * FROM invoice_adjustments WHERE invoice_id IN ($placeholders)
      ''', invoiceIds);

      // Group elements by parent invoice ID
      final Map<int, List<InvoiceLine>> linesByInvoiceId = {};
      for (final map in lineMaps) {
        final invoiceId = map['invoice_id'] as int;
        final line = InvoiceLineModel.fromMap(map);
        linesByInvoiceId.putIfAbsent(invoiceId, () => []).add(line);
      }

      final Map<int, List<InvoiceAdjustment>> adjustmentsByInvoiceId = {};
      for (final map in adjustmentMaps) {
        final invoiceId = map['invoice_id'] as int;
        final adj = InvoiceAdjustmentModel.fromMap(map);
        adjustmentsByInvoiceId.putIfAbsent(invoiceId, () => []).add(adj);
      }

      final List<Invoice> results = [];
      for (final map in maps) {
        final id = map['id'] as int;
        final lines = linesByInvoiceId[id] ?? [];
        final adjustments = adjustmentsByInvoiceId[id] ?? [];

        results.add(
          InvoiceModel.fromMap(
            map,
            lines: lines,
            adjustments: adjustments,
          ),
        );
      }
      return results;
    } catch (e) {
      throw DatabaseFailure(
        code: 'GET_INVOICES_FAILED',
        message: 'حدث خطأ أثناء جلب الفواتير للحساب من قاعدة البيانات: $e',
      );
    }
  }

  @override
  Future<int> createInvoice(Invoice invoice, int userId) async {
    try {
      final db = await _dbHelper.database;
      return await db.transaction((txn) async {
        final invoiceMap = InvoiceModel.toMap(invoice);
        final id = await txn.insert('invoices', invoiceMap);

        // Insert invoice lines if any exist
        for (final line in invoice.lines) {
          await txn.insert(
            'invoice_lines',
            InvoiceLineModel.toMap(line.copyWith(invoiceId: id)),
          );
        }

        // Insert invoice adjustments if any exist
        for (final adj in invoice.adjustments) {
          await txn.insert(
            'invoice_adjustments',
            InvoiceAdjustmentModel.toMap(adj.copyWith(invoiceId: id)),
          );
        }

        return id;
      });
    } on Failure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure(
        code: 'CREATE_INVOICE_FAILED',
        message: 'فشل إنشاء الفاتورة في قاعدة البيانات: $e',
      );
    }
  }

  @override
  Future<void> updateInvoice(Invoice invoice, int userId) async {
    if (invoice.id == null) {
      throw const ValidationFailure(
        code: 'INVOICE_ID_MISSING',
        message: 'تعذر التحديث: معرف الفاتورة مفقود.',
      );
    }
    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        final existingMaps = await txn.query(
          'invoices',
          where: 'id = ?',
          whereArgs: [invoice.id],
          limit: 1,
        );

        if (existingMaps.isEmpty) {
          throw const ValidationFailure(
            code: 'INVOICE_NOT_FOUND',
            message: 'الفاتورة غير موجودة لتحديثها في النظام.',
          );
        }

        // Perform updates
        final invoiceMap = InvoiceModel.toMap(invoice);
        await txn.update(
          'invoices',
          invoiceMap,
          where: 'id = ?',
          whereArgs: [invoice.id],
        );

        // Re-sync lines (easiest is deleting and recreating lines inside transaction)
        await txn.delete(
          'invoice_lines',
          where: 'invoice_id = ?',
          whereArgs: [invoice.id],
        );
        for (final line in invoice.lines) {
          await txn.insert(
            'invoice_lines',
            InvoiceLineModel.toMap(line.copyWith(invoiceId: invoice.id)),
          );
        }

        // Re-sync adjustments
        await txn.delete(
          'invoice_adjustments',
          where: 'invoice_id = ?',
          whereArgs: [invoice.id],
        );
        for (final adj in invoice.adjustments) {
          await txn.insert(
            'invoice_adjustments',
            InvoiceAdjustmentModel.toMap(adj.copyWith(invoiceId: invoice.id)),
          );
        }
      });
    } on Failure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure(
        code: 'UPDATE_INVOICE_FAILED',
        message: 'فشل تحديث الفاتورة والتزامن: $e',
      );
    }
  }

  @override
  Future<void> addInvoiceLine(InvoiceLine line, int userId) async {
    if (line.invoiceId == null) {
      throw const ValidationFailure(
        code: 'LINE_INVOICE_ID_MISSING',
        message: 'معرف الفاتورة مفقود لخطوط الفاتورة.',
      );
    }
    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        await txn.insert('invoice_lines', InvoiceLineModel.toMap(line));
      });
    } on Failure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure(
        code: 'ADD_INVOICE_LINE_FAILED',
        message: 'فشل إضافة بند الفاتورة: $e',
      );
    }
  }

  @override
  Future<void> removeInvoiceLine(int lineId, int userId) async {
    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        final lineMaps = await txn.query(
          'invoice_lines',
          where: 'id = ?',
          whereArgs: [lineId],
          limit: 1,
        );

        if (lineMaps.isEmpty) {
          throw const ValidationFailure(
            code: 'LINE_NOT_FOUND',
            message: 'بند الفاتورة المطلوب غير موجود في النظام.',
          );
        }

        await txn.delete(
          'invoice_lines',
          where: 'id = ?',
          whereArgs: [lineId],
        );
      });
    } on Failure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure(
        code: 'REMOVE_INVOICE_LINE_FAILED',
        message: 'فشل حذف بند الفاتورة: $e',
      );
    }
  }

  @override
  Future<void> addInvoiceAdjustment(InvoiceAdjustment adjustment, int userId) async {
    if (adjustment.invoiceId == null) {
      throw const ValidationFailure(
        code: 'ADJUSTMENT_INVOICE_ID_MISSING',
        message: 'معرف الفاتورة مفقود في التعديل.',
      );
    }
    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        await txn.insert('invoice_adjustments', InvoiceAdjustmentModel.toMap(adjustment));
      });
    } on Failure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure(
        code: 'ADD_INVOICE_ADJUSTMENT_FAILED',
        message: 'فشل إضافة تعديل الفاتورة: $e',
      );
    }
  }

  @override
  Future<void> issueInvoice(int invoiceId, Money frozenTotal, int userId) async {
    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        final now = DateTime.now().toIso8601String();
        final updatedRows = await txn.update(
          'invoices',
          {
            'status': InvoiceStatus.issued.name,
            'total_amount': frozenTotal.minorUnits, // Freeze the calculated total strictly
            'issued_at': now,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [invoiceId],
        );

        if (updatedRows == 0) {
          throw const ValidationFailure(
            code: 'INVOICE_NOT_FOUND',
            message: 'الفاتورة غير موجودة في قاعدة البيانات.',
          );
        }
      });
    } on Failure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure(
        code: 'ISSUE_INVOICE_FAILED',
        message: 'فشل إصدار وتجميد الفاتورة في قاعدة البيانات: $e',
      );
    }
  }

  @override
  Future<void> cancelInvoice(int invoiceId, int userId) async {
    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        final now = DateTime.now().toIso8601String();
        final updatedRows = await txn.update(
          'invoices',
          {
            'status': InvoiceStatus.cancelled.name,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [invoiceId],
        );

        if (updatedRows == 0) {
          throw const ValidationFailure(
            code: 'INVOICE_NOT_FOUND',
            message: 'الفاتورة غير موجودة لتحديث حالتها إلى ملغاة.',
          );
        }
      });
    } on Failure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure(
        code: 'CANCEL_INVOICE_FAILED',
        message: 'فشل إلغاء الفاتورة في قاعدة البيانات: $e',
      );
    }
  }

  @override
  Future<int?> getInvoiceIdByLineId(int lineId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'invoice_lines',
        columns: ['invoice_id'],
        where: 'id = ?',
        whereArgs: [lineId],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return maps.first['invoice_id'] as int?;
    } catch (e) {
      throw DatabaseFailure(
        code: 'GET_INVOICE_ID_BY_LINE_FAILED',
        message: 'حدث خطأ أثناء جلب معرّف الفاتورة للبند: $e',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUninvoicedBookings() async {
    try {
      final db = await _dbHelper.database;
      return await db.rawQuery('''
        SELECT b.id, b.booking_number, g.full_name as guest_name 
        FROM bookings b 
        JOIN guests g ON b.primary_guest_id = g.id 
        WHERE b.id NOT IN (SELECT booking_id FROM invoices)
      ''');
    } catch (e) {
      throw DatabaseFailure(
        code: 'GET_UNINVOICED_BOOKINGS_FAILED',
        message: 'حدث خطأ أثناء جلب الحجوزات غير المفوترة: $e',
      );
    }
  }
}
