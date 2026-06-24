/// Why the file exists:
/// Detailed view dialog for a specific invoice, including live line adjustments, state actions (issue/cancel),
/// and dynamic balance calculation. Conforms fully to Clean Architecture.
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
import 'invoice_status_badge.dart';

class InvoiceDetailsDialogContent extends ConsumerStatefulWidget {
  final int invoiceId;
  final VoidCallback onUpdate;

  const InvoiceDetailsDialogContent({
    Key? key,
    required this.invoiceId,
    required this.onUpdate,
  }) : super(key: key);

  @override
  ConsumerState<InvoiceDetailsDialogContent> createState() => _InvoiceDetailsDialogContentState();
}

class _InvoiceDetailsDialogContentState extends ConsumerState<InvoiceDetailsDialogContent> {
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
    // 💡 Architecture correction: Use Use Case Provider instead of direct Repository read
    final getInvoiceByIdUseCase = ref.read(getInvoiceByIdUseCaseProvider);
    return await getInvoiceByIdUseCase(widget.invoiceId);
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
                          InvoiceStatusBadge(status: invoice.status),
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
                                    data: (bal) => bal.format(''),
                                    error: (e, s) => 'خطأ',
                                    loading: () => '...',
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
}
