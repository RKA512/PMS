import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/common/enums/invoice_status.dart';
import '../../domain/entities/invoice.dart';
import '../providers/invoice_providers.dart';
import 'invoice_status_badge.dart';

/// Why this file exists:
/// Fulfills requirement #3 (Reduce Responsibility of InvoicesScreen) by extracting the
/// invoice listing table, search textfield panel, status filters, and row renders into a separate widget.
/// Implements [Application Flows Flow-12] and strictly separates presentation views from orchestrators.
class InvoiceListTable extends ConsumerStatefulWidget {
  final Function(Invoice invoice) onViewDetails;

  const InvoiceListTable({
    Key? key,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  ConsumerState<InvoiceListTable> createState() => _InvoiceListTableState();
}

class _InvoiceListTableState extends ConsumerState<InvoiceListTable> {
  String _selectedStatusFilter = 'all';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Input Panel
        Container(
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
        const SizedBox(height: 16),

        // Filter tabs
        _buildStatusTabs(),

        const SizedBox(height: 20),

        // Table Panel
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
                // Apply status filter locally if any
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

                    // Items
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
                final isZero = bal.minorUnits == 0;
                return Text(
                  isZero ? 'لا يوجد قيود' : bal.format(''),
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
            child: InvoiceStatusBadge(status: invoice.status),
          ),

          // Date Created
          Expanded(
            flex: 2,
            child: Text(
              intl.DateFormat('yyyy/MM/dd HH:mm').format(invoice.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),

          // Action button
          SizedBox(
            width: 100,
            child: Center(
              child: TextButton(
                onPressed: () => widget.onViewDetails(invoice),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6), padding: EdgeInsets.zero),
                child: const Text('عرض وتعديل'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
