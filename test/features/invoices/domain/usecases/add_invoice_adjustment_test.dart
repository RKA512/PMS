import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_system/core/common/enums/invoice_status.dart';
import 'package:property_management_system/core/common/models/money.dart';
import 'package:property_management_system/core/errors/failure.dart';
import 'package:property_management_system/core/contracts/audit_logger.dart';
import 'package:property_management_system/features/invoices/domain/entities/invoice.dart';
import 'package:property_management_system/features/invoices/domain/entities/invoice_adjustment.dart';
import 'package:property_management_system/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:property_management_system/features/invoices/domain/usecases/add_invoice_adjustment.dart';

class FakeAuditLogger implements AuditLogger {
  int logCount = 0;
  List<Map<String, dynamic>> loggedEvents = [];

  @override
  Future<int> log({
    int? propertyId,
    required int userId,
    required String entityType,
    required int entityId,
    required String action,
    required String description,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    logCount++;
    loggedEvents.add({
      'propertyId': propertyId,
      'userId': userId,
      'entityType': entityType,
      'entityId': entityId,
      'action': action,
      'description': description,
      'oldValues': oldValues,
      'newValues': newValues,
    });
    return logCount;
  }
}

class FakeInvoiceRepository implements InvoiceRepository {
  final Map<int, Invoice> invoices = {};
  final Map<int, int> lineToInvoiceMap = {};
  int _invoiceIdCounter = 1;
  int _lineIdCounter = 1;
  int _adjustmentIdCounter = 1;

  @override
  Future<Invoice?> getInvoiceById(int id) async {
    return invoices[id];
  }

  @override
  Future<Invoice?> getInvoiceByBookingId(int bookingId) async {
    for (final inv in invoices.values) {
      if (inv.bookingId == bookingId) return inv;
    }
    return null;
  }

  @override
  Future<List<Invoice>> getInvoices(int accountId) async {
    return invoices.values.toList();
  }

  @override
  Future<int> createInvoice(Invoice invoice, int userId) async {
    final newId = _invoiceIdCounter++;
    final preparedLines = invoice.lines.map((l) {
      final lineId = _lineIdCounter++;
      lineToInvoiceMap[lineId] = newId;
      return l.copyWith(id: lineId, invoiceId: newId);
    }).toList();

    final preparedAdjustments = invoice.adjustments.map((a) {
      final adjId = _adjustmentIdCounter++;
      return a.copyWith(id: adjId, invoiceId: newId);
    }).toList();

    final saved = invoice.copyWith(
      id: newId,
      lines: preparedLines,
      adjustments: preparedAdjustments,
    );
    invoices[newId] = saved;
    return newId;
  }

  @override
  Future<void> updateInvoice(Invoice invoice, int userId) async {
    if (invoice.id != null) {
      invoices[invoice.id!] = invoice;
    }
  }

  @override
  Future<void> addInvoiceLine(dynamic line, int userId) async {
    // not used in this test
  }

  @override
  Future<void> removeInvoiceLine(int lineId, int userId) async {
    // not used in this test
  }

  @override
  Future<void> addInvoiceAdjustment(InvoiceAdjustment adjustment, int userId) async {
    final invId = adjustment.invoiceId!;
    final inv = invoices[invId];
    if (inv != null) {
      final newAdjId = _adjustmentIdCounter++;
      final addedAdj = adjustment.copyWith(id: newAdjId);
      final updatedAdjustments = List<InvoiceAdjustment>.from(inv.adjustments)..add(addedAdj);
      invoices[invId] = inv.copyWith(adjustments: updatedAdjustments);
    }
  }

  @override
  Future<void> issueInvoice(int invoiceId, Money frozenTotal, int userId) async {
    // not used in this test
  }

  @override
  Future<void> cancelInvoice(int invoiceId, int userId) async {
    // not used in this test
  }

  @override
  Future<int?> getInvoiceIdByLineId(int lineId) async {
    return lineToInvoiceMap[lineId];
  }

