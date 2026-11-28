import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';

/// An executive, 2-column modal dialog for creating and updating
/// checklist template items with clinical guidelines from Dr. Aurora.
class TemplateItemEditorDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final String? categoryKey;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const TemplateItemEditorDialog({
    super.key,
    this.item,
    this.categoryKey,
    required this.onSave,
  });

  /// Displays the [TemplateItemEditorDialog] modal dialog.
  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? item,
    String? categoryKey,
    required Future<void> Function(Map<String, dynamic> data) onSave,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => TemplateItemEditorDialog(
        item: item,
        categoryKey: categoryKey,
        onSave: onSave,
      ),
    );
  }

  @override
  State<TemplateItemEditorDialog> createState() => _TemplateItemEditorDialogState();
}

class _TemplateItemEditorDialogState extends State<TemplateItemEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _twinQtyCtrl;
  late final TextEditingController _specsCtrl;
  late final TextEditingController _safetyCtrl;
  late final TextEditingController _tipCtrl;

  late String _categoryKey;
  late bool _isWajib;
  late bool _isHospitalBag;
  bool _isSaving = false;

  static const List<Map<String, String>> _categories = [
    {'key': 'baju', 'label': '👕 Baju & Keperluan Baby'},
    {'key': 'penyusuan', 'label': '🍼 Penyusuan & Makanan'},
    {'key': 'tidur', 'label': '🛏️ Bilik Tidur & Nursery'},
    {'key': 'mandi', 'label': '🛁 Mandian & Penjagaan'},
    {'key': 'keluar', 'label': '🚗 Keluar & Travel'},
    {'key': 'beg_hospital', 'label': '🏥 Beg Hospital Ibu & Anak'},
    {'key': 'ibu', 'label': '🤱🏻 Keperluan Ibu Bersalin'},
    {'key': 'rumah', 'label': '🏡 Persediaan Rumah'},
    {'key': 'dokumen', 'label': '📑 Dokumen & Pentadbiran'},
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    final rawCat = item?['categoryKey']?.toString().trim();
    _categoryKey = (rawCat != null && rawCat.isNotEmpty)
        ? rawCat
        : ((widget.categoryKey != null && widget.categoryKey!.trim().isNotEmpty && widget.categoryKey != 'all')
            ? widget.categoryKey!.trim()
            : 'baju');

    _titleCtrl = TextEditingController(text: item?['title']?.toString() ?? '');
    _qtyCtrl = TextEditingController(text: item?['quantity']?.toString() ?? '');
    _twinQtyCtrl = TextEditingController(text: item?['twinQuantity']?.toString() ?? '');

    final drAdvice = item?['drAuroraAdvice'];
    _specsCtrl = TextEditingController(
      text: drAdvice?['specs']?.toString() ?? item?['specs']?.toString() ?? '',
    );
    _safetyCtrl = TextEditingController(
      text: drAdvice?['safety']?.toString() ?? item?['safety']?.toString() ?? '',
    );
    _tipCtrl = TextEditingController(
      text: drAdvice?['savingTip']?.toString() ?? item?['savingTip']?.toString() ?? '',
    );

    if (item != null) {
      _isWajib = item['isWajib'] == true || item['isWajib'] == 1;
      _isHospitalBag = item['isHospitalBag'] == true || item['isHospitalBag'] == 1;
    } else {
      _isWajib = true;
      _isHospitalBag = _categoryKey == 'beg_hospital';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _qtyCtrl.dispose();
    _twinQtyCtrl.dispose();
    _specsCtrl.dispose();
    _safetyCtrl.dispose();
    _tipCtrl.dispose();
    super.dispose();
  }

  String _getCategoryEmoji(String key) {
    switch (key) {
      case 'baju':
        return '👕';
      case 'penyusuan':
        return '🍼';
      case 'tidur':
        return '🛏️';
      case 'mandi':
        return '🛁';
      case 'keluar':
        return '🚗';
      case 'beg_hospital':
        return '🏥';
      case 'ibu':
        return '🤱🏻';
      case 'rumah':
        return '🏡';
      case 'dokumen':
        return '📑';
      default:
        return '📦';
    }
  }

  List<DropdownMenuItem<String>> _buildCategoryDropdownItems() {
    final knownKeys = _categories.map((c) => c['key']!).toSet();
    final items = _categories.map((cat) {
      return DropdownMenuItem<String>(
        value: cat['key'],
        child: Text(
          cat['label']!,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList();

    if (!knownKeys.contains(_categoryKey) && _categoryKey.isNotEmpty) {
      items.insert(
        0,
        DropdownMenuItem<String>(
          value: _categoryKey,
          child: Text(
            '📁 $_categoryKey',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return items;
  }

  InputDecoration _inputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(fontSize: 12.5, color: appInkMuted, fontWeight: FontWeight.w500),
      floatingLabelStyle: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 12.5, color: appInkMuted, fontWeight: FontWeight.normal),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: appSurfaceSubtle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: appBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: appBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true);
    try {
      final payload = <String, dynamic>{
        'categoryKey': _categoryKey,
        'title': _titleCtrl.text.trim(),
        'quantity': _qtyCtrl.text.trim(),
        // Empty = twin mothers see the same quantity (shared item).
        'twinQuantity': _twinQtyCtrl.text.trim(),
        'isWajib': _isWajib,
        'isHospitalBag': _isHospitalBag,
        'specs': _specsCtrl.text.trim(),
        'safety': _safetyCtrl.text.trim(),
        'savingTip': _tipCtrl.text.trim(),
      };

      await widget.onSave(payload);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    final baseTheme = Theme.of(context);
    final dialogTheme = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.copyWith(
        bodyLarge: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: appInkPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13.0,
          fontWeight: FontWeight.normal,
          color: appInkSecondary,
        ),
      ),
    );

    return PopScope(
      canPop: !_isSaving,
      child: Theme(
        data: dialogTheme,
        child: Dialog(
          backgroundColor: appSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(isEdit),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                      child: Form(
                        key: _formKey,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 600;
                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildLeftColumn(),
                                  const SizedBox(height: 20),
                                  _buildRightColumn(),
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 6, child: _buildLeftColumn()),
                                const SizedBox(width: 20),
                                Expanded(flex: 5, child: _buildRightColumn()),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: appSurfaceSubtle),
                  _buildFooterActions(isEdit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEdit) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appDangerSoft, Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: appSurfaceSubtle)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: appSurfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: appBorder),
            ),
            child: Text(
              _getCategoryEmoji(_categoryKey),
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEdit ? 'Kemaskini Item Templat' : 'Tambah Item Templat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appInkPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tetapkan spesifikasi barangan dan panduan Dr. Aurora',
                  style: TextStyle(
                    fontSize: 12,
                    color: appInkMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: appInkMuted, size: 22),
            splashRadius: 20,
            tooltip: 'Tutup',
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Maklumat Item & Kategori',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: appInkPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleCtrl,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: appInkPrimary,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Sila masukkan nama barangan';
            }
            return null;
          },
          decoration: _inputDecoration(
            labelText: 'Nama Barangan *',
            hintText: 'cth: Sarung Tangan & Stokin Bayi',
            prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF0284C7), size: 20),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _categoryKey,
          isExpanded: true,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: appInkPrimary,
          ),
          decoration: _inputDecoration(
            labelText: 'Kategori',
            prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF0284C7), size: 20),
          ),
          items: _buildCategoryDropdownItems(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _categoryKey = val;
                if (val == 'beg_hospital') {
                  _isHospitalBag = true;
                }
              });
            }
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _qtyCtrl,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: appInkPrimary,
          ),
          decoration: _inputDecoration(
            labelText: 'Cadangan Kuantiti',
            hintText: 'cth: 3-4 pasang',
            prefixIcon: Icon(Icons.format_list_numbered_rounded, color: appInkMuted, size: 20),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _twinQtyCtrl,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: appInkPrimary,
          ),
          decoration: _inputDecoration(
            labelText: 'Kuantiti untuk Kembar (pilihan)',
            hintText: 'cth: 6-8 pasang · kosongkan jika sama (barang dikongsi)',
            prefixIcon: Icon(Icons.people_outline_rounded, color: appInkMuted, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Status & Keutamaan',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: appInkSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSelectableCard(
                isActive: _isWajib,
                onTap: () => setState(() => _isWajib = !_isWajib),
                activeColor: const Color(0xFFD97706),
                activeBgColor: appWarningSoft,
                activeIcon: Icons.star_rounded,
                inactiveIcon: Icons.star_border_rounded,
                title: 'Item WAJIB',
                subtitle: 'Keperluan asas yang disyorkan',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSelectableCard(
                isActive: _isHospitalBag,
                onTap: () => setState(() => _isHospitalBag = !_isHospitalBag),
                activeColor: const Color(0xFF0284C7),
                activeBgColor: appInfoSoft,
                activeIcon: Icons.medical_services_rounded,
                inactiveIcon: Icons.medical_services_outlined,
                title: 'Beg Hospital',
                subtitle: 'Perlu dibawa semasa bersalin',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectableCard({
    required bool isActive,
    required VoidCallback onTap,
    required Color activeColor,
    required Color activeBgColor,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : appSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor : appBorder,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? activeIcon : inactiveIcon,
                  size: 18,
                  color: isActive ? activeColor : appInkMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isActive ? activeColor : appInkSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.5,
                color: isActive ? appInkSecondary : appInkMuted,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightColumn() {
    return Container(
      decoration: BoxDecoration(
        color: appDangerSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE4E6), width: 1.2),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '🩺 Panduan Klinikal Dr. Aurora',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: appInfoSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Klinikal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: appSkyText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _specsCtrl,
            maxLines: 2,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.normal,
              color: appInkSecondary,
              height: 1.35,
            ),
            decoration: _inputDecoration(
              labelText: 'Spesifikasi (Pilihan Fabrik & Saiz)',
              hintText: 'Contoh: 100% cotton organik berventilasi baik',
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _safetyCtrl,
            maxLines: 2,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.normal,
              color: appInkSecondary,
              height: 1.35,
            ),
            decoration: _inputDecoration(
              labelText: 'Keselamatan (Nasihat Pediatrik)',
              hintText: 'Contoh: Elakkan tali panjang berisiko terbelit',
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _tipCtrl,
            maxLines: 2,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.normal,
              color: appInkSecondary,
              height: 1.35,
            ),
            decoration: _inputDecoration(
              labelText: 'Tip Penjimatan (Smart Budgeting)',
              hintText: 'Contoh: Beli saiz 0-3M lebih berbanding NB',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(bool isEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: appInkMuted,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [appInkPrimary, appInkSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isEdit ? 'Kemaskini' : 'Tambah Item',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
