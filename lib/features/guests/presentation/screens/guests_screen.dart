/// Why this file exists:
/// Interface for Guest Directory and profile coordination.
/// Supports search filters, archiving toggles, error tracking, and nested contact managers.
/// Implements [Presentation Layer Rules] using Arabic primary and English secondary typography.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/guest_providers.dart';
import '../../domain/entities/guest.dart';
import '../../domain/entities/guest_contact.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/providers/session_providers.dart';

class GuestsScreen extends ConsumerStatefulWidget {
  const GuestsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends ConsumerState<GuestsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String val) {
    ref.read(guestSearchQueryProvider.notifier).state = val;
    final accountId = ref.read(activeAccountIdProvider);
    if (accountId != null) {
      ref.read(guestsListProvider.notifier).fetchGuests(
            accountId,
            query: val,
            includeArchived: ref.read(guestIncludeArchivedProvider),
          );
    }
  }

  void _onToggleArchived(bool val) {
    ref.read(guestIncludeArchivedProvider.notifier).state = val;
    final accountId = ref.read(activeAccountIdProvider);
    if (accountId != null) {
      ref.read(guestsListProvider.notifier).fetchGuests(
            accountId,
            query: ref.read(guestSearchQueryProvider),
            includeArchived: val,
          );
    }
  }

  void _openGuestForm(BuildContext context, [Guest? guest]) {
    final accountId = ref.read(activeAccountIdProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GuestFormDialog(guest: guest),
    ).then((saved) {
      if (saved == true && accountId != null) {
        ref.read(guestsListProvider.notifier).fetchGuests(
              accountId,
              query: ref.read(guestSearchQueryProvider),
              includeArchived: ref.read(guestIncludeArchivedProvider),
            );
      }
    });
  }

  void _confirmRestore(BuildContext context, Guest guest) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.unarchive, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('تأكيد الاستعادة / Restore Guest'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من رغبتك في إلغاء أرشفة نزيل: "${guest.fullName}"؟',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'ستتم استعادة الضيف إلى دليل البحث النشط وسيصبح متاحاً للحجوزات الجديدة.',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء (Cancel)'),
          ),
          ElevatedButton(
            onPressed: () async {
              final activeAccountId = ref.read(activeAccountIdProvider);
              final authenticatedUserId = ref.read(authenticatedUserIdProvider);
              if (activeAccountId == null || authenticatedUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('لا يمكن الاستعادة: سياق المستخدم أو الحساب غير متوفر (Missing active user/account context).')),
                );
                return;
              }
              Navigator.pop(dialogCtx);
              try {
                await ref.read(unarchiveGuestUseCaseProvider)(guest.id!, authenticatedUserId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت استعادة ملف الضيف بنجاح.')),
                );
                ref.read(guestsListProvider.notifier).fetchGuests(
                      activeAccountId,
                      query: ref.read(guestSearchQueryProvider),
                      includeArchived: ref.read(guestIncludeArchivedProvider),
                    );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('فشلت عملية الاستعادة: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الاستعادة (Restore)'),
          ),
        ],
      ),
    );
  }

  void _confirmArchive(BuildContext context, Guest guest) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('تأكيد الأرشفة / Archive Guest'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من رغبتك في أرشفة نزيل: "${guest.fullName}"؟',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'لن يظهر الضيف في دليل البحث النشط، ولكن سيتم الاحتفاظ بكافة فواتيره وحجوزاته والبيانات التشغيلية التاريخية بأمان.',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء (Cancel)'),
          ),
          ElevatedButton(
            onPressed: () async {
              final activeAccountId = ref.read(activeAccountIdProvider);
              final authenticatedUserId = ref.read(authenticatedUserIdProvider);
              if (activeAccountId == null || authenticatedUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('لا يمكن الأرشفة: سياق المستخدم أو الحساب غير متوفر (Missing active user/account context).')),
                );
                return;
              }
              Navigator.pop(dialogCtx);
              try {
                await ref.read(archiveGuestUseCaseProvider)(guest.id!, authenticatedUserId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت أرشفة ملف الضيف بنجاح.')),
                );
                ref.read(guestsListProvider.notifier).fetchGuests(
                      activeAccountId,
                      query: ref.read(guestSearchQueryProvider),
                      includeArchived: ref.read(guestIncludeArchivedProvider),
                    );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('فشلت عملية الأرشفة: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الأرشفة (Archive)'),
          ),
        ],
      ),
    );
  }

  void _showGuestDetails(BuildContext context, Guest guest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          guest.fullName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (guest.deletedAt != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'مؤرشف / Archived',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  _buildDetailRow(Icons.phone, 'رقم التواصل الأساسي:', guest.phone ?? 'غير مسجل'),
                  _buildDetailRow(Icons.email, 'البريد الإلكتروني:', guest.email ?? 'غير مسجل'),
                  _buildDetailRow(Icons.flag, 'الجنسية / Nationality:', guest.nationality ?? 'غير مسجل'),
                  _buildDetailRow(
                    Icons.badge, 
                    'وثيقة التحقق / Identity Document:', 
                    guest.documentType != null && guest.documentNumber != null 
                        ? '${guest.documentType} - ${guest.documentNumber}' 
                        : 'غير مسجل',
                  ),
                  _buildDetailRow(Icons.cake, 'تاريخ الميلاد / DOB:', guest.dateOfBirth ?? 'غير مسجل'),
                  _buildDetailRow(Icons.home, 'العنوان السكني:', guest.address ?? 'غير مسجل'),
                  _buildDetailRow(Icons.notes, 'ملاحظات النزيل:', guest.notes ?? 'لا توجد ملاحظات إضافية'),

                  const SizedBox(height: 24),
                  const Text('الاتصالات والروابط الفرعية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  if (guest.contacts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('لا توجد جهات اتصال بديلة مسجلة للنزيل.', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ...guest.contacts.map((c) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: const Color(0xFFF8FAFC),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            leading: const CircleAvatar(
                              radius: 14,
                              backgroundColor: Color(0xFF3B82F6),
                              child: Icon(Icons.contact_mail, size: 12, color: Colors.white),
                            ),
                            title: Text(c.contactValue, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('تصنيف العلاقة: ${c.contactType}', style: const TextStyle(fontSize: 11)),
                          ),
                        )),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _openGuestForm(context, guest);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('تعديل ملف الضيف (Edit Guest Profile)'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF475569)),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569), fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guestsAsync = ref.watch(guestsListProvider);
    final includeArchived = ref.watch(guestIncludeArchivedProvider);
    final activeAccountId = ref.watch(activeAccountIdProvider);
    final authenticatedUserId = ref.watch(authenticatedUserIdProvider);

    return Scaffold(
      body: Container(
        color: const Color(0xFFF1F5F9),
        child: Column(
          children: [
            // Warning notice banner if session/account infrastructure is missing or offline
            if (activeAccountId == null || authenticatedUserId == null)
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
                      child: Text(
                        'تنبيه تبعية هندسية: سياق الجلسة والحساب النشط مفقود. لإكمال دمج نظام النزلاء، يرجى تفعيل مصادر الهوية وسياق الجلسات الموحد.\n'
                        'Dependency Alert: Active Account / User Session context is unresolved. In production, guest ownership and immutable transaction logs derive from validated login states.',
                        style: TextStyle(color: const Color(0xFF78350F), fontSize: 11, fontWeight: FontWeight.w500, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

            // Head Area
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'دليل إدارة النزلاء والضيوف | Guest Directory',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'عرض ملفات الضيوف المشتركة لحسابك السياحي، والتحقق المستمر من السجلات والهويات والاتصالات البديلة.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openGuestForm(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('إضافة ضيف جديد (Add Guest)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Toolbar Area
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearch,
                        decoration: const InputDecoration(
                          hintText: 'ابحث باسم الضيف أو رقم الجوال أو الهوية أو البريد...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Row(
                    children: [
                      const Text(
                        'إظهار الأرشيف (Archived)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: includeArchived,
                        onChanged: _onToggleArchived,
                        activeThumbColor: const Color(0xFF3B82F6),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // Main List Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: guestsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('فشل جلب النزلاء: $err', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  data: (guests) {
                    if (guests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline, size: 64, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 16),
                            const Text(
                              'لا يوجد ضيوف مضافين في الدليل حالياً',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'اضغط على "إضافة ضيف جديد" لتسجيل ملف إلكتروني بالدليل الموحد.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => _openGuestForm(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('إنشاء أول ضيف بالدليل (Create Guest)'),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 380,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 220,
                      ),
                      itemCount: guests.length,
                      itemBuilder: (context, idx) {
                        final g = guests[idx];
                        final isArchived = g.deletedAt != null;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isArchived ? Colors.orange.withValues(alpha: 0.3) : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          color: isArchived ? const Color(0xFFFFFBEB) : Colors.white,
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isArchived 
                                          ? Colors.orange.withValues(alpha: 0.1) 
                                          : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                      child: Icon(
                                        isArchived ? Icons.archive_outlined : Icons.person_outline, 
                                        color: isArchived ? Colors.orange : const Color(0xFF3B82F6),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            g.fullName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            g.email ?? 'لا يوجد بريد الكتروني',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildCompactRow(Icons.phone, g.phone ?? 'مجهول'),
                                      _buildCompactRow(Icons.flag, g.nationality ?? 'غير مسجل'),
                                      _buildCompactRow(
                                        Icons.badge, 
                                        g.documentNumber != null 
                                            ? '${g.documentType ?? "وثيقة"}: ${g.documentNumber}' 
                                            : 'لا تتوفر بطاقة إثبات مفعّلة',
                                      ),
                                    ],
                                  ),
                                ),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.info_outline, size: 18, color: Color(0xFF3B82F6)),
                                      tooltip: 'عرض التفاصيل (Details)',
                                      onPressed: () => _showGuestDetails(context, g),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
                                      tooltip: 'تعديل البيانات (Edit)',
                                      onPressed: () => _openGuestForm(context, g),
                                    ),
                                    if (!isArchived)
                                      IconButton(
                                        icon: const Icon(Icons.archive_outlined, size: 18, color: Colors.orange),
                                        tooltip: 'أرشفة (Archive)',
                                        onPressed: () => _confirmArchive(context, g),
                                      )
                                    else
                                      IconButton(
                                        icon: const Icon(Icons.unarchive_outlined, size: 18, color: Colors.green),
                                        tooltip: 'استعادة (Restore)',
                                        onPressed: () => _confirmRestore(context, g),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class GuestFormDialog extends ConsumerStatefulWidget {
  final Guest? guest;

  const GuestFormDialog({Key? key, this.guest}) : super(key: key);

  @override
  ConsumerState<GuestFormDialog> createState() => _GuestFormDialogState();
}

class _GuestFormDialogState extends ConsumerState<GuestFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _nationalityController;
  late TextEditingController _docNumberController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  String? _selectedDocType;
  bool _isSaving = false;

  // Local contact builder list
  final List<GuestContact> _contacts = [];
  final TextEditingController _contactTypeController = TextEditingController();
  final TextEditingController _contactValueController = TextEditingController();

  final List<String> _identityTypes = [
    'هوية وطنية / National ID',
    'جواز سفر / Passport',
    'إقامة / Residence Permit',
    'أخرى / Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.guest?.fullName ?? '');
    _phoneController = TextEditingController(text: widget.guest?.phone ?? '');
    _emailController = TextEditingController(text: widget.guest?.email ?? '');
    _nationalityController = TextEditingController(text: widget.guest?.nationality ?? '');
    _docNumberController = TextEditingController(text: widget.guest?.documentNumber ?? '');
    _dobController = TextEditingController(text: widget.guest?.dateOfBirth ?? '');
    _addressController = TextEditingController(text: widget.guest?.address ?? '');
    _notesController = TextEditingController(text: widget.guest?.notes ?? '');

    if (widget.guest?.documentType != null) {
      if (_identityTypes.contains(widget.guest!.documentType)) {
        _selectedDocType = widget.guest!.documentType;
      } else {
        _selectedDocType = widget.guest!.documentType;
        if (!_identityTypes.contains(_selectedDocType)) {
          _identityTypes.add(_selectedDocType!);
        }
      }
    }

    if (widget.guest?.contacts != null) {
      _contacts.addAll(widget.guest!.contacts);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nationalityController.dispose();
    _docNumberController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _contactTypeController.dispose();
    _contactValueController.dispose();
    super.dispose();
  }

  void _addContact() {
    final type = _contactTypeController.text.trim();
    final value = _contactValueController.text.trim();

    if (type.isEmpty || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة تصنيف ونوع الاتصال والروابط أولاً.')),
      );
      return;
    }

    setState(() {
      _contacts.add(GuestContact(
        contactType: type,
        contactValue: value,
        createdAt: DateTime.now(),
      ));
      _contactTypeController.clear();
      _contactValueController.clear();
    });
  }

  void _removeContact(int idx) {
    setState(() {
      _contacts.removeAt(idx);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final activeAccountId = ref.read(activeAccountIdProvider);
    final authenticatedUserId = ref.read(authenticatedUserIdProvider);

    if (activeAccountId == null || authenticatedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يمكن إتمام العملية: سياق الحساب النشط أو المستخدم غير متوفر (Missing active account or user session context).'
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.guest == null) {
        // Create Flow
        await ref.read(createGuestUseCaseProvider)(
          accountId: activeAccountId,
          userId: authenticatedUserId,
          fullName: _nameController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          nationality: _nationalityController.text.isEmpty ? null : _nationalityController.text,
          documentType: _selectedDocType,
          documentNumber: _docNumberController.text.isEmpty ? null : _docNumberController.text,
          dateOfBirth: _dobController.text.isEmpty ? null : _dobController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          contacts: _contacts,
        );
      } else {
        // Edit Flow
        final updated = widget.guest!.copyWith(
          fullName: _nameController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          nationality: _nationalityController.text.isEmpty ? null : _nationalityController.text,
          documentType: _selectedDocType,
          documentNumber: _docNumberController.text.isEmpty ? null : _docNumberController.text,
          dateOfBirth: _dobController.text.isEmpty ? null : _dobController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          contacts: _contacts,
        );
        await ref.read(updateGuestUseCaseProvider)(updated, authenticatedUserId);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is Failure ? e.message : 'فشلت عملية الحفظ: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleAr = widget.guest == null ? 'إضافة ضيف جديد' : 'تعديل ملف الضيف';
    final titleEn = widget.guest == null ? 'Add Guest Profile' : 'Edit Guest Profile';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Form Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$titleAr ($titleEn)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Form Row 1: Name and National ID Choice
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'اسم الضيف الكامل / Full Name *',
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'الاسم مطلوب وإلزامي لملف الضيف';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedDocType,
                              decoration: const InputDecoration(
                                labelText: 'نوع الوثيقة / Document Type',
                                prefixIcon: Icon(Icons.badge),
                              ),
                              items: _identityTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type, style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedDocType = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Form Row 2: Doc Number and Nationality
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _docNumberController,
                              decoration: const InputDecoration(
                                labelText: 'رقم وثيقة الهوية والمستند / Doc Number',
                                prefixIcon: Icon(Icons.assignment_ind),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _nationalityController,
                              decoration: const InputDecoration(
                                labelText: 'الجنسية / Nationality',
                                prefixIcon: Icon(Icons.flag),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Form Row 3: Phone and Email (Validated)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'رقم الجوال الأساسي / Primary Phone',
                                prefixIcon: Icon(Icons.phone),
                                hintText: 'مثال: +966500000000',
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (v) {
                                if (v != null && v.trim().isNotEmpty) {
                                  final r = RegExp(r'^\+?[0-9\s\-]{7,15}$');
                                  if (!r.hasMatch(v.trim())) {
                                    return 'صيغة رقم الهاتف غير صالحة';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'البريد الإلكتروني / Email Address',
                                prefixIcon: Icon(Icons.email),
                                hintText: 'example@domain.com',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v != null && v.trim().isNotEmpty) {
                                  final r = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                  if (!r.hasMatch(v.trim())) {
                                    return 'صيغة البريد الإلكتروني غير صالحة';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Form Row 4: Date Of Birth and Address
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dobController,
                              decoration: const InputDecoration(
                                labelText: 'تاريخ الميلاد / Date of Birth',
                                prefixIcon: Icon(Icons.cake),
                                hintText: 'YYYY-MM-DD',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'العنوان السكني الشامل / Address',
                                prefixIcon: Icon(Icons.home),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Form Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات وتنبيهات تشغيلية خاصة بالضيف / Notes',
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),

                      // Secondary contacts section
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'جهات الاتصال الفرعية والروابط (Secondary Contacts Management)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'أضف أرقام رفقاء السفر أو جهات الاتصال في حالات الطوارئ وهواتف العمل.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 12),

                            // Added contacts list
                            if (_contacts.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('لا توجد جهات اتصال مضافة حالياً.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _contacts.length,
                                itemBuilder: (context, idx) {
                                  final c = _contacts[idx];
                                  return Card(
                                    color: Colors.white,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    child: ListTile(
                                      title: Text(c.contactValue, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      subtitle: Text(c.contactType, style: const TextStyle(fontSize: 11)),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                        onPressed: () => _removeContact(idx),
                                      ),
                                      dense: true,
                                    ),
                                  );
                                },
                              ),

                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),

                            // Add fields
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _contactTypeController,
                                    decoration: const InputDecoration(
                                      labelText: 'العلاقة / Type',
                                      hintText: 'مثال: طوارئ، زوج، هاتف عمل',
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _contactValueController,
                                    decoration: const InputDecoration(
                                      labelText: 'القيمة / Code or Phone',
                                      hintText: '+966...',
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _addContact,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Icon(Icons.add, size: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('إلغاء (Cancel)'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('حفظ البيانات (Save Profile)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