  @override
  Future<List<Map<String, dynamic>>> getUninvoicedBookings() async {
    return [];
  }
}

void main() {
  late FakeInvoiceRepository repository;
  late FakeAuditLogger auditLogger;
  late AddInvoiceAdjustment useCase;

  setUp(() {
    repository = FakeInvoiceRepository();
    auditLogger = FakeAuditLogger();
    useCase = AddInvoiceAdjustment(repository, auditLogger);
  });

  Invoice createDraftInvoice({required int id, required int bookingId}) {
    return Invoice(
      id: id,
      uuid: 'invoice-$id',
      bookingId: bookingId,
      invoiceNumber: 'INV-$id',
      totalAmount: const Money(0),
      status: InvoiceStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lines: const [],
      adjustments: const [],
    );
  }

  test('should throw ValidationFailure if invoiceId is null or invalid', () async {
    final adj = InvoiceAdjustment(
      invoiceId: null,
      adjustmentType: InvoiceAdjustmentType.discount,
      amount: const Money(100),
      reason: 'Discount',
      createdAt: declareDateTime,
    );

    expect(
      () => useCase(adj, 1),
      throwsA(isA<ValidationFailure>().having((f) => f.code, 'code', 'INVOICE_ID_REQUIRED')),
    );
  });

  test('should throw ValidationFailure if invoice does not exist', () async {
    final adj = InvoiceAdjustment(
      invoiceId: 99,
      adjustmentType: InvoiceAdjustmentType.discount,
      amount: const Money(100),
      reason: 'Discount',
      createdAt: declareDateTime,
    );

    expect(
      () => useCase(adj, 1),
      throwsA(isA<ValidationFailure>().having((f) => f.code, 'code', 'INVOICE_NOT_FOUND')),
    );
  });

  test('should throw BusinessRuleFailure if invoice is not in Draft status', () async {
    final invoice = createDraftInvoice(id: 1, bookingId: 10).copyWith(status: InvoiceStatus.issued);
    repository.invoices[1] = invoice;

    final adj = InvoiceAdjustment(
      invoiceId: 1,
      adjustmentType: InvoiceAdjustmentType.discount,
      amount: const Money(100),
      reason: 'Discount',
      createdAt: declareDateTime,
    );

    expect(
      () => useCase(adj, 1),
      throwsA(isA<BusinessRuleFailure>().having((f) => f.code, 'code', 'INVOICE_NOT_EDITABLE')),
    );
  });

  test('should throw ValidationFailure if adjustment amount is zero', () async {
    final invoice = createDraftInvoice(id: 1, bookingId: 10);
    repository.invoices[1] = invoice;

    final adj = InvoiceAdjustment(
      invoiceId: 1,
      adjustmentType: InvoiceAdjustmentType.discount,
      amount: const Money(0),
      reason: 'Discount',
      createdAt: declareDateTime,
    );

    expect(
      () => useCase(adj, 1),
      throwsA(isA<ValidationFailure>().having((f) => f.code, 'code', 'INVALID_ADJUSTMENT')),
    );
  });

  test('should successfully add adjustment and log event', () async {
    final invoice = createDraftInvoice(id: 1, bookingId: 10);
    repository.invoices[1] = invoice;

    final adj = InvoiceAdjustment(
      invoiceId: 1,
      adjustmentType: InvoiceAdjustmentType.discount,
      amount: const Money(500),
      reason: 'Friendly discount',
      createdAt: declareDateTime,
    );

    await useCase(adj, 42);

    expect(repository.invoices[1]!.adjustments.length, 1);
    expect(repository.invoices[1]!.adjustments.first.amount, const Money(500));
    expect(auditLogger.logCount, 1);
    expect(auditLogger.loggedEvents.first['userId'], 42);
    expect(auditLogger.loggedEvents.first['entityId'], 1);
    expect(auditLogger.loggedEvents.first['action'], 'Add Adjustment');
  });
}

final declareDateTime = DateTime(2026, 6, 23);
