/// Why this file exists:
/// Interface for listing, creating, editing, and cancelling Bookings.
/// Exposes the existing Booking repository, use cases, and domain services end-to-end.
/// Satisfies [Architecture Rule AR-011] and [UX-100/UX-1400 UI Guidelines].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/enums/booking_status.dart';
import '../../../../core/common/enums/invoice_status.dart';
import '../../../../core/providers/session_providers.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/audit_service.dart';
import '../../../properties/presentation/providers/property_providers.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../units/presentation/providers/unit_providers.dart';
import '../../../guests/presentation/providers/guest_providers.dart';
import '../../../invoices/presentation/providers/invoice_providers.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_providers.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  @override
  Widget build(BuildContext context) {
    final activeProperty = ref.watch(selectedPropertyProvider);
    final propertiesAsync = ref.watch(propertiesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحجوزات (Bookings Management)'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          // Select / Change Active Property right from this screen
          propertiesAsync.when(
            data: (properties) {
              if (properties.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Property>(
                        value: activeProperty != null && properties.any((p) => p.id == activeProperty.id)
                            ? properties.firstWhere((p) => p.id == activeProperty.id)
                            : null,
                        hint: const Text('اختر المنشأة (Select Property)', style: TextStyle(fontSize: 13)),
                        onChanged: (prop) {
                          if (prop != null) {
                            ref.read(selectedPropertyProvider.notifier).state = prop;
                          }
                        },
                        items: properties.map((p) {
                          return DropdownMenuItem<Property>(
                            value: p,
                            child: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: activeProperty == null ? null : () => _openBookingForm(context, activeProperty),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة حجز (New Booking)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF1F5F9),
        child: activeProperty == null
            ? _buildNoActivePropertyPrompt()
            : _buildBookingsList(activeProperty),
      ),
    );
  }

  Widget _buildNoActivePropertyPrompt() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.business_outlined, size: 36, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(height: 24),
              const Text(
                'لم يتم تحديد منشأة نشطة حالياً',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'يرجى تحديد منشأة نشطة من القائمة في الأعلى أو من الصفحة الرئيسية لإدارة وعرض الحجوزات الخاصة بها.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(propertiesListProvider.notifier).fetchProperties();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('تحديث المنشآت (Refresh Properties)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList(Property property) {
    final bookingsAsync = ref.watch(bookingsListProvider(property.id));

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('حدث خطأ في تحميل الحجوزات: $err', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(bookingsListProvider(property.id).notifier).fetchBookings();
              },
              child: const Text('إعادة المحاولة (Retry)'),
            ),
          ],
        ),
      ),
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.book_online_outlined, size: 64, color: Color(0xFF94A3B8)),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد حجوزات مسجلة لهذه المنشأة حالياً',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ابدأ بإضافة حجز جديد لهذه المنشأة عبر زر الإضافة في الأعلى.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _BookingCard(booking: booking, property: property);
          },
        );
      },
    );
  }

  void _openBookingForm(BuildContext context, Property property) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BookingFormDialog(property: property),
    ).then((saved) {
      if (saved == true) {
        ref.read(bookingsListProvider(property.id).notifier).fetchBookings();
      }
    });
  }
}

class _BookingCard extends ConsumerWidget {
  final Booking booking;
  final Property property;

