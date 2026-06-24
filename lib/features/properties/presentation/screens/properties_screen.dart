/// Why this file exists:
/// Interface for listing and managing properties and property-specific settings.
/// Implements [Properties management MVP-003], [Property Settings MVP-003], and [UX-100/UX-1400 UI Guidelines].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/session_providers.dart';
import '../providers/property_providers.dart';
import '../../domain/entities/property.dart';

class PropertiesScreen extends ConsumerStatefulWidget {
  const PropertiesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends ConsumerState<PropertiesScreen> {
  bool _showArchived = false;

  void _openPropertyForm(BuildContext context, [Property? property]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PropertyFormDialog(property: property),
    ).then((updated) {
      if (updated == true) {
        ref.read(propertiesListProvider.notifier).fetchProperties(includeArchived: _showArchived);
      }
    });
  }

  void _openSettingsDialog(BuildContext context, Property property) {
    showDialog(
      context: context,
      builder: (context) => PropertySettingsDialog(property: property),
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العقارات والمنشآت (Properties & Settings)'),
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
                  ref.read(propertiesListProvider.notifier).fetchProperties(includeArchived: val);
                },
              ),
            ],
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _openPropertyForm(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة عقار جديد (Add Property)'),
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
        child: propertiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('حدث خطأ في تحميل البيانات: $err', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          data: (properties) {
            if (properties.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.business_outlined, size: 64, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 16),
                    const Text('لا توجد عقارات حالية مضافة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    const Text('اضغط على "إضافة عقار جديد" في الأعلى للبدء', style: TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _openPropertyForm(context),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
                      child: const Text('إضافة أول عقار (Create First Property)'),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: properties.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final prop = properties[index];
                final isArchived = prop.deletedAt != null;
                final isSelected = ref.watch(selectedPropertyProvider)?.id == prop.id;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.5) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  color: isArchived ? Colors.grey[100] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: isSelected 
                              ? const Color(0xFF3B82F6).withValues(alpha: 0.12) 
                              : const Color(0xFF64748B).withValues(alpha: 0.1),
                          child: Icon(
                            isArchived ? Icons.archive_outlined : Icons.business, 
                            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF475569), 
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    prop.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                  ),
                                  if (isArchived) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4)),
                                      child: const Text('مؤرشف (Archived)', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(4)),
                                      child: const Text('العقار النشط (Active Property)', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                key: ValueKey('prop-info-${prop.id}'),
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${prop.address ?? "-"}, ${prop.city ?? "-"}, ${prop.country ?? "-"}',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 24),
                                  const Icon(Icons.payments_outlined, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'العملة: ${prop.currencyCode}',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 24),
                                  const Icon(Icons.today_outlined, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'اليوم التشغيلي: ${prop.useBusinessDays ? "مفعّل (Enabled)" : "خارج التفعيل (Disabled)"}',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (prop.phone != null) ...[
                                    const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(prop.phone!, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                    const SizedBox(width: 24),
                                  ],
                                  if (prop.email != null) ...[
                                    const Icon(Icons.email_outlined, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(prop.email!, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Action menu
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    ref.read(selectedPropertyProvider.notifier).state = prop;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('تم تحديد المنشأة النشطة: ${prop.name}')),
                                    );
                                  },
                                  icon: const Icon(Icons.check_circle_outline, size: 16),
                                  label: const Text('تفعيل (Activate)'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: isSelected ? Colors.green : const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _openSettingsDialog(context, prop),
                                  icon: const Icon(Icons.tune, size: 16),
                                  label: const Text('الإعدادات (Settings)'),
                                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF475569)),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: isArchived ? null : () => _openPropertyForm(context, prop),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('تعديل (Edit)'),
                                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
                                ),
                                if (!isArchived) ...[
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (btnContext) => AlertDialog(
                                          title: const Text('تأكيد الأرشفة (Confirm Archive)'),
                                          content: Text('هل أنت متأكد من أرشفة العقار "${prop.name}"؟ ستتحول كافة الوحدات التابعة له للمؤرشفة أيضاً ولا يمكن حذف العقار مالياً.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(btnContext),
                                              child: const Text('إلغاء (Cancel)'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(btnContext);
                                                final userId = ref.read(authenticatedUserIdProvider) ?? 1;
                                                await ref.read(archivePropertyUseCaseProvider)(id: prop.id!, userId: userId);
                                                ref.read(propertiesListProvider.notifier).fetchProperties(includeArchived: _showArchived);
                                                if (ref.read(selectedPropertyProvider)?.id == prop.id) {
                                                  ref.read(selectedPropertyProvider.notifier).state = null;
                                                }
                                              },
                                              child: const Text('تأكيد أرشفة (Archive)', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.archive, size: 16, color: Colors.red),
                                    label: const Text('أرشفة (Archive)', style: TextStyle(color: Colors.red)),
                                  ),
                                ] else ...[
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (btnContext) => AlertDialog(
                                          title: const Text('تأكيد إلغاء أرشفة العقار (Confirm Restore)'),
                                          content: Text('هل أنت متأكد من إلغاء أرشفة العقار "${prop.name}"؟'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(btnContext),
                                              child: const Text('إلغاء (Cancel)'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(btnContext);
                                                final userId = ref.read(authenticatedUserIdProvider) ?? 1;
                                                await ref.read(unarchivePropertyUseCaseProvider)(id: prop.id!, userId: userId);
                                                ref.read(propertiesListProvider.notifier).fetchProperties(includeArchived: _showArchived);
                                              },
                                              child: const Text('استعادة (Restore)', style: TextStyle(color: Colors.green)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.unarchive, size: 16, color: Colors.green),
                                    label: const Text('استعادة (Restore)', style: TextStyle(color: Colors.green)),
                                  ),
                                ]
                              ],
                            )
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

// Dialog Form Widget with full input validation
class PropertyFormDialog extends ConsumerStatefulWidget {
  final Property? property;

  const PropertyFormDialog({Key? key, this.property}) : super(key: key);

  @override
  ConsumerState<PropertyFormDialog> createState() => _PropertyFormDialogState();
}

class _PropertyFormDialogState extends ConsumerState<PropertyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _currencyController;
  bool _useBusinessDays = false;
  int? _selectedPropertyTypeId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.property?.name ?? '');
    _addressController = TextEditingController(text: widget.property?.address ?? '');
    _cityController = TextEditingController(text: widget.property?.city ?? '');
    _countryController = TextEditingController(text: widget.property?.country ?? '');
    _phoneController = TextEditingController(text: widget.property?.phone ?? '');
    _emailController = TextEditingController(text: widget.property?.email ?? '');
    _currencyController = TextEditingController(text: widget.property?.currencyCode ?? 'SAR');
    _useBusinessDays = widget.property?.useBusinessDays ?? false;
    _selectedPropertyTypeId = widget.property?.propertyTypeId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPropertyTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار نوع التصنيف المنشأتي أولاً')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.property == null) {
        // Create Flow
        final userId = ref.read(authenticatedUserIdProvider) ?? 1;
        await ref.read(createPropertyUseCaseProvider)(
          accountId: 1, // Pre-seeded default system account ID
          propertyTypeId: _selectedPropertyTypeId!,
          name: _nameController.text,
          address: _addressController.text,
          city: _cityController.text,
          country: _countryController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          currencyCode: _currencyController.text,
          useBusinessDays: _useBusinessDays,
          userId: userId,
        );
      } else {
        // Update Flow
        final updated = widget.property!.copyWith(
          propertyTypeId: _selectedPropertyTypeId!,
          name: _nameController.text,
          address: _addressController.text,
          city: _cityController.text,
          country: _countryController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          currencyCode: _currencyController.text,
          useBusinessDays: _useBusinessDays,
        );
        final userId = ref.read(authenticatedUserIdProvider) ?? 1;
        await ref.read(updatePropertyUseCaseProvider)(property: updated, userId: userId);
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حفظ البيانات: $e')),
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
    final typesAsync = ref.watch(propertyTypesFutureProvider);

    return AlertDialog(
      title: Text(widget.property == null ? 'إضافة منشأة عقارية جديدة (New Property)' : 'تعديل بيانات المنشأة (Edit Property)'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                typesAsync.when(
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (e, s) => Text('خطأ في تحميل التصنيفات: $e', style: const TextStyle(color: Colors.red)),
                  data: (types) {
                    if (_selectedPropertyTypeId == null && types.isNotEmpty) {
                      _selectedPropertyTypeId = types.first.id;
                    }
                    return DropdownButtonFormField<int>(
                      initialValue: _selectedPropertyTypeId != null && types.any((t) => t.id == _selectedPropertyTypeId)
                          ? _selectedPropertyTypeId
                          : (types.isNotEmpty ? types.first.id : null),
                      decoration: const InputDecoration(labelText: 'تصنيف المنشأة (Property Classification) *'),
                      items: types.map((t) {
                        return DropdownMenuItem<int>(
                          value: t.id,
                          child: Text('${t.name} - ${t.description ?? ""}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedPropertyTypeId = val;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم المنشأة/العقار (Property Name) *'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'رجاء إدخال اسم المنشأة' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(labelText: 'الدولة (Country)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'المدينة (City)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'عنوان الشارع / التفاصيل (Street Address)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'رقم الهاتف (Phone Number)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'البريد الإلكتروني (Email Address)'),
                        validator: (val) {
                          if (val == null || val.isEmpty) return null;
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(val)) return 'تنسيق البريد غير صالح';
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
                        controller: _currencyController,
                        decoration: const InputDecoration(labelText: 'الرمز المالي للعملة الأساسية (Currency Code, e.g. SAR) *'),
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 3,
                        validator: (val) => val == null || val.trim().isEmpty ? 'رمز العملة مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('دورة العمل اليوم التشغيلي (Daily Business Cycle)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        Row(
                          children: [
                            const Text('تفعيل ميزة الأيام التشغيلية', style: TextStyle(fontSize: 12)),
                            Switch(
                              value: _useBusinessDays,
                              onChanged: (val) {
                                setState(() {
                                  _useBusinessDays = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
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
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('حفظ البيانات (Save Property)'),
        )
      ],
    );
  }
}

// Property-specific Settings Management Dialog
class PropertySettingsDialog extends ConsumerStatefulWidget {
  final Property property;

  const PropertySettingsDialog({Key? key, required this.property}) : super(key: key);

  @override
  ConsumerState<PropertySettingsDialog> createState() => _PropertySettingsDialogState();
}

class _PropertySettingsDialogState extends ConsumerState<PropertySettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _keyControllers = [];
  final List<TextEditingController> _valueControllers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(getPropertySettingsUseCaseProvider)(widget.property.id!);
    for (final s in settings) {
      _keyControllers.add(TextEditingController(text: s.settingKey));
      _valueControllers.add(TextEditingController(text: s.settingValue));
    }
    if (_keyControllers.isEmpty) {
      _addSettingRow('check_in_time', '14:00');
      _addSettingRow('check_out_time', '12:00');
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _addSettingRow([String key = '', String val = '']) {
    setState(() {
      _keyControllers.add(TextEditingController(text: key));
      _valueControllers.add(TextEditingController(text: val));
    });
  }

  void _removeSettingRow(int index) {
    setState(() {
      _keyControllers[index].dispose();
      _valueControllers[index].dispose();
      _keyControllers.removeAt(index);
      _valueControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (final c in _keyControllers) {
      c.dispose();
    }
    for (final c in _valueControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final saver = ref.read(savePropertySettingUseCaseProvider);
      for (int i = 0; i < _keyControllers.length; i++) {
        final keyText = _keyControllers[i].text.trim();
        final valueText = _valueControllers[i].text.trim();
        if (keyText.isNotEmpty) {
          await saver(
            propertyId: widget.property.id!,
            key: keyText,
            value: valueText,
          );
        }
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث إعدادات المنشأة "${widget.property.name}" بنجاح.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء حفظ الإعدادات: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إعدادات المنشأة تخصيصياً: ${widget.property.name}'),
      content: SizedBox(
        width: 550,
        height: 400,
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        'الإعدادات المتقدمة (قواعد وسياسات الغرف والاستلام واليومية)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _keyControllers.length,
                        itemBuilder: (context, idx) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _keyControllers[idx],
                                    decoration: const InputDecoration(labelText: 'مفتاح التهيئة (Setting Key)'),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'الحقل مطلوب' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _valueControllers[idx],
                                    decoration: const InputDecoration(labelText: 'القيمة المحددة (Setting Value)'),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'الحقل مطلوب' : null,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _removeSettingRow(idx),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _addSettingRow(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('إضافة مفتاح تهيئة جديد (Add Parameter)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64748B),
                        foregroundColor: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('إلغاء (Cancel)'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveAll,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
          child: const Text('حفظ الإعدادات (Save Configurations)'),
        )
      ],
    );
  }
}
