/// Why the file exists:
/// Multi-item invoice composition dialog, responsible for building a draft invoice.
/// Delegates financial calculations to the [Invoice] Domain Entity to avoid presentation logic leak.
library;

import 'package:flutter/material.dart';
import '../../../../core/common/enums/invoice_status.dart';
import '../../../../core/common/models/money.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_adjustment.dart';
import '../../domain/entities/invoice_line.dart';

class CreateInvoiceDialogContent extends StatefulWidget {
  final List<Map<String, dynamic>> bookingMaps;
  final Function(int bookingId, List<InvoiceLine> lines, List<InvoiceAdjustment> adjustments) onSave;

  const CreateInvoiceDialogContent({
    Key? key,
    required this.bookingMaps,
    required this.onSave,
  }) : super(key: key);

  @override
  State<CreateInvoiceDialogContent> createState() => _CreateInvoiceDialogContentState();
}

class _CreateInvoiceDialogContentState extends State<CreateInvoiceDialogContent> {
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

  /// Draft Invoice representation to leverage Domain Entity for calculations
  Invoice get _draftInvoice {
    return Invoice(
      uuid: '',
      bookingId: _selectedBookingId ?? 0,
      invoiceNumber: '',
      totalAmount: const Money(0),
      status: InvoiceStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lines: _lines,
      adjustments: _adjustments,
    );
  }

  Money _calculateSubtotal() => _draftInvoice.subtotal;
  Money _calculateAdjustments() => _draftInvoice.totalAdjustments;
  Money _calculateTotal() => _draftInvoice.calculatedTotal;

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
