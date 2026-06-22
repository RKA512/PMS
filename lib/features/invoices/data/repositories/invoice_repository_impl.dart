/// Why the file exists:
/// Implements [InvoiceRepository] using sqflite, managing transactions,
/// ensuring safe updates, freezing totals, dynamic outstanding calculations, and audit logging.
library;

import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/common/enums/invoice_status.dart';
import '../../../../core/common/models/money.dart';
import '../../../../core/services/audit_service.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_adjustment.dart';
import '../../domain/entities/invoice_line.dart';
import '../models/invoice_model.dart';
import '../models/invoice_line_model.dart';
import '../models/invoice_adjustment_model.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final _dbHelper = DatabaseHelper.instance;

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

      final List<Invoice> results = [];
      for (final map in maps) {
        final id = map['id'] as int;

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
        // Enforce that only one invoice exists per booking to prevent duplicate financial ledgers
        final existing = await txn.query(
          'invoices',
          where: 'booking_id = ?',
          whereArgs: [invoice.bookingId],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          throw const BusinessRuleFailure(
            code: 'DUPLICATE_BOOKING_INVOICE',
            message: 'تنبيه مالي: يوجد بالفعل فاتورة مرتبطة بهذا الحجز ومن غير المسموح إنشاء فاتورة مكررة لنفس الحجز.',
          );
        }

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

        // Log audit event
        await AuditService.instance.log(
          userId: userId,
          entityType: 'Invoice',
          entityId: id,
          action: 'Create Invoice',
          description: 'تم إنشاء مسودة فاتورة جديدة برقم ${invoice.invoiceNumber}.',
        );

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
          throw const DatabaseFailure(
            code: 'INVOICE_NOT_FOUND',
            message: 'الفاتورة غير موجودة في قاعدة البيانات.',
          );
        }

        final currentStatus = InvoiceStatus.fromJson(existingMaps.first['status'] as String);
        if (currentStatus != InvoiceStatus.draft) {
          throw const BusinessRuleFailure(
            code: 'INVOICE_NOT_EDITABLE',
            message: 'تعديل الفاتورة مرفوض: الفواتير الصادرة أو المغلقة غير قابلة للتعديل المباشر.',
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

        // Log audit
        await AuditService.instance.log(
          userId: userId,
          entityType: 'Invoice',
          entityId: invoice.id!,
          action: 'Update Invoice',
          description: 'تم تحديث الخطوط والتعديلات الخاصة بمسودة الفاتورة ${invoice.invoiceNumber}.',
        );
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
        final existing = await txn.query(
          'invoices',
          where: 'id = ?',
          whereArgs: [line.invoiceId],
          limit: 1,
        );
        if (existing.isEmpty) {
          throw const DatabaseFailure(
            code: 'INVOICE_NOT_FOUND',
            message: 'الفاتورة المستهدفة غير موجودة.',
          );
        }
        final status = InvoiceStatus.fromJson(existing.first['status'] as String);
        if (status != InvoiceStatus.draft) {
          throw const BusinessRuleFailure(
            code: 'INVOICE_NOT_EDITABLE',
            message: 'تعديل الفاتورة مرفوض: لا يمكن إضافة بنود إلا للفواتير التي في حالة مسودة.',
          );
        }

        await txn.insert('invoice_lines', InvoiceLineModel.toMap(line));

        await AuditService.instance.log(
          userId: userId,
          entityType: 'Invoice',
          entityId: line.invoiceId!,
          action: 'Add Line',
          description: 'تمت إضافة بند جديد: ${line.description} بقيمة ${line.lineTotal}.',
        );
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
          throw const DatabaseFailure(
            code: 'LINE_NOT_FOUND',
            message: 'بند الفاتورة غير موجود.',
          );
        }

        final invoiceId = lineMaps.first['invoice_id'] as int;
        final existing = await txn.query(
          'invoices',
          where: 'id = ?',
          whereArgs: [invoiceId],
          limit: 1,
        );

        final status = InvoiceStatus.fromJson(existing.first['status'] as String);
        if (status != InvoiceStatus.draft) {
          throw const BusinessRuleFailure(
            code: 'INVOICE_NOT_EDITABLE',
            message: 'تعديل الفاتورة مرفوض: تعذر حذف البنود لغير الفاتورة المسودة.',
          );
        }

        await txn.delete(
          'invoice_lines',
          where: 'id = ?',
          whereArgs: [lineId],
        );

        await AuditService.instance.log(
          userId: userId,
          entityType: 'Invoice',
          entityId: invoiceId,
          action: 'Remove Line',
          description: 'تم حذف البند "${lineMaps.first['description']}" من مسودة الفاتورة.',
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
        final existing = await txn.query(
          'invoices',
          where: 'id = ?',
          whereArgs: [adjustment.invoiceId],
          limit: 1,
        );
        if (existing.isEmpty) {
          throw const DatabaseFailure(
            code: 'INVOICE_NOT_FOUND',
            message: 'الفاتورة المستهدفة غير موجودة.',
          );
        }
        final status = InvoiceStatus.fromJson(existing.first['status'] as String);
        if (status != InvoiceStatus.draft) {
          throw const BusinessRuleFailure(
            code: 'INVOICE_NOT_EDITABLE',
            message: 'تعديل الفاتورة مرفوض: لا يمكن إضافة تعديلات إلا في حالة المسودة.',
          );
        }

        await txn.insert('invoice_adjustments', InvoiceAdjustmentModel.toMap(adjustment));

        await AuditService.instance.log(
          userId: userId,
          entityType: 'Invoice',
          entityId: adjustment.invoiceId!,
          action: 'Add Adjustment',
          description: 'تمت إضافة تعديل (${adjustment.adjustmentType.displayName}) بقيمة ${adjustment.amount} وبسبب: ${adjustment.reason}.',
        );
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
        final existing = await txn.query(
          'invoices',
          where: 'id = ?',
          whereArgs: [invoiceId],
          limit: 1,
        );

        if (existing.isEmpty) {
          throw const DatabaseFailure(
            code: 'INVOICE_NOT_FOUND',
            message: 'الفاتورة غير موجودة.',
          );
        }

        final status = InvoiceStatus.fromJson(existing.first['status'] as String);
        if (status != InvoiceStatus.draft) {
          throw const BusinessRuleFailure(
            code: 'INVOICE_NOT_DRAFT',
            message: 'إصدار الفاتورة مرفوض: الفاتورة بالفعل صادرة أو في وضع آخر غير مسودة.',
          );
        }

        // Verify that the invoice has at least one line before issuing
        final lines = await txn.query(
          'invoice_lines',
          where: 'invoice_id = ?',
          whereArgs: [invoiceId],
        );
        if (lines.isEmpty) {
          throw const BusinessRuleFailure(
            code: 'EMPTY_INVOICE_ISSUE_REJECTED',
            message: 'إصدار الفاتورة مرفوض: يجب أن تحتوي الفاتورة على بند مالي واحد على الأقل قبل إصدارها.',
          );
        }

        final now = DateTime.now().toIso8601String();
        await txn.update(
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

        await AuditService.instance.log(
          userId: userId,
          entityType: 'Invoice',
          entityId: invoiceId,
          action: 'Issue Invoice',
          description: 'تم إصدار الفاتورة وتجميد المجموع المالي النهائي عند ${frozenTotal.toString()}.',
        );
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
        final existing = await txn.query(
          'invoices',
          where: 'id = ?',
          whereArgs: [invoiceId],
          limit: 1,
        );

        if (existing.isEmpty) {
          throw const DatabaseFailure(
            code: 'INVOICE_NOT_FOUND',
            message: 'الفاتورة غير موجودة.',
          );
        }

        final status = InvoiceStatus.fromJson(existing.first['status'] as String);
        if (status == InvoiceStatus.paid) {
          throw const BusinessRuleFailure(
            code: 'CANCEL_PAID_INVOICE_REJECTED',
            message: 'إلغاء الفاتورة مرفوض: الفاتورة مدفوعة بالكامل ولا يمكن إلغاؤها.',
          );
        }
        if (status == InvoiceStatus.cancelled) {
          throw const BusinessRuleFailure(
            code: 'ALREADY_CANCELLED',
            message: 'الفاتورة ملغاة بالفعل.',
          );
        }

        final now = DateTime.now().toIso8601String();
        await txn.update(
          'invoices',
          {
            'status': InvoiceStatus.cancelled.name,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [invoiceId],
        );

        await AuditService.instance.log(
          userId: userId,
          entityType: 'Invoice',
          entityId: invoiceId,
          action: 'Cancel Invoice',
          description: 'تم إلغاء الفاتورة بالكامل وتغيير حالتها إلى ملغاة.',
        );
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
  Future<Money> calculateOutstandingBalance(int invoiceId) async {
    try {
      final db = await _dbHelper.database;
      // Get the total_amount stored in the invoice
      final invoiceMaps = await db.query(
        'invoices',
        columns: ['total_amount', 'status'],
        where: 'id = ?',
        whereArgs: [invoiceId],
        limit: 1,
      );

      if (invoiceMaps.isEmpty) {
        return const Money(0);
      }

      final status = InvoiceStatus.fromJson(invoiceMaps.first['status'] as String);
      
      // Calculate total amount. If status is Draft, we dynamically compute totalAmount because it's not frozen yet!
      int invoiceTotalMinor = 0;
      if (status == InvoiceStatus.draft) {
        // Query lines and adjustments dynamically for draft
        final lines = await db.query('invoice_lines', columns: ['line_total'], where: 'invoice_id = ?', whereArgs: [invoiceId]);
        final adjs = await db.query('invoice_adjustments', columns: ['amount', 'adjustment_type'], where: 'invoice_id = ?', whereArgs: [invoiceId]);
        
        int subtotal = lines.fold<int>(0, (sum, row) => sum + (row['line_total'] as int));
        int adjustmentsSum = 0;
        for (final adj in adjs) {
          final amt = adj['amount'] as int;
          final type = InvoiceAdjustmentType.fromString(adj['adjustment_type'] as String);
          if (type == InvoiceAdjustmentType.discount) {
            adjustmentsSum -= amt.abs();
          } else {
            adjustmentsSum += amt;
          }
        }
        invoiceTotalMinor = subtotal + adjustmentsSum;
        if (invoiceTotalMinor < 0) invoiceTotalMinor = 0;
      } else {
        invoiceTotalMinor = invoiceMaps.first['total_amount'] as int;
      }

      // Query payments table securely
      final List<Map<String, dynamic>> res = await db.rawQuery('''
        SELECT 
          SUM(CASE WHEN payment_type = 'incoming' THEN amount ELSE 0 END) as incoming,
          SUM(CASE WHEN payment_type = 'refund' THEN amount ELSE 0 END) as refund
        FROM payments 
        WHERE invoice_id = ?
      ''', [invoiceId]);

      final incoming = res.first['incoming'] as int? ?? 0;
      final refund = res.first['refund'] as int? ?? 0;
      final netPaid = incoming - refund;

      final balanceMinor = invoiceTotalMinor - netPaid;
      return Money(balanceMinor < 0 ? 0 : balanceMinor);
    } catch (e) {
      throw DatabaseFailure(
        code: 'OUTSTANDING_BALANCE_CALCULATION_FAILED',
        message: 'فشل حساب الرصيد المستحق ديناميكياً: $e',
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
