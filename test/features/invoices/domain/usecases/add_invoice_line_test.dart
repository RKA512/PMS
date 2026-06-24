import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_system/core/common/enums/invoice_status.dart';
import 'package:property_management_system/core/common/models/money.dart';
import 'package:property_management_system/core/errors/failure.dart';
import 'package:property_management_system/core/contracts/audit_logger.dart';
import 'package:property_management_system/features/invoices/domain/entities/invoice.dart';
import 'package:property_management_system/features/invoices/domain/entities/invoice_line.dart';
import 'package:property_management_system/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:property_management_system/features/invoices/domain/usecases/add_invoice_line.dart';

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
  int _lineIdCounter = 1;

  @override
  Future<Invoice?> getInvoiceById(int id) async {
    return invoices[id];
  }

  @override
  Future<Invoice?> getInvoiceByBookingId(int bookingId) async {
    return null;
  }

  @override
  Future<List<Invoice>> getInvoices(int accountId) async {
    return invoices.values.toList();
  }

  @override
  Future<int> createInvoice(Invoice invoice, int userId) async {
    return 1;
  }

  @override
  Future<void> updateInvoice(Invoice invoice, int userId) async {
    // not used in this test
  }

  @override
  Future<void> addInvoiceLine(InvoiceLine line, int userId) async {
    final invId = line.invoiceId!;
    final inv = invoices[invId];
    if (inv != null) {
      final newLineId = _lineIdCounter++;
      lineToInvoiceMap[newLineId] = invId;
      final addedLine = line.copyWith(id: newLineId);
      final updatedLines = List<InvoiceLine>.from(inv.lines)..add(addedLine);
      invoices[invId] = inv.copyWith(lines: updatedLines);
    }
  }

  @override
  Future<void> removeInvoiceLine(int lineId, int userId) async {
    // not used in this test
  }

  @override
  Future<void> addInvoiceAdjustment(dynamic adjustment, int userId) async {
    // not used in this test
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
  late AddInvoiceLine useCase;

  setUp(() {
    repository = FakeInvoiceRepository();
    auditLogger = FakeAuditLogger();
    useCase = AddInvoiceLine(repository, auditLogger);
  });

  Invoice createDraftInvoice({required int id}) {
    return Invoice(
      id: id,
      uuid: 'invoice-$id',
      bookingId: 10,
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
    final line = InvoiceLine.create(
      invoiceId: null,
      description: 'Room Charge',
      quantity: 1,
      unitPrice: const Money(100),
    );

    expect(
      () => useCase(line, 1),
      throwsA(isA<ValidationFailure>().having((f) => f.code, 'code', 'INVOICE_ID_REQUIRED')),
    );
  });

  test('should throw ValidationFailure if invoice does not exist', () async {
    final line = InvoiceLine.create(
      invoiceId: 99,
      description: 'Room Charge',
      quantity: 1,
      unitPrice: const Money(100),
    );

    expect(
      () => useCase(line, 1),
      throwsA(isA<ValidationFailure>().having((f) => f.code, 'code', 'INVOICE_NOT_FOUND')),
    );
  });

  test('should throw BusinessRuleFailure if invoice is not in Draft status', () async {
    final invoice = createDraftInvoice(id: 1).copyWith(status: InvoiceStatus.issued);
    repository.invoices[1] = invoice;

    final line = InvoiceLine.create(
      invoiceId: 1,
      description: 'Room Charge',
      quantity: 1,
      unitPrice: const Money(100),
    );

    expect(
      () => useCase(line, 1),
      throwsA(isA<BusinessRuleFailure>().having((f) => f.code, 'code', 'INVOICE_NOT_EDITABLE')),
    );
  });

  test('should throw ValidationFailure if quantity is zero or negative', () async {
    final invoice = createDraftInvoice(id: 1);
    repository.invoices[1] = invoice;

    final line = InvoiceLine(
      invoiceId: 1,
      description: 'Room Charge',
      quantity: 0,
      unitPrice: const Money(100),
      lineTotal: const Money(0),
    );

    expect(
      () => useCase(line, 1),
      throwsA(isA<ValidationFailure>().having((f) => f.code, 'code', 'INVALID_QUANTITY')),
    );
  });

  test('should throw ValidationFailure if unit price is negative', () async {
    final invoice = createDraftInvoice(id: 1);
    repository.invoices[1] = invoice;

    final line = InvoiceLine(
      invoiceId: 1,
      description: 'Room Charge',
      quantity: 1,
      unitPrice: const Money(-100),
      lineTotal: const Money(-100),
    );

    expect(
      () => useCase(line, 1),
      throwsA(isA<ValidationFailure>().having((f) => f.code, 'code', 'INVALID_UNIT_PRICE')),
    );
  });

  test('should successfully add line item and log audit event', () async {
    final invoice = createDraftInvoice(id: 1);
    repository.invoices[1] = invoice;

    final line = InvoiceLine.create(
      invoiceId: 1,
      description: 'Deluxe Room Charge',
      quantity: 3,
      unitPrice: const Money(150),
    );

    await useCase(line, 42);

    expect(repository.invoices[1]!.lines.length, 1);
    expect(repository.invoices[1]!.lines.first.description, 'Deluxe Room Charge');
    expect(repository.invoices[1]!.lines.first.lineTotal, const Money(450));
    expect(auditLogger.logCount, 1);
    expect(auditLogger.loggedEvents.first['userId'], 42);
    expect(auditLogger.loggedEvents.first['entityId'], 1);
    expect(auditLogger.loggedEvents.first['action'], 'Add Line');
  });
}
