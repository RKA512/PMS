/// Why the file exists:
/// Implements [InvoicesScreen] - the core presentation layer for Phase 3: Invoice Management.
/// Fully conforms to [Application Flows Flow-12, 13, 14, 14.5], [Financial Rules], and [UX Guidelines].
/// Supports listing, searching, tabs, details, real-time lines/adjustments editing,
/// secure state transition confirmations (Issue, Cancel) and dynamic outstanding calculations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/enums/invoice_status.dart';
import '../../../../core/common/models/money.dart';
import '../../../../core/providers/session_providers.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_adjustment.dart';
import '../../domain/entities/invoice_line.dart';
import '../providers/invoice_providers.dart';
import '../widgets/invoice_form_dialog.dart';
import '../widgets/invoice_details_dialog.dart';
import '../widgets/invoice_status_badge.dart';
import '../widgets/invoice_list_table.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {

  @override
  Widget build(BuildContext context) {
    final activeAccount = ref.watch(activeAccountIdProvider);
    final authenticatedUserId = ref.watch(authenticatedUserIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Warning notice banner if session/account infrastructure is missing or offline
          if (activeAccount == null || authenticatedUserId == null)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBEB),
                border: Border(bottom: BorderSide(color: Color(0xFFFDE68A), width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: const Text(
                      'تنبيه: سياق المستخدم الموثق أو الحساب النشط غير متوفر حالياً لتفعيل الميزات السحابية.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w500,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // Page Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إدارة الفواتير والذمم المالية',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'أصدر فواتير الغرف، راقب الفروقات والدفوعات، وتحكم بالقيود المانعة لإجراء تعديلات للفواتير المجمدة.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _openCreateInvoiceDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إنشاء فاتورة جديدة (Draft)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: InvoiceListTable(
                onViewDetails: (invoice) => _openInvoiceDetailsDialog(context, invoice),
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
    );
  }

  // --- CREATE INVOICE DIALOG ---
  void _openCreateInvoiceDialog(BuildContext context) async {
    final activeAccount = ref.read(activeAccountIdProvider);
    final authenticatedUserId = ref.read(authenticatedUserIdProvider);
    if (activeAccount == null || authenticatedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ: سياق المستخدم الموثق أو الحساب غير متوفر.')),
      );
      return;
    }

    // Fetch bookings that do NOT have any invoice yet via Clean Architecture
    final getUninvoiced = ref.read(getUninvoicedBookingsUseCaseProvider);
    final List<Map<String, dynamic>> bookingMaps = await getUninvoiced();

    if (bookingMaps.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تعذر إنشاء فاتورة جديدة', textDirection: TextDirection.rtl),
            content: const Text(
              'جميع الحجوزات المسجلة حالياً لديها فواتير مسبقة.\nيرجى تسجيل حجز جديد أولاً لتتمكن من توليد فاتورة له.',
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return CreateInvoiceDialogContent(
          bookingMaps: bookingMaps,
          onSave: (int bookingId, List<InvoiceLine> lines, List<InvoiceAdjustment> adjustments) async {
            // Generate professional serial invoice_number
            final now = DateTime.now();
            final numSuffix = now.millisecondsSinceEpoch.toString().substring(7);
            final invoiceNumber = 'INV-${now.year}-$numSuffix';

            final newInvoice = Invoice(
              uuid: '',
              bookingId: bookingId,
              invoiceNumber: invoiceNumber,
              totalAmount: const Money(0), // computed and frozen on issued
              status: InvoiceStatus.draft,
              createdAt: now,
              updatedAt: now,
              lines: lines,
              adjustments: adjustments,
            );

            try {
              final useCase = ref.read(createInvoiceUseCaseProvider);
              await useCase(newInvoice, authenticatedUserId);
              
              // Refresh state
              ref.read(invoicesListProvider.notifier).fetchInvoices(activeAccount);
              
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم إنشاء مسودة الفاتورة $invoiceNumber بنجاح!')),
                );
              }
            } catch (e) {
              if (ctx.mounted) {
                showDialog(
                  context: ctx,
                  builder: (errCtx) => AlertDialog(
                    title: const Text('فشل الحفظ', textDirection: TextDirection.rtl),
                    content: Text(e.toString(), textDirection: TextDirection.rtl),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(errCtx), child: const Text('حسناً')),
                    ],
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  // --- INVOICE DETAILS & EDITING VIEW DIALOG ---
  void _openInvoiceDetailsDialog(BuildContext context, Invoice initialInvoice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return InvoiceDetailsDialogContent(
          invoiceId: initialInvoice.id!,
          onUpdate: () {
            final activeAccount = ref.read(activeAccountIdProvider);
            if (activeAccount != null) {
              ref.read(invoicesListProvider.notifier).fetchInvoices(activeAccount);
              // Force invalidation of balance cache
              ref.invalidate(invoiceOutstandingBalanceProvider(initialInvoice.id!));
            }
          },
        );
      },
    );
  }
} const SizedBox(width: 8),
                      ],

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        child: const Text('رجوع'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailMetricCell(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(InvoiceStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case InvoiceStatus.draft:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        break;
      case InvoiceStatus.issued:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        break;
      case InvoiceStatus.partiallyPaid:
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFD97706);
        break;
      case InvoiceStatus.paid:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        break;
      case InvoiceStatus.cancelled:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
