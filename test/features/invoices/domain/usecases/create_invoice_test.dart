import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_system/core/common/enums/invoice_status.dart';
import 'package:property_management_system/core/common/models/money.dart';
import 'package:property_management_system/core/errors/failure.dart';
import 'package:property_management_system/core/contracts/audit_logger.dart';
import 'package:property_management_system/features/invoices/domain/entities/invoice.dart';
import 'package:property_management_system/features/invoices/domain/entities/invoice_line.dart';
import 'package:property_management_system/features/invoices/domain/entities/invoice_adjustment.dart';
import 'package:property_management_system/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:property_management_system/features/invoices/domain/usecases/create_invoice.dart';

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
  int _invoiceIdCounter = 1;

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
    final id = _invoiceIdCounter++;
    final saved = invoice.copyWith(id: id);
    invoices[id] = saved;
    return id;
  }

  @override
  Future<void> updateInvoice(Invoice invoice, int userId) async {
    // not used
  }

  @override
  Future<void> addInvoiceLine(dynamic line, int userId) async {
    // not used
  }

  @override
  Future<void> removeInvoiceLine(int lineId, int userId) async {
    // not used
  }

  @override
  Future<void> addInvoiceAdjustment(dynamic adjustment, int userId) async {
    // not used
  }

  @override
  Future<void> issueInvoice(int invoiceId, Money frozenTotal, int userId) async {
    // not used
  }

  @override
  Future<void> cancelInvoice(int invoiceId, int userId) async {
    // not used
  }

  @override
  Future<int?> getInvoiceIdByLineId(int lineId) async {
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getUninvoicedBookings() async {
    return [];
  }
}

void main() {
  late FakeInvoiceRepository repository;
  late FakeAuditLogger auditLogger;
  late CreateInvoice useCase;

  setUp(() {
    repository = FakeInvoiceRepository();
    auditLogger = FakeAuditLogger();
    useCase = CreateInvoice(repository, auditLogger);
  });

  Invoice createTemplateInvoice({required int bookingId, List<InvoiceLine> lines = const [], List<InvoiceAdjustment> adjustments = const []}) {
    return Invoice(
      id: null,
      uuid: '',
      bookingId: bookingId,
      invoiceNumber: 'INV-$bookingId',
      totalAmount: const Money(0),
      status: InvoiceStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lines: lines,
      adjustments: adjustments,
    );
  }

  test('should throw ValidationFailure if bookingId is <= 0', () async {
    final invoice = createTemplateInvoice(bookingId: 0);
    expect(
      () => useCase(invoice, 1),
      throwsA(isA<ValidationFailure>().having((f) => f.code, 'code', 'INVALID_BOOKING_LINK')),
    );
  });

  test('should throw BusinessRuleFailure if an invoice already exists for this booking', () async {
    final existing = createTemplateInvoice(bookingId: 10).copyWith(id: 1);
    repository.invoices[1] = existing;

    final invoice = createTemplateInvoice(bookingId: 10);
    expect(
      () => useCase(invoice, 1),
      throwsA(isA<BusinessRuleFailure>().having((f) => f.code, 'code', 'DUPLICATE_BOOKING_INVOICE')),
    );
  });

  test('should throw BusinessRuleFailure if lines are empty', () async {
    final invoice = createTemplateInvoice(bookingId: 10, lines: const []);
    expect(
      () => useCase(invoice, 1),
      throwsA(isA<BusinessRuleFailure>().having((f) => f.code, 'code', 'EMPTY_INVOICE_NOT_ALLOWED')),
    );
  });

  test('should throw ValidationFailure if any line quantity is <= 0', () async {
    final lines = [
      InvoiceLine(
        description: 'Room Charge',
        quantity: 0,
        unitPrice: const Money(100),
        lineTotal: const Money(0),
      ),
    ];
    final invoice = createTemplateInvoice(bookingId: 10, lines: lines);
    expect(
      () => useCase(invoice, 1),
      throwsA(isA<ValidationFailure>().having((f) => f.code, 'code', 'INVALID_QUANTITY')),
    );
  });

  test('should throw ValidationFailure if any line unitPrice is negative', () async {
    final lines = [
      InvoiceLine(
        description: 'Room Charge',
        quantity: 1,
        unitPrice: const Money(-100),
        lineTotal: const Money(-100),
      ),
    ];
    final invoice = createTemplateInvoice(bookingId: 10, lines: lines);
    expect(
      () => useCase(invoice, 1),
      throwsA(isA<ValidationFailure>().having((f) => f.code, 'code', 'INVALID_UNIT_PRICE')),
    );
  });

  test('should throw ValidationFailure if any adjustment amount is 0', () async {
    final lines = [
      InvoiceLine.create(description: 'Room Charge', quantity: 1, unitPrice: const Money(100)),
    ];
    final adjustments = [
      InvoiceAdjustment(
        adjustmentType: InvoiceAdjustmentType.discount,
        amount: const Money(0),
        reason: 'Zero Discount',
        createdAt: DateTime.now(),
      ),
    ];
    final invoice = createTemplateInvoice(bookingId: 10, lines: lines, adjustments: adjustments);
    expect(
      () => useCase(invoice, 1),
      throwsA(isA<ValidationFailure>().having((f) => f.code, 'code', 'INVALID_ADJUSTMENT_AMOUNT')),
    );
  });

  test('should successfully create invoice, auto-generate uuid, and log audit event', () async {
    final lines = [
      InvoiceLine.create(description: 'Room Charge', quantity: 2, unitPrice: const Money(100)),
    ];
    final invoice = createTemplateInvoice(bookingId: 10, lines: lines);

    final id = await useCase(invoice, 42);

    expect(id, 1);
    expect(repository.invoices[1], isNotNull);
    expect(repository.invoices[1]!.uuid, isNotEmpty);
    expect(repository.invoices[1]!.status, InvoiceStatus.draft);
    expect(auditLogger.logCount, 1);
    expect(auditLogger.loggedEvents.first['userId'], 42);
    expect(auditLogger.loggedEvents.first['entityId'], 1);
    expect(auditLogger.loggedEvents.first['action'], 'Create Invoice');
  });
}