  const _BookingCard({
    Key? key,
    required this.booking,
    required this.property,
  }) : super(key: key);

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.reserved:
        return const Color(0xFF3B82F6); // Blue
      case BookingStatus.checkedIn:
        return const Color(0xFF10B981); // Green
      case BookingStatus.checkedOut:
        return const Color(0xFF64748B); // Slate Gray
      case BookingStatus.cancelled:
        return const Color(0xFFEF4444); // Red
      case BookingStatus.noShow:
        return const Color(0xFFF59E0B); // Amber/Yellow
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guestsAsync = ref.watch(guestsListProvider);
    final unitsAsync = ref.watch(unitsListProvider(property.id!));
    final unitIdsAsync = ref.watch(bookingUnitIdsProvider(booking.id!));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        booking.status.displayName,
                        style: TextStyle(
                          color: _getStatusColor(booking.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'حجز رقم: ${booking.bookingNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 20),
                      tooltip: 'تفاصيل الحجز (View Details)',
                      onPressed: () => _viewBookingDetails(context, ref),
                    ),
                    if (booking.status != BookingStatus.cancelled && booking.status != BookingStatus.checkedOut) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF64748B), size: 20),
                        tooltip: 'تعديل (Edit Booking)',
                        onPressed: () => _editBooking(context, ref),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 20),
                        tooltip: 'إلغاء (Cancel Booking)',
                        onPressed: () => _confirmCancelBooking(context, ref),
                      ),
                    ],
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            
            // Primary Guest display
            guestsAsync.when(
              data: (guests) {
                final guest = guests.any((g) => g.id == booking.primaryGuestId)
                    ? guests.firstWhere((g) => g.id == booking.primaryGuestId)
                    : null;
                return _buildInfoRow(
                  Icons.person,
                  'النزيل الرئيسي:',
                  guest != null ? '${guest.fullName} (${guest.phone ?? 'بدون هاتف'})' : 'تحميل...',
                );
              },
              loading: () => _buildInfoRow(Icons.person, 'النزيل الرئيسي:', 'تحميل النزيل...'),
              error: (_, __) => _buildInfoRow(Icons.person, 'النزيل الرئيسي:', 'خطأ في التحميل'),
            ),

            const SizedBox(height: 8),

            // Units display
            unitIdsAsync.when(
              data: (uIds) {
                return unitsAsync.when(
                  data: (units) {
                    final names = units
                        .where((u) => uIds.contains(u.id))
                        .map((u) => '${u.name} (غرفة ${u.unitNumber})')
                        .join('، ');
                    return _buildInfoRow(
                      Icons.meeting_room,
                      'الوحدات السكنية:',
                      names.isNotEmpty ? names : 'غير محدد',
                    );
                  },
                  loading: () => _buildInfoRow(Icons.meeting_room, 'الوحدات السكنية:', 'تحميل...'),
                  error: (_, __) => _buildInfoRow(Icons.meeting_room, 'الوحدات السكنية:', 'خطأ في التحميل'),
                );
              },
              loading: () => _buildInfoRow(Icons.meeting_room, 'الوحدات السكنية:', 'تحميل...'),
              error: (_, __) => _buildInfoRow(Icons.meeting_room, 'الوحدات السكنية:', 'خطأ في التحميل'),
            ),

            const SizedBox(height: 8),

            _buildInfoRow(
              Icons.date_range,
              'فترة الإقامة:',
              'من ${_formatDate(booking.checkInDate)} إلى ${_formatDate(booking.checkOutDate)} (${booking.checkOutDate.difference(booking.checkInDate).inDays} ليالٍ)',
            ),

            if (booking.source != null && booking.source!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.api_outlined, 'مصدر الحجز:', booking.source!),
            ],

            if (booking.notes != null && booking.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.notes, 'ملاحظات إضافية:', booking.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day}';
  }

  void _viewBookingDetails(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => BookingDetailsDialog(booking: booking, property: property),
    );
  }

  void _editBooking(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => BookingFormDialog(property: property, booking: booking),
    ).then((saved) {
      if (saved == true) {
        ref.read(bookingsListProvider(property.id!).notifier).fetchBookings();
        ref.invalidate(bookingUnitIdsProvider(booking.id!));
        ref.invalidate(bookingGuestIdsProvider(booking.id!));
      }
    });
  }

  void _confirmCancelBooking(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('تأكيد إلغاء الحجز (Confirm Cancel)'),
        content: Text('هل أنت متأكد من رغبتك في إلغاء الحجز رقم ${booking.bookingNumber}؟\nسيؤدي هذا الإجراء إلى تغيير حالة الحجز إلى ملغي وتحرير الوحدات المسجلة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('تراجع (Back)'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                final userId = ref.read(authenticatedUserIdProvider) ?? 1;
                await ref.read(cancelBookingUseCaseProvider).execute(
                  booking: booking,
                  updatedByUserId: userId,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم إلغاء الحجز رقم ${booking.bookingNumber} بنجاح.')),
                );
                ref.read(bookingsListProvider(property.id!).notifier).fetchBookings();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('فشل الإلغاء: ${e is Failure ? e.message : e.toString()}', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('إلغاء الحجز (Cancel)'),
          ),
        ],
      ),
    );
  }
}

