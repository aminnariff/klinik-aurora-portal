import 'package:flutter/material.dart';

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
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE84C7A), width: 1.5),
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

    return PopScope(
      canPop: !_isSaving,
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
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
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                _buildFooterActions(isEdit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEdit) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF1F5), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFD1DC)),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Tetapkan spesifikasi barangan dan panduan Dr. Aurora',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
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
        const Text(
          'Maklumat Item & Kategori',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleCtrl,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Sila masukkan nama barangan';
            }
            return null;
          },
          decoration: _inputDecoration(
            labelText: 'Nama Barangan *',
            hintText: 'cth: Sarung Tangan & Stokin Bayi',
            prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFE84C7A), size: 20),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _categoryKey,
          isExpanded: true,
          decoration: _inputDecoration(
            labelText: 'Kategori',
            prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFFE84C7A), size: 20),
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
          decoration: _inputDecoration(
            labelText: 'Cadangan Kuantiti',
            hintText: 'cth: 3-4 pasang',
            prefixIcon: const Icon(Icons.format_list_numbered_rounded, color: Color(0xFF64748B), size: 20),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Status & Keutamaan',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSelectableCard(
                isActive: _isWajib,
                onTap: () => setState(() => _isWajib = !_isWajib),
                activeColor: const Color(0xFFE84C7A),
                activeBgColor: const Color(0xFFFFF0F5),
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
                activeBgColor: const Color(0xFFF0F9FF),
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
          color: isActive ? activeBgColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFFE2E8F0),
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
                  color: isActive ? activeColor : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isActive ? activeColor : const Color(0xFF334155),
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
                color: isActive ? const Color(0xFF475569) : const Color(0xFF64748B),
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
        color: const Color(0xFFFFF9FB),
        borderRadius: BorderRadius.circular(16),
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
                  '💖 Panduan Klinikal Dr. Aurora',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBE185D),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE7F3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Tips Klinikal',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9D174D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _specsCtrl,
            maxLines: 2,
            decoration: _inputDecoration(
              labelText: 'Spesifikasi (Pilihan Fabrik & Saiz)',
              hintText: 'Contoh: 100% cotton organik berventilasi baik',
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _safetyCtrl,
            maxLines: 2,
            decoration: _inputDecoration(
              labelText: 'Keselamatan (Nasihat Pediatrik)',
              hintText: 'Contoh: Elakkan tali panjang berisiko terbelit',
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _tipCtrl,
            maxLines: 2,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7E9C), Color(0xFFE84C7A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE84C7A).withValues(alpha: 0.3),
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
