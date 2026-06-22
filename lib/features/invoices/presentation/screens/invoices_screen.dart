/// Why the file exists:
/// Implements [InvoicesScreen] - the core presentation layer for Phase 3: Invoice Management.
/// Fully conforms to [Application Flows Flow-12, 13, 14, 14.5], [Financial Rules], and [UX Guidelines].
/// Supports listing, searching, tabs, details, real-time lines/adjustments editing,
/// secure state transition confirmations (Issue, Cancel) and dynamic outstanding calculations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/common/enums/invoice_status.dart';
import '../../../../core/common/models/money.dart';
import '../../../../core/providers/session_providers.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_adjustment.dart';
import '../../domain/entities/invoice_line.dart';
import '../providers/invoice_providers.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  String _selectedStatusFilter = 'all'; // status name or 'all'
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesListProvider);
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

            // Searching & Filter Tabs Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(invoiceSearchQueryProvider.notifier).state = val;
                      },
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        hintText: 'البحث برقم الفاتورة أو رمز الحالة...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Filter Tabs
            _buildStatusTabs(),

            const SizedBox(height: 20),

            // Main Listing Table Panel
            Expanded(
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: invoicesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'خطأ أثناء جلب الفواتير: $e',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (invoices) {
                    // Apply visual tabs filter locally
                    final filtered = invoices.where((inv) {
                      if (_selectedStatusFilter == 'all') return true;
                      return inv.status.name.toLowerCase() == _selectedStatusFilter.toLowerCase();
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد فواتير مطابقة لخيارات الفرز الحالية.',
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Table Headers
                        Container(
                          color: const Color(0xFFF8FAFC),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(
                            children: const [
                              Expanded(flex: 2, child: Text('رقم الفاتورة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                              Expanded(flex: 2, child: Text('حساب الحجز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                              Expanded(flex: 2, child: Text('المجموع الإجمالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                              Expanded(flex: 2, child: Text('الرصيد المستحق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                              Expanded(flex: 2, child: Text('حالة الفاتورة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                              Expanded(flex: 2, child: Text('تاريخ الإنشاء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                              SizedBox(width: 100, child: Text('خيارات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)), textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),

                        // Table Items Rows
                        Expanded(
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (context, idx) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (context, idx) {
                              final invoice = filtered[idx];
                              return _buildInvoiceRow(context, invoice);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
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

  Widget _buildStatusTabs() {
    final Map<String, String> states = {
      'all': 'الكل (All)',
      'draft': 'مسودة (Draft)',
      'issued': 'صادرة (Issued)',
      'partiallyPaid': 'مدفوعة جزئياً',
      'paid': 'مدفوعة (Paid)',
      'cancelled': 'ملغاة (Cancelled)',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: states.entries.map((entry) {
          final isSelected = _selectedStatusFilter == entry.key;
          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedStatusFilter = entry.key;
                  });
                }
              },
              selectedColor: const Color(0xFF0F172A),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[200]!),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInvoiceRow(BuildContext context, Invoice invoice) {
    // Dynamic Outstanding balance calculation
    final balanceAsync = ref.watch(invoiceOutstandingBalanceProvider(invoice.id!));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Invoice Number
          Expanded(
            flex: 2,
            child: Text(
              invoice.invoiceNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
          
          // Booking link
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 6),
                Text('حجز #${invoice.bookingId}', style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
              ],
            ),
          ),

          // Total amount (Draft is dynamically computed, Issued/etc is from DB)
          Expanded(
            flex: 2,
            child: Text(
              invoice.status == InvoiceStatus.draft 
                  ? invoice.calculatedTotal.format('') 
                  : invoice.totalAmount.format(''),
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ),

          // Dynamic Outstanding Balance
          Expanded(
            flex: 2,
            child: balanceAsync.when(
              loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, s) => const Text('خطأ', style: TextStyle(color: Colors.red, fontSize: 12)),
              data: (bal) {
                final isZero = bal == 0.0;
                return Text(
                  isZero ? 'لا يوجد قيود' : '${bal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isZero ? Colors.green[600] : const Color(0xFFEF4444),
                  ),
                );
              },
            ),
          ),

          // Status Badge
          Expanded(
            flex: 2,
            child: _buildStatusBadge(invoice.status),
          ),

          // Date Created
          Expanded(
            flex: 2,
            child: Text(
              intl.DateFormat('yyyy/MM/dd HH:mm').format(invoice.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),

          // Action dropdown / buttons
          SizedBox(
            width: 100,
            child: Center(
              child: TextButton(
                onPressed: () => _openInvoiceDetailsDialog(context, invoice),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6), padding: EdgeInsets.zero),
                child: const Text('عرض وتعديل'),
              ),
            ),
          ),
        ],
      ),
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

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status.displayName,
          style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
        ),
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
        return _CreateInvoiceDialogContent(
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
        return _InvoiceDetailsDialogContent(
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
}

// --- Create Invoice Form Sub-widget logic ---
class _CreateInvoiceDialogContent extends StatefulWidget {
  final List<Map<String, dynamic>> bookingMaps;
  final Function(int bookingId, List<InvoiceLine> lines, List<InvoiceAdjustment> adjustments) onSave;

  const _CreateInvoiceDialogContent({
    Key? key,
    required this.bookingMaps,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_CreateInvoiceDialogContent> createState() => _CreateInvoiceDialogContentState();
}

class _CreateInvoiceDialogContentState extends State<_CreateInvoiceDialogContent> {
  int? _selectedBookingId;
  final List<InvoiceLine> _lines = [];
  final List<InvoiceAdjustment> _adjustments = [];

  // Line form fields controllers
  final _lineDescController = TextEditingController();
  final _lineQtyController = TextEditingController(text: '1');
  final _linePriceController = TextEditingController(text: '100.0');

  // Adjustment form controllers
  final _adjDescController = TextEditingController();
  final _adjAmountController = TextEditingController(text: '10.0');
  InvoiceAdjustmentType _selectedAdjType = InvoiceAdjustmentType.discount;

  @override
  void initState() {
    super.initState();
    if (widget.bookingMaps.isNotEmpty) {
      _selectedBookingId = widget.bookingMaps.first['id'] as int;
    }
  }

  @override
  void dispose() {
    _lineDescController.dispose();
    _lineQtyController.dispose();
    _linePriceController.dispose();
    _adjDescController.dispose();
    _adjAmountController.dispose();
    super.dispose();
  }

  Money _calculateSubtotal() {
    int sum = 0;
    for (final l in _lines) {
      sum += l.lineTotal.minorUnits;
    }
    return Money(sum);
  }

  Money _calculateAdjustments() {
    int sum = 0;
    for (final a in _adjustments) {
      if (a.adjustmentType == InvoiceAdjustmentType.discount) {
        sum -= a.amount.minorUnits.abs();
      } else {
        sum += a.amount.minorUnits;
      }
    }
    return Money(sum);
  }

  Money _calculateTotal() {
    final s = _calculateSubtotal();
    final a = _calculateAdjustments();
    final total = s.minorUnits + a.minorUnits;
    return Money(total < 0 ? 0 : total);
  }

  void _addLine() {
    final desc = _lineDescController.text.trim();
    if (desc.isEmpty) return;
    final qty = int.tryParse(_lineQtyController.text) ?? 1;
    final price = double.tryParse(_linePriceController.text) ?? 0.0;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكمية يجب أن تكون أكبر من الصفر')),
      );
      return;
    }

    setState(() {
      _lines.add(InvoiceLine.create(
        description: desc,
        quantity: qty,
        unitPrice: Money.fromDouble(price),
      ));
      _lineDescController.clear();
      _lineQtyController.text = '1';
      _linePriceController.text = '100.0';
    });
  }

  void _addAdjustment() {
    final reason = _adjDescController.text.trim();
    if (reason.isEmpty) return;
    final amt = double.tryParse(_adjAmountController.text) ?? 0.0;

    if (amt == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قيمة التعديل لا يمكن أن تساوي الصفر')),
      );
      return;
    }

    setState(() {
      _adjustments.add(InvoiceAdjustment(
        adjustmentType: _selectedAdjType,
        amount: Money.fromDouble(amt),
        reason: reason,
        createdAt: DateTime.now(),
      ));
      _adjDescController.clear();
      _adjAmountController.text = '10.0';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(28.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Semantics(
                header: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'إنشاء مسودة فاتورة مالية',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                        onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Booking Picker
              Row(
                children: [
                  const Text('الحجز المستهدف: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedBookingId,
                          isExpanded: true,
                          items: widget.bookingMaps.map((b) {
                            return DropdownMenuItem<int>(
                              value: b['id'] as int,
                              child: Text('حجز رقم ${b['booking_number']} - النزيل: ${b['guest_name']}'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedBookingId = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section: Invoice Lines
              const Text('1. بنود الرسوم والمبيعات:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              const SizedBox(height: 8),
              
              // Lines Input Row
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: _lineDescController,
                      decoration: const InputDecoration(hintText: 'وصف البند الفندقي المعين', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _lineQtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'الكمية', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _linePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'سعر الوحدة', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addLine,
                    icon: const Icon(Icons.add_circle, color: Colors.green, size: 36),
                  )
                ],
              ),
              const SizedBox(height: 12),

              // Lines List
              if (_lines.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.yellow.withValues(alpha: 0.1),
                  child: const Text('⚠️ لم يتم إضافة أي خط مالي للفاتورة بعد. البند المالي الواحد على الأقل إلزامي.', style: TextStyle(fontSize: 12, color: Colors.amber)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _lines.length,
                  itemBuilder: (context, index) {
                    final line = _lines[index];
                    return Card(
                      child: ListTile(
                        title: Text(line.description),
                        subtitle: Text('الكمية: ${line.quantity} × بسعر ${line.unitPrice}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(line.lineTotal.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              onPressed: () => setState(() => _lines.removeAt(index)),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Section: Invoice Adjustments
              const Text('2. التعديلات والخصومات المالية المسموحة:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent)),
              const SizedBox(height: 8),

              // Adjustments Input Row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _adjDescController,
                      decoration: const InputDecoration(hintText: 'سبب إجراء التعديل', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<InvoiceAdjustmentType>(
                          value: _selectedAdjType,
                          items: InvoiceAdjustmentType.values.map((type) {
                            return DropdownMenuItem<InvoiceAdjustmentType>(
                              value: type,
                              child: Text(type.displayName, style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedAdjType = val ?? InvoiceAdjustmentType.discount;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _adjAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'القيمة', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addAdjustment,
                    icon: const Icon(Icons.add_circle, color: Colors.orange, size: 36),
                  )
                ],
              ),
              const SizedBox(height: 12),

              // Adjustments List
              if (_adjustments.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _adjustments.length,
                  itemBuilder: (context, index) {
                    final adj = _adjustments[index];
                    return Card(
                      color: Colors.orange.withValues(alpha: 0.05),
                      child: ListTile(
                        title: Text(adj.reason),
                        subtitle: Text(adj.adjustmentType.displayName),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              adj.adjustmentType == InvoiceAdjustmentType.discount 
                                  ? '-${adj.amount}' 
                                  : '+${adj.amount}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _adjustments.removeAt(index)),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const Divider(height: 40),

              // Realtime Totaling Displays
              _buildMetricLine('مجموع البنود الأصلي (Subtotal):', _calculateSubtotal().toString()),
              _buildMetricLine('مجموع التعديلات (Adjustments):', _calculateAdjustments().toString()),
              _buildMetricLine('المجموع النهائي المستحق (Calculated Est Total):', _calculateTotal().toString(), isTotal: true),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _lines.isEmpty || _selectedBookingId == null
                    ? null
                    : () => widget.onSave(_selectedBookingId!, _lines, _adjustments),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('حفظ مسودة الفاتورة (Save as Draft)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricLine(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 15 : 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isTotal ? 16 : 14, color: isTotal ? Colors.blue[800] : Colors.black)),
        ],
      ),
    );
  }
}

// --- Invoice Details Dialog Sub-widget logic ---
class _InvoiceDetailsDialogContent extends ConsumerStatefulWidget {
  final int invoiceId;
  final VoidCallback onUpdate;

  const _InvoiceDetailsDialogContent({
    Key? key,
    required this.invoiceId,
    required this.onUpdate,
  }) : super(key: key);

  @override
  ConsumerState<_InvoiceDetailsDialogContent> createState() => _InvoiceDetailsDialogContentState();
}

class _InvoiceDetailsDialogContentState extends ConsumerState<_InvoiceDetailsDialogContent> {
  // Direct inputs inside Details Dialog if the Invoice is Draft to facilitate modifications
  final _lineDescController = TextEditingController();
  final _lineQtyController = TextEditingController(text: '1');
  final _linePriceController = TextEditingController(text: '100.0');

  final _adjDescController = TextEditingController();
  final _adjAmountController = TextEditingController(text: '10.0');
  InvoiceAdjustmentType _selectedAdjType = InvoiceAdjustmentType.discount;

  bool _isSaving = false;

  @override
  void dispose() {
    _lineDescController.dispose();
    _lineQtyController.dispose();
    _linePriceController.dispose();
    _adjDescController.dispose();
    _adjAmountController.dispose();
    super.dispose();
  }

  Future<Invoice?> _fetchInvoice() async {
    final repo = ref.read(invoiceRepositoryProvider);
    return await repo.getInvoiceById(widget.invoiceId);
  }

  void _modifyLinesAndAdjustments(Invoice current, List<InvoiceLine> newLines, List<InvoiceAdjustment> newAdjs) async {
    final authenticatedUserId = ref.read(authenticatedUserIdProvider);
    if (authenticatedUserId == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('خطأ في الصلاحيات'),
          content: const Text('تعذر العثور على معرّف مستخدم جاري صالح لتسجيل التعديل.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً')),
          ],
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = current.copyWith(
        lines: newLines,
        adjustments: newAdjs,
        updatedAt: DateTime.now(),
      );
      final updateUseCase = ref.read(updateInvoiceUseCaseProvider);
      await updateUseCase(updated, authenticatedUserId);
      widget.onUpdate();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الفاتورة والتوطين بنجاح!')));
    } catch (e) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('فشل الحفظ والتجميد'),
          content: Text(e.toString()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً')),
          ],
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _issueInvoiceFlow(Invoice invoice) async {
    final authenticatedUserId = ref.read(authenticatedUserIdProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إصدار الفاتورة المعتمدة (Freeze Total)', textDirection: TextDirection.rtl),
        content: Text(
          'تنبيه محاسبي مهم:\nعند إصدار الفاتورة، سيتم تجميد المجموع المالي النهائي عند (${invoice.calculatedTotal.toString()}) ولن تتمكن من إضافة أي خطوط أو تعديلات مباشرة عليها لاحقاً.\nهل أنت متأكد من المتابعة والإصدار؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            child: const Text('تأكيد وإصدار'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (authenticatedUserId == null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('خطأ في الصلاحيات'),
            content: const Text('تعذر العثور على معرّف مستخدم جاري صالح لتسجيل إصدار الفاتورة.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً')),
            ],
          ),
        );
        return;
      }

      setState(() => _isSaving = true);
      try {
        final issueUseCase = ref.read(issueInvoiceUseCaseProvider);
        await issueUseCase(invoice.id!, authenticatedUserId);
        widget.onUpdate();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إصدار الفاتورة بنجاح وتجميد المبالغ ماليّاً!')));
      } catch (e) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تعذر الإصدار'),
            content: Text(e.toString()),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع'))],
          ),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  void _cancelInvoiceFlow(Invoice invoice) async {
    final authenticatedUserId = ref.read(authenticatedUserIdProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الفاتورة بالكامل (Cancellation)', textDirection: TextDirection.rtl),
        content: const Text(
          'هل أنت متأكد من إلغاء الفاتورة؟\nهذا الإجراء لا يمكن التراجع عنه وسيعتبر الفاتورة ملغاة محاسبياً.',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('إلغاء الفاتورة الآن'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (authenticatedUserId == null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('خطأ في الصلاحيات'),
            content: const Text('تعذر العثور على معرّف مستخدم جاري صالح لتسجيل إلغاء الفاتورة.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً')),
            ],
          ),
        );
        return;
      }

      setState(() => _isSaving = true);
      try {
        final cancelUseCase = ref.read(cancelInvoiceUseCaseProvider);
        await cancelUseCase(invoice.id!, authenticatedUserId);
        widget.onUpdate();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الفاتورة بنجاح!')));
      } catch (e) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تعذر الإلغاء'),
            content: Text(e.toString()),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً'))],
          ),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final outstandingAsync = ref.watch(invoiceOutstandingBalanceProvider(widget.invoiceId));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: FutureBuilder<Invoice?>(
        future: _fetchInvoice(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isSaving) {
            return const SizedBox(
              width: 700,
              height: 400,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final invoice = snapshot.data;
          if (invoice == null) {
            return SizedBox(
              width: 500,
              height: 200,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('خطأ مالي: تعذر العثور على الفاتورة المعينة أو تم حذفها.'),
                    const Spacer(),
                    ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))
                  ],
                ),
              ),
            );
          }

          final isDraft = invoice.status == InvoiceStatus.draft;

          return Container(
            width: 850,
            padding: const EdgeInsets.all(28.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Invoice details Top Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تفاصيل الفاتورة: ${invoice.invoiceNumber}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'مرتبطة بالحجز رقم #${invoice.bookingId}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildStatusBadge(invoice.status),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Outstanding calculations header banner
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: const Color(0xFFF8FAFC),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[200]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildDetailMetricCell(
                                  'المجموع الإجمالي للفاتورة',
                                  isDraft ? invoice.calculatedTotal.format('') : invoice.totalAmount.format(''),
                                  Colors.blue[900]!,
                                ),
                                _buildDetailMetricCell(
                                  'الرصيد المستقيل الصافي',
                                  outstandingAsync.when(
                                    loading: () => '...',
                                    error: (e, s) => 'خطأ',
                                    data: (bal) => Money.fromDouble(bal).format(''),
                                  ),
                                  Colors.red[800]!,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section: Invoice Lines
                  Text(
                    isDraft ? '1. بنود الرسوم والمبيعات (قابل للتعديل):' : '1. بنود الرسوم (مجمدة للتدقيق):',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),

                  // Add line form if Draft
                  if (isDraft) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: _lineDescController,
                            decoration: const InputDecoration(hintText: 'وصف البند', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _lineQtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'الكمية', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _linePriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'سعر الوحدة', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            final desc = _lineDescController.text.trim();
                            if (desc.isEmpty) return;
                            final qty = int.tryParse(_lineQtyController.text) ?? 1;
                            final price = double.tryParse(_linePriceController.text) ?? 0.0;
                            if (qty <= 0) return;

                            final newLine = InvoiceLine.create(
                              description: desc,
                              quantity: qty,
                              unitPrice: Money.fromDouble(price),
                              invoiceId: invoice.id,
                            );

                            final updatedLines = List<InvoiceLine>.from(invoice.lines)..add(newLine);
                            _modifyLinesAndAdjustments(invoice, updatedLines, invoice.adjustments);
                          },
                          icon: const Icon(Icons.add_circle, color: Colors.green, size: 36),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Render list of lines
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invoice.lines.length,
                    itemBuilder: (context, idx) {
                      final line = invoice.lines[idx];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[100]!),
                        ),
                        child: ListTile(
                          title: Text(line.description),
                          subtitle: Text('الكمية: ${line.quantity} × بسعر ${line.unitPrice}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(line.lineTotal.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (isDraft)
                                IconButton(
                                  onPressed: () {
                                    // Make sure we keep at least one line (or we let validation use-case fail cleanly, but let's check here)
                                    if (invoice.lines.length <= 1) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('⚠️ يجب إبقاء بند مالي واحد على الأقل للفاتورة.')),
                                      );
                                      return;
                                    }
                                    final updatedLines = List<InvoiceLine>.from(invoice.lines)..removeAt(idx);
                                    _modifyLinesAndAdjustments(invoice, updatedLines, invoice.adjustments);
                                  },
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Section: Adjustments
                  Text(
                    isDraft ? '2. التعديلات والخصومات المالية المشموحة (قابل للتعديل):' : '2. التعديلات المالية (مجمدة للتدقيق):',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),

                  // Add adjustment form if Draft
                  if (isDraft) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _adjDescController,
                            decoration: const InputDecoration(hintText: 'سبب إجراء التعديل', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<InvoiceAdjustmentType>(
                                value: _selectedAdjType,
                                items: InvoiceAdjustmentType.values.map((type) {
                                  return DropdownMenuItem<InvoiceAdjustmentType>(
                                    value: type,
                                    child: Text(type.displayName, style: const TextStyle(fontSize: 12)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedAdjType = val ?? InvoiceAdjustmentType.discount;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _adjAmountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'القيمة', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            final reason = _adjDescController.text.trim();
                            if (reason.isEmpty) return;
                            final amt = double.tryParse(_adjAmountController.text) ?? 0.0;
                            if (amt <= 0.0) return;

                            final newAdj = InvoiceAdjustment(
                              adjustmentType: _selectedAdjType,
                              amount: Money.fromDouble(amt),
                              reason: reason,
                              createdAt: DateTime.now(),
                              invoiceId: invoice.id,
                            );

                            final updatedAdjs = List<InvoiceAdjustment>.from(invoice.adjustments)..add(newAdj);
                            _modifyLinesAndAdjustments(invoice, invoice.lines, updatedAdjs);
                          },
                          icon: const Icon(Icons.add_circle, color: Colors.orange, size: 36),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Adjustments List
                  if (invoice.adjustments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('لا توجد تعديلات مالية حالية على هذه الفاتورة.', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: invoice.adjustments.length,
                      itemBuilder: (context, idx) {
                        final adj = invoice.adjustments[idx];
                        return Card(
                          color: Colors.orange.withValues(alpha: 0.02),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.orange.withValues(alpha: 0.1)),
                          ),
                          child: ListTile(
                            title: Text(adj.reason),
                            subtitle: Text('النوع: ${adj.adjustmentType.displayName}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  adj.adjustmentType == InvoiceAdjustmentType.discount 
                                      ? '-${adj.amount}' 
                                      : '+${adj.amount}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                ),
                                if (isDraft)
                                  IconButton(
                                    onPressed: () {
                                      final updatedAdjs = List<InvoiceAdjustment>.from(invoice.adjustments)..removeAt(idx);
                                      _modifyLinesAndAdjustments(invoice, invoice.lines, updatedAdjs);
                                    },
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const Divider(height: 48),

                  // Standard static information banner
                  Table(
                    children: [
                      TableRow(children: [
                        const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('تاريخ الإصدار الأكاديمي/الفعلي:')),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            invoice.issuedAt != null 
                                ? intl.DateFormat('yyyy/MM/dd HH:mm').format(invoice.issuedAt!) 
                                : 'مسودة لم تصدر بعد',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]),
                      TableRow(children: [
                        const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('تاريخ الإنشاء الأولي:')),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(intl.DateFormat('yyyy/MM/dd HH:mm').format(invoice.createdAt), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Bottom Option Controls based on invoice.status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Direct Draft Controls
                      if (isDraft) ...[
                        ElevatedButton.icon(
                          onPressed: () => _issueInvoiceFlow(invoice),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('إصدار وتجميد الفاتورة (Issue)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Cancel Option (for Draft/Issued/PartiallyPaid, but NOT Paid or already Cancelled)
                      if (invoice.status != InvoiceStatus.paid && invoice.status != InvoiceStatus.cancelled) ...[
                        ElevatedButton.icon(
                          onPressed: () => _cancelInvoiceFlow(invoice),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('إلغاء الفاتورة (Cancel)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
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