class BookingFormDialog extends ConsumerStatefulWidget {
  final Property property;
  final Booking? booking;

  const BookingFormDialog({
    Key? key,
    required this.property,
    this.booking,
  }) : super(key: key);

  @override
  ConsumerState<BookingFormDialog> createState() => _BookingFormDialogState();
}

class _BookingFormDialogState extends ConsumerState<BookingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bookingNumberController;
  late TextEditingController _sourceController;
  late TextEditingController _notesController;

  int? _selectedPrimaryGuestId;
  List<int> _selectedAdditionalGuestIds = [];
  List<int> _selectedUnitIds = [];
  DateTime _checkInDate = DateTime.now();
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 1));

  bool _isEdit = false;
  bool _isLoading = false;
  bool _invoiceIssued = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.booking != null;
    _bookingNumberController = TextEditingController(
      text: widget.booking?.bookingNumber ?? 'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
    );
    _sourceController = TextEditingController(text: widget.booking?.source ?? '');
    _notesController = TextEditingController(text: widget.booking?.notes ?? '');

    if (_isEdit) {
      _checkInDate = widget.booking!.checkInDate;
      _checkOutDate = widget.booking!.checkOutDate;
      _selectedPrimaryGuestId = widget.booking!.primaryGuestId;
      _checkInvoiceIssued();
      _loadExistingBookingAssociations();
    }
  }

  Future<void> _checkInvoiceIssued() async {
    try {
      final invoice = await ref.read(invoiceRepositoryProvider).getInvoiceByBookingId(widget.booking!.id!);
      if (invoice != null && invoice.status == InvoiceStatus.issued) {
        if (mounted) {
          setState(() {
            _invoiceIssued = true;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadExistingBookingAssociations() async {
    try {
      final uIds = await ref.read(bookingRepositoryProvider).getUnitIdsForBooking(widget.booking!.id!);
      final gIds = await ref.read(bookingRepositoryProvider).getGuestIdsForBooking(widget.booking!.id!);
      
      if (mounted) {
        setState(() {
          _selectedUnitIds = uIds;
          _selectedAdditionalGuestIds = gIds.where((id) => id != _selectedPrimaryGuestId).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _bookingNumberController.dispose();
    _sourceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectCheckInDate(BuildContext context) async {
    if (_isEdit && widget.booking!.status == BookingStatus.checkedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('النزيل مسجل دخوله بالفعل، لا يمكن تعديل تاريخ الدخول.')),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
    );
    if (picked != null && picked != _checkInDate) {
      setState(() {
        _checkInDate = picked;
        if (!_checkOutDate.isAfter(_checkInDate)) {
          _checkOutDate = _checkInDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectCheckOutDate(BuildContext context) async {
    if (_isEdit && widget.booking!.status == BookingStatus.checkedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('النزيل مسجل دخوله، لتعديل فترات الخروج يرجى استخدام المعالجات المالية المخصصة أو تعديل التفاصيل مباشرة بعد خروج النزلاء.')),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate.isAfter(_checkInDate) ? _checkOutDate : _checkInDate.add(const Duration(days: 1)),
      firstDate: _checkInDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
    );
    if (picked != null && picked != _checkOutDate) {
      setState(() {
        _checkOutDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final guestsAsync = ref.watch(activeGuestsForBookingProvider);
    final unitsAsync = ref.watch(activeUnitsForBookingProvider(widget.property.id!));

    return AlertDialog(
      title: Text(_isEdit ? 'تعديل الحجز (Edit Booking)' : 'إضافة حجز جديد (Create Booking)'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_invoiceIssued)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'تحذير: تم إصدار فاتورة صادرة (Issued Invoice) بالفعل لهذا الحجز. لن يسمح النظام بتغيير البيانات المالية والتاريخية مباشرة (Frozen as per BR-307).',
                            style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Booking Number
                TextFormField(
                  controller: _bookingNumberController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الحجز (Booking Number) *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال رقم الحجز';
                    }
                    return null;
                  },
                  enabled: !_invoiceIssued,
                ),
                const SizedBox(height: 16),

                // Primary Guest
                guestsAsync.when(
                  data: (guests) {
                    return DropdownButtonFormField<int>(
                      initialValue: _selectedPrimaryGuestId != null && guests.any((g) => g.id == _selectedPrimaryGuestId)
                          ? _selectedPrimaryGuestId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'النزيل الرئيسي (Primary Guest) *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      hint: const Text('اختر النزيل'),
                      items: guests.map((g) {
                        return DropdownMenuItem<int>(
                          value: g.id,
                          child: Text(g.fullName),
                        );
                      }).toList(),
                      onChanged: _isEdit || _invoiceIssued ? null : (val) {
                        setState(() {
                          _selectedPrimaryGuestId = val;
                          _selectedAdditionalGuestIds.remove(val);
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'يرجى تحديد النزيل الرئيسي';
                        }
                        return null;
                      },
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (e, _) => Text('خطأ في تحميل النزلاء: $e'),
                ),
                const SizedBox(height: 16),

                // Check-in and Check-out Date Pickers
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('تاريخ الدخول (Check-In) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: _invoiceIssued ? null : () => _selectCheckInDate(context),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text('${_checkInDate.year}/${_checkInDate.month}/${_checkInDate.day}'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('تاريخ الخروج (Check-Out) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: _invoiceIssued ? null : () => _selectCheckOutDate(context),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text('${_checkOutDate.year}/${_checkOutDate.month}/${_checkOutDate.day}'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Select Unit(s) Multi-Select
                if (!_isEdit) ...[
                  const Text('اختر الوحدات السكنية (Select Unit(s)) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  unitsAsync.when(
                    data: (units) {
                      if (units.isEmpty) {
                        return const Text('لا توجد غرف أو وحدات سكنية مسجلة لهذا العقار. يرجى إضافة غرف أولاً.', style: TextStyle(color: Colors.red, fontSize: 12));
                      }
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: units.length,
                          itemBuilder: (context, index) {
                            final unit = units[index];
                            final isChecked = _selectedUnitIds.contains(unit.id);
                            return CheckboxListTile(
                              title: Text('${unit.name} (غرفة رقم ${unit.unitNumber} - السعة: ${unit.capacity})'),
                              subtitle: Text('الحالة: ${unit.status.name}'),
                              value: isChecked,
                              dense: true,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedUnitIds.add(unit.id!);
                                  } else {
                                    _selectedUnitIds.remove(unit.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Center(child: LinearProgressIndicator()),
                    error: (e, _) => Text('خطأ في تحميل الغرف: $e'),
                  ),
                  const SizedBox(height: 16),
                ],

                // Optional Additional Guests
                if (!_isEdit) ...[
                  const Text('نزلاء إضافيون مصلحون (Additional Guests) - اختياري', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  guestsAsync.when(
                    data: (guests) {
                      final filteredGuests = guests.where((g) => g.id != _selectedPrimaryGuestId).toList();
                      if (filteredGuests.isEmpty) {
                        return const Text('لا يوجد نزلاء إضافيون متاحون.', style: TextStyle(color: Colors.grey, fontSize: 12));
                      }
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredGuests.length,
                          itemBuilder: (context, index) {
                            final guest = filteredGuests[index];
                            final isChecked = _selectedAdditionalGuestIds.contains(guest.id);
                            return CheckboxListTile(
                              title: Text(guest.fullName),
                              value: isChecked,
                              dense: true,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedAdditionalGuestIds.add(guest.id!);
                                  } else {
                                    _selectedAdditionalGuestIds.remove(guest.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Source (API/Platform Source)
                TextFormField(
                  controller: _sourceController,
                  decoration: const InputDecoration(
                    labelText: 'مصدر الحجز (Source - Booking.com, walk-in, etc.)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  enabled: !_invoiceIssued,
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات وتفاصيل (Notes)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء (Cancel)'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_isEdit ? 'حفظ التعديلات (Save)' : 'إنشاء حجز (Create)'),
        ),
      ],
    );
  }

  Future<void> _saveBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEdit && _selectedUnitIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب اختيار وحدة سكنية واحدة على الأقل لإتمام الحجز.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = ref.read(authenticatedUserIdProvider) ?? 1;

      if (_isEdit) {
        final existingBooking = widget.booking!;
        await ref.read(editBookingUseCaseProvider).execute(
          existingBooking: existingBooking,
          newNotes: _notesController.text.trim(),
          newSource: _sourceController.text.trim(),
          newCheckInDate: _checkInDate,
          newCheckOutDate: _checkOutDate,
          invoiceIssued: _invoiceIssued,
          updatedByUserId: userId,
        );
      } else {
        await ref.read(createBookingUseCaseProvider).execute(
          propertyId: widget.property.id!,
          primaryGuestId: _selectedPrimaryGuestId!,
          bookingNumber: _bookingNumberController.text.trim(),
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
          unitIds: _selectedUnitIds,
          additionalGuestIds: _selectedAdditionalGuestIds,
          createdByUserId: userId,
          source: _sourceController.text.trim(),
          notes: _notesController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'تم تعديل الحجز بنجاح' : 'تم إنشاء الحجز بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ: ${e is Failure ? e.message : e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class BookingDetailsDialog extends ConsumerWidget {
  final Booking booking;
  final Property property;

  const BookingDetailsDialog({
    Key? key,
    required this.booking,
    required this.property,
  }) : super(key: key);

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guestsAsync = ref.watch(guestsListProvider);
    final unitsAsync = ref.watch(unitsListProvider(property.id!));
    final unitIdsAsync = ref.watch(bookingUnitIdsProvider(booking.id!));
    final guestIdsAsync = ref.watch(bookingGuestIdsProvider(booking.id!));

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('تفاصيل الحجز #${booking.bookingNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('الحالة العامة والبيانات (Status & Core)'),
              _buildDetailItem(Icons.info_outline, 'حالة الحجز التشغيلية:', booking.status.displayName),
              _buildDetailItem(Icons.tag, 'معرف الحجز الفريد (UUID):', booking.uuid),
              _buildDetailItem(Icons.api_outlined, 'مصدر الحجز:', booking.source ?? 'غير متوفر'),
              
              const SizedBox(height: 16),
              _buildSectionTitle('التاريخ والمواعيد (Timeline)'),
              _buildDetailItem(Icons.calendar_today, 'تاريخ الدخول المخطط:', _formatDate(booking.checkInDate)),
              _buildDetailItem(Icons.calendar_today, 'تاريخ الخروج المخطط:', _formatDate(booking.checkOutDate)),
              _buildDetailItem(Icons.nights_stay, 'عدد الليالي الإجمالي:', '${booking.checkOutDate.difference(booking.checkInDate).inDays} ليالٍ'),
              _buildDetailItem(
                Icons.login, 
                'تاريخ الدخول الفعلي:', 
                booking.actualCheckIn != null ? _formatDate(booking.actualCheckIn!) : 'لم يتم الدخول بعد',
              ),
              _buildDetailItem(
                Icons.logout, 
                'تاريخ الخروج الفعلي:', 
                booking.actualCheckOut != null ? _formatDate(booking.actualCheckOut!) : 'لم يتم الخروج بعد',
              ),

              const SizedBox(height: 16),
              _buildSectionTitle('النزلاء المسجلون (Guests)'),
              guestsAsync.when(
                data: (guests) {
                  final primary = guests.any((g) => g.id == booking.primaryGuestId)
                      ? guests.firstWhere((g) => g.id == booking.primaryGuestId)
                      : null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem(Icons.person, 'النزيل الرئيسي:', primary != null ? primary.fullName : 'تحميل النزيل...'),
                      
                      // Additional guests mapping
                      guestIdsAsync.when(
                        data: (gIds) {
                          final additional = guests.where((g) => gIds.contains(g.id) && g.id != booking.primaryGuestId).map((g) => g.fullName).join('، ');
                          return _buildDetailItem(
                            Icons.group, 
                            'المرافقون الإضافيون:', 
                            additional.isNotEmpty ? additional : 'لا يوجد مرافقون إضافيون مسجلون',
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('خطأ في تحميل المرافقين'),
                      )
                    ],
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (e, _) => Text('خطأ في تحميل النزلاء: $e'),
              ),

              const SizedBox(height: 16),
              _buildSectionTitle('الغرف والوحدات المخصصة (Booked Units)'),
              unitIdsAsync.when(
                data: (uIds) {
                  return unitsAsync.when(
                    data: (units) {
                      final bookedUnits = units.where((u) => uIds.contains(u.id));
                      if (bookedUnits.isEmpty) {
                        return const Text('لم يتم العثور على غرف مخصصة لهذا الحجز.', style: TextStyle(color: Colors.red));
                      }
                      return Column(
                        children: bookedUnits.map((u) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.meeting_room, color: Color(0xFF3B82F6), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${u.name} (غرفة رقم ${u.unitNumber} - الطابق ${u.floorNumber ?? 'غير محدد'})',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: LinearProgressIndicator()),
                    error: (e, _) => Text('خطأ في تحميل الغرف: $e'),
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (e, _) => Text('خطأ في تحميل الغرف المخصصة: $e'),
              ),

              const SizedBox(height: 16),
              _buildSectionTitle('ملاحظات وسجل تدقيق العمليات (Notes & Audit)'),
              _buildDetailItem(Icons.notes, 'ملاحظات الحجز:', booking.notes != null && booking.notes!.isNotEmpty ? booking.notes! : 'لا توجد ملاحظات مسجلة'),
              _buildDetailItem(Icons.person_pin, 'أنشئ بواسطة المستخدم:', 'المستخدم رقم #${booking.createdBy}'),
              _buildDetailItem(Icons.access_time, 'تاريخ التسجيل في النظام:', _formatDate(booking.createdAt)),
              
              // Direct Actions inside Details Panel for Testing Status transitions
              if (booking.status != BookingStatus.cancelled && booking.status != BookingStatus.checkedOut) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                const Text('إجراءات تشغيلية سريعة (Testing Actions):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (booking.status == BookingStatus.reserved)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateBookingStatus(context, ref, 'checkedIn', 'تسجيل دخول النزيل'),
                          icon: const Icon(Icons.login, size: 16),
                          label: const Text('تسجيل دخول (Check In)'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                        ),
                      ),
                    if (booking.status == BookingStatus.checkedIn)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateBookingStatus(context, ref, 'checkedOut', 'تسجيل خروج النزيل وتفريغ الغرفة'),
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text('تسجيل خروج (Check Out)'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B), foregroundColor: Colors.white),
                        ),
                      ),
                    if (booking.status == BookingStatus.reserved) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateBookingStatus(context, ref, 'noShow', 'تسجيل عدم حضور النزيل'),
                          icon: const Icon(Icons.person_off_outlined, size: 16),
                          label: const Text('عدم حضور (No Show)'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateBookingStatus(BuildContext context, WidgetRef ref, String newStatus, String actionDesc) async {
    try {
      final userId = ref.read(authenticatedUserIdProvider) ?? 1;
      await ref.read(bookingRepositoryProvider).updateBookingStatus(
        bookingId: booking.id!,
        status: newStatus,
        updatedByUserId: userId,
      );

      // Refresh the units so the room status transitions correctly
      if (newStatus == 'checkedOut') {
        final uIds = await ref.read(bookingRepositoryProvider).getUnitIdsForBooking(booking.id!);
        for (final unitId in uIds) {
          await ref.read(unitRepositoryProvider).updateUnitStatus(unitId: unitId, status: 'available');
        }
      } else if (newStatus == 'checkedIn') {
        final uIds = await ref.read(bookingRepositoryProvider).getUnitIdsForBooking(booking.id!);
        for (final unitId in uIds) {
          await ref.read(unitRepositoryProvider).updateUnitStatus(unitId: unitId, status: 'occupied');
        }
      } else if (newStatus == 'noShow') {
        final uIds = await ref.read(bookingRepositoryProvider).getUnitIdsForBooking(booking.id!);
        for (final unitId in uIds) {
          await ref.read(unitRepositoryProvider).updateUnitStatus(unitId: unitId, status: 'available');
        }
      }

      // Log audit
      await ref.read(auditServiceProvider).log(
        propertyId: property.id!,
        userId: userId,
        entityType: 'booking',
        entityId: booking.id!,
        action: 'Update Status',
        description: 'تغيير حالة الحجز رقم ${booking.bookingNumber} إلى: $actionDesc',
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث حالة الحجز إلى: $newStatus')),
        );
        ref.read(bookingsListProvider(property.id!).notifier).fetchBookings();
        ref.read(unitsListProvider(property.id!).notifier).fetchUnits();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء تحديث الحالة: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
          const SizedBox(width: 6),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
        ],
      ),
    );
  }
}
