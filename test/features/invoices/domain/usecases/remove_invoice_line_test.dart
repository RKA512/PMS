import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_system/core/common/enums/invoice_status.dart';
import 'package:property_management_system/core/common/models/money.dart';
import 'package:property_management_system/core/errors/failure.dart';
import 'package:property_management_system/core/contracts/audit_logger.dart';
import 'package:property_management_system/features/invoices/domain/entities/invoice.dart';
import 'package:property_management_system/features/invoices/domain/entities/invoice_line.dart';
import 'package:property_management_system/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:property_management_system/features/invoices/domain/usecases/remove_invoice_line.dart';

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
    // not used
  }

  @override
  Future<void> addInvoiceLine(dynamic line, int userId) async {
    // not used
  }

  @override
  Future<void> removeInvoiceLine(int lineId, int userId) async {
    final invId = lineToInvoiceMap[lineId];
    if (invId != null) {
      final inv = invoices[invId];
      if (inv != null) {
        final updatedLines = inv.lines.where((l) => l.id != lineId).toList();
        invoices[invId] = inv.copyWith(lines: updatedLines);
        lineToInvoiceMap.remove(lineId);
      }
    }
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
  late RemoveInvoiceLine useCase;

  setUp(() {
    repository = FakeInvoiceRepository();
    auditLogger = FakeAuditLogger();
    useCase = RemoveInvoiceLine(repository, auditLogger);
  });

  Invoice createDraftInvoice({required int id, List<InvoiceLine> lines = const []}) {
    return Invoice(
      id: id,
      uuid: 'invoice-$id',
      bookingId: 10,
      invoiceNumber: 'INV-$id',
      totalAmount: const Money(0),
      status: InvoiceStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lines: lines,
      adjustments: const [],
    );
  }

  test('should throw ValidationFailure if line does not exist in the system', () async {
    expect(
      () => useCase(99, 1),
      throwsA(isA<ValidationFailure>().having((f) => f.code, 'code', 'LINE_NOT_FOUND')),
    );
  });

  test('should throw BusinessRuleFailure if invoice status is not Draft', () async {
    const line = InvoiceLine(
      id: 5,
      invoiceId: 1,
      description: 'Tax Charge',
      quantity: 1,
      unitPrice: Money(10),
      lineTotal: Money(10),
    );
    final invoice = createDraftInvoice(id: 1, lines: [line]).copyWith(status: InvoiceStatus.issued);
    repository.invoices[1] = invoice;
    repository.lineToInvoiceMap[5] = 1;

    expect(
      () => useCase(5, 1),
      throwsA(isA<BusinessRuleFailure>().having((f) => f.code, 'code', 'INVOICE_NOT_EDITABLE')),
    );
  });

  test('should successfully remove line and log audit event', () async {
    const line = InvoiceLine(
      id: 5,
      invoiceId: 1,
      description: 'Breakfast Charge',
      quantity: 1,
      unitPrice: Money(15),
      lineTotal: Money(15),
    );
    final invoice = createDraftInvoice(id: 1, lines: [line]);
    repository.invoices[1] = invoice;
    repository.lineToInvoiceMap[5] = 1;

    await useCase(5, 42);

    expect(repository.invoices[1]!.lines, isEmpty);
    expect(auditLogger.logCount, 1);
    expect(auditLogger.loggedEvents.first['userId'], 42);
    expect(auditLogger.loggedEvents.first['entityId'], 1);
    expect(auditLogger.loggedEvents.first['action'], 'Remove Line');
  });
}
