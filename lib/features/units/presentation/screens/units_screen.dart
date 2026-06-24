/// Why this file exists:
/// Interface for listing and managing rooms/units.
/// Implements [Units and Room Management MVP-004], and [UX-100/UX-500/UX-1400 UI Guidelines].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/session_providers.dart';
import '../../../properties/presentation/providers/property_providers.dart';
import '../providers/unit_providers.dart';
import '../../domain/entities/unit.dart';
import '../../../../core/common/enums/unit_status.dart';

class UnitsScreen extends ConsumerStatefulWidget {
  const UnitsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends ConsumerState<UnitsScreen> {
  bool _showArchived = false;

  void _openUnitForm(BuildContext context, int propertyId, [Unit? unit]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UnitFormDialog(propertyId: propertyId, unit: unit),
    ).then((updated) {
      if (updated == true) {
        ref.read(unitsListProvider(propertyId).notifier).fetchUnits(includeArchived: _showArchived);
      }
    });
  }

  Color _getStatusColor(UnitStatus status) {
    switch (status) {
      case UnitStatus.available:
        return const Color(0xFF10B981); // Emerald Green
      case UnitStatus.reserved:
        return const Color(0xFF3B82F6); // Blue
      case UnitStatus.occupied:
        return const Color(0xFFEF4444); // Red
      case UnitStatus.maintenance:
        return const Color(0xFFF59E0B); // Amber
      case UnitStatus.outOfService:
        return const Color(0xFF64748B); // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeProperty = ref.watch(selectedPropertyProvider);

    if (activeProperty == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الوحدات السكنية والغرَف (Units & Rooms)'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
        ),
        body: Container(
          color: const Color(0xFFF1F5F9),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.business_outlined, size: 80, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 16),
                    const Text(
                      'لم يتم تحديد عقار نشط (No Active Property Selected)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'الرجاء الانتقال لقائمة "العقارات" أولاً وتحديد منشأة نشطة لإظهار الغرف وإدارتها.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'أو اضغط على الزر أدناه لتفعيل عقار نظامي للتقييم والتجربة.',
                      style: TextStyle(color: Color(0xFF475569), fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        // Quick-Activate logic if properties exist
                        await ref.read(propertiesListProvider.notifier).fetchProperties();
                        if (!mounted) return;
                        ref.read(propertiesListProvider).whenData((list) {
                          if (list.isNotEmpty) {
                            ref.read(selectedPropertyProvider.notifier).state = list.first;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('لا توجد عقارات حالية بالدليل. رجاءً أنشئ عقاراً أولاً.')),
                            );
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('تفعيل أول عقار تلقائياً (Activate Property)'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final unitsAsync = ref.watch(unitsListProvider(activeProperty.id!));

    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة الغرف | منشأة: ${activeProperty.name} (Units List)'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          Row(
            children: [
              const Text('إظهار المؤرشفة (Show Archived)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Switch(
                value: _showArchived,
                onChanged: (val) {
                  setState(() {
                    _showArchived = val;
                  });
                  ref.read(unitsListProvider(activeProperty.id!).notifier).fetchUnits(includeArchived: val);
                },
              ),
            ],
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _openUnitForm(context, activeProperty.id!),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة غرفة جديدة (Add Unit)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF1F5F9),
        padding: const EdgeInsets.all(24),
        child: unitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('حدث خطأ في تحميل الغرف: $err', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          data: (units) {
            if (units.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.meeting_room_outlined, size: 64, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 16),
                    const Text('لا توجد غرف أو وحدات سكنية مضافة في هذا العقار حالياً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    const Text('اضغط على "إضافة غرفة جديدة" لبدء تجهيز المأوى والمخزون السياحي.', style: TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _openUnitForm(context, activeProperty.id!),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
                      child: const Text('إضافة أول وحدة للغرف (Create First Room)'),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 350,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 220,
              ),
              itemCount: units.length,
              itemBuilder: (context, idx) {
                final u = units[idx];
                final statusCol = _getStatusColor(u.status);
                final isArchived = u.deletedAt != null;

                return Card(
                  color: isArchived ? Colors.grey[50] : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusCol.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                u.status.displayName,
                                style: TextStyle(color: statusCol, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              'رقم #${u.unitNumber}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          u.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.layers, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text('الطابق: ${u.floorNumber ?? "-"}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            const SizedBox(width: 16),
                            const Icon(Icons.people_outline, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text('الاستيعاب: ${u.capacity} أشخاص', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                        if (u.notes != null && u.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            u.notes!,
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const Spacer(),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: isArchived ? null : () => _openUnitForm(context, activeProperty.id!, u),
                              icon: const Icon(Icons.edit, size: 14),
                              label: const Text('تعديل (Edit)', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6), padding: EdgeInsets.zero),
                            ),
                            if (!isArchived) ...[
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (btnContext) => AlertDialog(
                                      title: const Text('تأكيد أرشفة الغرفة (Archive Unit)'),
                                      content: Text('هل أنت متأكد من أرشفة الغرفة رقم "${u.unitNumber}"؟ لن تظهر للنزلاء في الحجوزات المستقبلية.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(btnContext),
                                          child: const Text('إلغاء (Cancel)'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.pop(btnContext);
                                            final userId = ref.read(authenticatedUserIdProvider) ?? 1;
                                             await ref.read(archiveUnitUseCaseProvider)(id: u.id!, userId: userId);
                                            ref.read(unitsListProvider(activeProperty.id!).notifier).fetchUnits(includeArchived: _showArchived);
                                          },
                                          child: const Text('تأكيد أرشفة (Archive)', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.archive, size: 14, color: Colors.red),
                                label: const Text('أرشفة (Archive)', style: TextStyle(fontSize: 12, color: Colors.red)),
                                style: TextButton.styleFrom(foregroundColor: Colors.red, padding: EdgeInsets.zero),
                              ),
                            ] else ...[
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (btnContext) => AlertDialog(
                                      title: const Text('تأكيد إلغاء أرشفة الغرفة (Confirm Restore)'),
                                      content: Text('هل أنت متأكد من إلغاء أرشفة الغرفة رقم "${u.unitNumber}"؟'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(btnContext),
                                          child: const Text('إلغاء (Cancel)'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.pop(btnContext);
                                            final userId = ref.read(authenticatedUserIdProvider) ?? 1;
                                            await ref.read(unarchiveUnitUseCaseProvider)(id: u.id!, userId: userId);
                                            ref.read(unitsListProvider(activeProperty.id!).notifier).fetchUnits(includeArchived: _showArchived);
                                          },
                                          child: const Text('استعادة (Restore)', style: TextStyle(color: Colors.green)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.unarchive, size: 14, color: Colors.green),
                                label: const Text('استعادة (Restore)', style: TextStyle(fontSize: 12, color: Colors.green)),
                                style: TextButton.styleFrom(foregroundColor: Colors.green, padding: EdgeInsets.zero),
                              ),
                            ]
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
    );
  }
}

// Dialog Form for Unit Profile Configuration
class UnitFormDialog extends ConsumerStatefulWidget {
  final int propertyId;
  final Unit? unit;

  const UnitFormDialog({Key? key, required this.propertyId, this.unit}) : super(key: key);

  @override
  ConsumerState<UnitFormDialog> createState() => _UnitFormDialogState();
}

class _UnitFormDialogState extends ConsumerState<UnitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _floorController;
  late TextEditingController _capacityController;
  late TextEditingController _notesController;
  int? _selectedUnitTypeId;
  UnitStatus _selectedStatus = UnitStatus.available;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unit?.name ?? '');
    _numberController = TextEditingController(text: widget.unit?.unitNumber ?? '');
    _floorController = TextEditingController(text: widget.unit?.floorNumber?.toString() ?? '');
    _capacityController = TextEditingController(text: widget.unit?.capacity.toString() ?? '2');
    _notesController = TextEditingController(text: widget.unit?.notes ?? '');
    _selectedUnitTypeId = widget.unit?.unitTypeId;
    _selectedStatus = widget.unit?.status ?? UnitStatus.available;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _floorController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnitTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار نوع الغرفة (Room Type) أولاً')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final capacityVal = int.parse(_capacityController.text.trim());
      final floorVal = _floorController.text.trim().isEmpty ? null : int.parse(_floorController.text.trim());

      if (widget.unit == null) {
        // Create Flow
        final userId = ref.read(authenticatedUserIdProvider) ?? 1;
        await ref.read(createUnitUseCaseProvider)(
          propertyId: widget.propertyId,
          unitTypeId: _selectedUnitTypeId!,
          name: _nameController.text,
          unitNumber: _numberController.text,
          floorNumber: floorVal,
          capacity: capacityVal,
          notes: _notesController.text,
          userId: userId,
        );
      } else {
        // Edit Flow
        final updated = widget.unit!.copyWith(
          unitTypeId: _selectedUnitTypeId!,
          name: _nameController.text,
          unitNumber: _numberController.text,
          floorNumber: floorVal,
          capacity: capacityVal,
          status: _selectedStatus,
          notes: _notesController.text,
        );
        final userId = ref.read(authenticatedUserIdProvider) ?? 1;
        await ref.read(updateUnitUseCaseProvider)(unit: updated, userId: userId);
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حفظ الغرفة: $e')),
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
    final typesAsync = ref.watch(unitTypesFutureProvider);

    return AlertDialog(
      title: Text(widget.unit == null ? 'إضافة غرفة عقارية جديدة (Add Unit)' : 'تعديل بيانات الغرفة (Edit Unit)'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                typesAsync.when(
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (e, s) => Text('خطأ في تحميل فئات الغرف: $e', style: const TextStyle(color: Colors.red)),
                  data: (types) {
                    if (_selectedUnitTypeId == null && types.isNotEmpty) {
                      _selectedUnitTypeId = types.first.id;
                    }
                    return DropdownButtonFormField<int>(
                      initialValue: _selectedUnitTypeId != null && types.any((t) => t.id == _selectedUnitTypeId)
                          ? _selectedUnitTypeId
                          : (types.isNotEmpty ? types.first.id : null),
                      decoration: const InputDecoration(labelText: 'فئة/نوع الغرفة (Unit Category) *'),
                      items: types.map((t) {
                        return DropdownMenuItem<int>(
                          value: t.id,
                          child: Text('${t.name} - ${t.description ?? ""}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedUnitTypeId = val;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'الاسم الوصفي للغرفة (Label, e.g. جناج ملكي مطل) *'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'الرجاء كتابة الاسم الوصفي الغرفي' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _numberController,
                        decoration: const InputDecoration(labelText: 'رقم الغرفة/شقة (Room/Unit Number) *'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'رقم الغرفة مطلوب لفرز الحجوزات' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _floorController,
                        decoration: const InputDecoration(labelText: 'رقم الطابق (Floor Number)'),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) return null;
                          if (int.tryParse(val) == null) return 'يجب إدخال عدد صحيح';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _capacityController,
                        decoration: const InputDecoration(labelText: 'السعة الاستيعابية أشخاص (Max Capacity) *'),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'السعة مطلوبة';
                          final cap = int.tryParse(val);
                          if (cap == null || cap <= 0) {
                            return 'أدخل رقم صحيح أكبر من 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (widget.unit != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<UnitStatus>(
                          initialValue: _selectedStatus,
                          decoration: const InputDecoration(labelText: 'حالة الصيانة/التشغيل *'),
                          items: UnitStatus.values.map((s) {
                            return DropdownMenuItem<UnitStatus>(
                              value: s,
                              child: Text(s.displayName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedStatus = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'ملاحظات وتفاصيل إضافية للوحدة (Internal Notes)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء (Cancel)'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('حفظ الغرفة (Save Unit)'),
        )
      ],
    );
  }
}
