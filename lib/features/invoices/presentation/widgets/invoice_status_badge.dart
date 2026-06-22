/// Why the file exists:
/// Reusable status badge component for displaying InvoiceStatus in a styled chip, satisfying UX Guidelines.
library;

import 'package:flutter/material.dart';
import '../../../../core/common/enums/invoice_status.dart';

class InvoiceStatusBadge extends StatelessWidget {
  final InvoiceStatus status;

  const InvoiceStatusBadge({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
