import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_system/core/common/enums/invoice_status.dart';
import 'package:property_management_system/core/common/models/money.dart';
import 'package:property_management_system/core/errors/failure.dart';
import 'package:property_management_system/core/contracts/audit_logger.dart';
import 'package:property_management_system/features/invoices/domain/entities/invoice.dart';
import 'package:property_management_system/features/invoices/domain/entities/invoice_line.dart';
import 'package:property_management_system/features/invoices/domain/entities/invoice_adjustment.dart';
import 'package:property_management_system/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:property_management_system/features/invoices/domain/usecases/issue_invoice.dart';

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
    // not used
  }

  @override
  Future<void> addInvoiceAdjustment(dynamic adjustment, int userId) async {
    // not used
  }

  @override
  Future<void> issueInvoice(int invoiceId, Money frozenTotal, int userId) async {
    final inv = invoices[invoiceId];
    if (inv != null) {
      invoices[invoiceId] = inv.copyWith(
        status: InvoiceStatus.issued,
        totalAmount: frozenTotal,
        issuedAt: DateTime.now(),
      );
    }
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
  late IssueInvoice useCase;

  setUp(() {
    repository = FakeInvoiceRepository();
    auditLogger = FakeAuditLogger();
    useCase = IssueInvoice(repository, auditLogger);
  });

  Invoice createDraftInvoice({required int id, List<InvoiceLine> lines = const [], List<InvoiceAdjustment> adjustments = const []}) {
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
      adjustments: adjustments,
    );
  }

  test('should throw ValidationFailure if invoice does not exist', () async {
    expect(
      () => useCase(99, 1),
      throwsA(isA<ValidationFailure>().having((f) => f.code, 'code', 'INVOICE_NOT_FOUND')),
    );
  });

  test('should throw BusinessRuleFailure if invoice is not in Draft state', () async {
    final invoice = createDraftInvoice(id: 1).copyWith(status: InvoiceStatus.issued);
    repository.invoices[1] = invoice;

    expect(
      () => useCase(1, 1),
      throwsA(isA<BusinessRuleFailure>().having((f) => f.code, 'code', 'INVOICE_NOT_DRAFT')),
    );
  });

  test('should throw BusinessRuleFailure if invoice has no lines', () async {
    final invoice = createDraftInvoice(id: 1, lines: const []);
    repository.invoices[1] = invoice;

    expect(
      () => useCase(1, 1),
      throwsA(isA<BusinessRuleFailure>().having((f) => f.code, 'code', 'EMPTY_INVOICE')),
    );
  });

  test('should successfully issue invoice, freezing calculated total and logging audit event', () async {
    final lines = [
      InvoiceLine.create(description: 'Room Charge', quantity: 2, unitPrice: const Money(150)), // subtotal = 300
    ];
    final adjustments = [
      InvoiceAdjustment(
        adjustmentType: InvoiceAdjustmentType.discount,
        amount: const Money(50), // subtotal - 50 = 250
        reason: 'Promo Discount',
        createdAt: DateTime.now(),
      ),
    ];
    final invoice = createDraftInvoice(id: 1, lines: lines, adjustments: adjustments);
    repository.invoices[1] = invoice;

    await useCase(1, 42);

    expect(repository.invoices[1]!.status, InvoiceStatus.issued);
    expect(repository.invoices[1]!.totalAmount, const Money(250));
    expect(auditLogger.logCount, 1);
    expect(auditLogger.loggedEvents.first['userId'], 42);
    expect(auditLogger.loggedEvents.first['entityId'], 1);
    expect(auditLogger.loggedEvents.first['action'], 'Issue Invoice');
  });
}
