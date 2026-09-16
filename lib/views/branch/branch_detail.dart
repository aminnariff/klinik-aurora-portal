import "dart:math" as math;

import "package:calendar_date_picker2/calendar_date_picker2.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:klinik_aurora_portal/config/constants.dart";
import "package:klinik_aurora_portal/controllers/api_response_controller.dart";
import "package:klinik_aurora_portal/controllers/branch/branch_controller.dart";
import "package:klinik_aurora_portal/models/branch/branch_all_response.dart";
import "package:klinik_aurora_portal/models/branch/create_branch_request.dart";
import "package:klinik_aurora_portal/models/branch/update_branch_request.dart";
import "package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart";
import "package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart";
import "package:klinik_aurora_portal/views/widgets/global/global.dart";
import "package:klinik_aurora_portal/views/widgets/input_field/app_image_field.dart";
import "package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart";
import "package:klinik_aurora_portal/views/widgets/size.dart";
import "package:provider/provider.dart";

class BranchDetail extends StatefulWidget {
  final Data? branch;
  final String type;
  const BranchDetail({super.key, this.branch, required this.type});

  @override
  State<BranchDetail> createState() => _BranchDetailState();
}

class _BranchDetailState extends State<BranchDetail> {
  final TextEditingController _branchName = TextEditingController();
  final TextEditingController _branchCode = TextEditingController();
  final TextEditingController _branchPhone = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _postcode = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _launchDate = TextEditingController();
  final TextEditingController _openingHours = TextEditingController();
  final TextEditingController _closingHours = TextEditingController();
  final ValueNotifier<bool> _is24Hours = ValueNotifier(false);
  final ValueNotifier<bool> _branchStatus = ValueNotifier(true);

  late final InputFieldAttribute _branchImage;

  String? _branchNameError;
  String? _branchCodeError;
  String? _branchPhoneError;
  String? _addressError;
  String? _postcodeError;
  String? _cityError;
  String? _stateError;
  String? _launchDateError;
  String? _hoursError;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _branchImage = InputFieldAttribute(
      controller: TextEditingController(),
      labelText: "Branch Image",
      hintText: "https://... or upload photo",
    );

    if (widget.type == "update") {
      _branchName.text = widget.branch?.branchName ?? "";
      _branchCode.text = widget.branch?.branchCode ?? "";
      _branchPhone.text = widget.branch?.phoneNumber ?? "";
      _address.text = widget.branch?.address ?? "";
      _postcode.text = widget.branch?.postcode?.toString() ?? "";
      _city.text = widget.branch?.city ?? "";
      _state.text = widget.branch?.state ?? "";
      _branchStatus.value = widget.branch?.branchStatus == 1;
      _is24Hours.value = widget.branch?.is24Hours == true;
      _openingHours.text = widget.branch?.branchOpeningHours ?? "";
      _closingHours.text = widget.branch?.branchClosingHours ?? "";
      _launchDate.text = dateConverter(widget.branch?.branchLaunchDate, format: "dd-MM-yyyy") ?? "";
      _branchImage.controller.text = widget.branch?.branchImage ?? "";
    } else {
      _branchStatus.value = true;
      _is24Hours.value = false;
    }
  }

  @override
  void dispose() {
    _branchName.dispose();
    _branchCode.dispose();
    _branchPhone.dispose();
    _address.dispose();
    _postcode.dispose();
    _city.dispose();
    _state.dispose();
    _launchDate.dispose();
    _openingHours.dispose();
    _closingHours.dispose();
    _branchImage.controller.dispose();
    _is24Hours.dispose();
    _branchStatus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height - (isMobile ? 32 : 64);
    final maxW = math.min(880.0, MediaQuery.of(context).size.width - (isMobile ? 16 : 32));

    return Center(
      child: Container(
        width: maxW,
        constraints: BoxConstraints(
          maxWidth: maxW,
          maxHeight: maxH,
        ),
        margin: EdgeInsets.all(isMobile ? 8 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                if (widget.type == "update") _buildQuickStats(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16 : 22),
                    child: _buildFormContent(),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isCreate = widget.type == "create";
    final title = isCreate
        ? "New Clinic Branch"
        : (_branchName.text.isNotEmpty ? _branchName.text : (widget.branch?.branchName ?? "Branch Details"));
    final code = _branchCode.text.isNotEmpty ? _branchCode.text : widget.branch?.branchCode;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.storefront_rounded, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (code != null && code.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          code.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                            fontFamily: "monospace",
                          ),
                        ),
                      ),
                    ],
                    if (!isCreate) ...[
                      const SizedBox(width: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: _branchStatus,
                        builder: (context, active, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: active ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                              ),
                            ),
                            child: Text(
                              active ? "Active" : "Inactive",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: active ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isCreate
                      ? "Set up a new clinic location with complete operating hours & details"
                      : "Manage branch profile, physical location and operational schedules",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
            splashRadius: 18,
            onPressed: () => context.pop(),
            tooltip: "Close",
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final hours = _is24Hours.value
        ? "24 Hours"
        : (_openingHours.text.isNotEmpty && _closingHours.text.isNotEmpty
            ? "${_openingHours.text} - ${_closingHours.text}"
            : "Standard Hours");
    final location = _city.text.isNotEmpty || _state.text.isNotEmpty
        ? "${_city.text.isNotEmpty ? _city.text : "—"}, ${_state.text.isNotEmpty ? _state.text : "—"}"
        : "—";
    final launch = _launchDate.text.isNotEmpty ? _launchDate.text : "—";
    final phone = _branchPhone.text.isNotEmpty ? _branchPhone.text : "—";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(child: _statCard("Location", location, Icons.location_on_outlined, const Color(0xFF0F766E))),
          const SizedBox(width: 10),
          Expanded(child: _statCard("Schedule", hours, Icons.access_time_rounded, const Color(0xFF0284C7))),
          const SizedBox(width: 10),
          Expanded(child: _statCard("Launch Date", launch, Icons.calendar_today_outlined, const Color(0xFF7C3AED))),
          if (!isMobile) ...[
            const SizedBox(width: 10),
            Expanded(child: _statCard("Contact", phone, Icons.phone_outlined, const Color(0xFF475569))),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accentColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: const Color(0xFF0D9488),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 14, color: const Color(0xFF0F766E)),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent() {
    final leftCol = [
      _sectionLabel("Basic Information", Icons.business_outlined),
      const SizedBox(height: 12),
      _buildTextField(
        label: "Branch Name *",
        controller: _branchName,
        errorText: _branchNameError,
        hintText: "e.g. Klinik Aurora Petaling Jaya",
        onChanged: (_) {
          if (_branchNameError != null) setState(() => _branchNameError = null);
        },
      ),
      const SizedBox(height: 12),
      _buildTextField(
        label: "Branch Code *",
        controller: _branchCode,
        errorText: _branchCodeError,
        hintText: "e.g. AUR-PJ01",
        onChanged: (_) {
          if (_branchCodeError != null) setState(() => _branchCodeError = null);
        },
      ),
      const SizedBox(height: 12),
      _buildTextField(
        label: "Phone Number *",
        controller: _branchPhone,
        errorText: _branchPhoneError,
        hintText: "e.g. 03-78901234 or 0123456789",
        isNumber: true,
        onChanged: (_) {
          if (_branchPhoneError != null) setState(() => _branchPhoneError = null);
        },
      ),
      const SizedBox(height: 22),
      _sectionLabel("Location", Icons.location_on_outlined),
      const SizedBox(height: 12),
      _buildTextField(
        label: "Street Address *",
        controller: _address,
        errorText: _addressError,
        hintText: "e.g. No. 12, Jalan SS21/39, Damansara Utama",
        onChanged: (_) {
          if (_addressError != null) setState(() => _addressError = null);
        },
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Flexible(
            flex: 2,
            child: _buildTextField(
              label: "Postal Code *",
              controller: _postcode,
              errorText: _postcodeError,
              hintText: "47400",
              isNumber: true,
              maxCharacters: 5,
              onChanged: (_) {
                if (_postcodeError != null) setState(() => _postcodeError = null);
              },
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: _buildTextField(
              label: "City *",
              controller: _city,
              errorText: _cityError,
              hintText: "Petaling Jaya",
              onChanged: (_) {
                if (_cityError != null) setState(() => _cityError = null);
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildStateDropdown(),
    ];

    final rightCol = [
      _sectionLabel("Branch Photo", Icons.image_outlined),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: AppImageField(
          field: _branchImage,
          folder: "branch",
          previewHeight: 130,
          previewWidth: double.infinity,
        ),
      ),
      const SizedBox(height: 22),
      _sectionLabel("Operating Schedule", Icons.schedule_outlined),
      const SizedBox(height: 12),
      _buildDatePickerField(),
      const SizedBox(height: 12),
      _build24HoursCard(),
      ValueListenableBuilder<bool>(
        valueListenable: _is24Hours,
        builder: (context, is24, _) {
          if (is24) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTimePickerField(
                        label: "Opening Time *",
                        timeText: _openingHours.text,
                        onTap: () => _pickTime(isOpening: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTimePickerField(
                        label: "Closing Time *",
                        timeText: _closingHours.text,
                        onTap: () => _pickTime(isOpening: false),
                      ),
                    ),
                  ],
                ),
                if (_hoursError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _hoursError!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      if (widget.type == "update") ...[
        const SizedBox(height: 18),
        _buildBranchStatusCard(),
      ],
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...leftCol,
          const SizedBox(height: 24),
          ...rightCol,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: leftCol,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rightCol,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? errorText,
    String? hintText,
    bool isNumber = false,
    int? maxCharacters,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 42,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
              width: errorText != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            maxLength: maxCharacters,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              counterText: "",
              hintText: hintText,
              hintStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 3),
          Text(
            errorText,
            style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _buildStateDropdown() {
    final selectedStateItem = _state.text.isNotEmpty && states.any((s) => s.key == _state.text)
        ? states.firstWhere((s) => s.key == _state.text)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "State *",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _stateError != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
              width: _stateError != null ? 1.5 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<DropdownAttribute>(
              isExpanded: true,
              value: selectedStateItem,
              hint: const Text(
                "Select State",
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF94A3B8)),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              onChanged: (DropdownAttribute? selected) {
                if (selected != null) {
                  setState(() {
                    _state.text = selected.key;
                    _stateError = null;
                  });
                }
              },
              items: states.map((DropdownAttribute s) {
                return DropdownMenuItem<DropdownAttribute>(
                  value: s,
                  child: Text(
                    s.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (_stateError != null) ...[
          const SizedBox(height: 3),
          Text(
            _stateError!,
            style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _buildDatePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Launch Date *",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: () async {
            final results = await showCalendarDatePicker2Dialog(
              context: context,
              barrierDismissible: true,
              dialogBackgroundColor: Colors.white,
              config: CalendarDatePicker2WithActionButtonsConfig(
                calendarViewMode: CalendarDatePicker2Mode.day,
              ),
              dialogSize: Size(
                isMobile ? (MediaQuery.of(context).size.width * 0.88) : 420,
                380,
              ),
              borderRadius: BorderRadius.circular(16),
            );
            if (results != null && results.isNotEmpty && results.first != null) {
              final formatted = dateConverter("${results.first}", format: "dd-MM-yyyy") ?? "";
              setState(() {
                _launchDate.text = formatted;
                _launchDateError = null;
              });
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _launchDateError != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                width: _launchDateError != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _launchDate.text.isNotEmpty ? _launchDate.text : "Select Launch Date",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _launchDate.text.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                      color: _launchDate.text.isNotEmpty ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
        if (_launchDateError != null) ...[
          const SizedBox(height: 3),
          Text(
            _launchDateError!,
            style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _buildTimePickerField({
    required String label,
    required String timeText,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hoursError != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                width: _hoursError != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    timeText.isNotEmpty ? timeText : "--:--",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: timeText.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                      color: timeText.isNotEmpty ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _build24HoursCard() {
    return ValueListenableBuilder<bool>(
      valueListenable: _is24Hours,
      builder: (context, is24, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: is24 ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: is24 ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: is24 ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.all_inclusive_rounded,
                  size: 16,
                  color: is24 ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Open 24 Hours",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      is24 ? "Clinic operates 24 hours daily" : "Specify custom opening & closing hours",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: is24,
                onChanged: (val) {
                  _is24Hours.value = val;
                  if (val) {
                    _hoursError = null;
                  }
                  setState(() {});
                },
                activeThumbColor: const Color(0xFF16A34A),
                activeTrackColor: const Color(0xFFBBF7D0),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBranchStatusCard() {
    return ValueListenableBuilder<bool>(
      valueListenable: _branchStatus,
      builder: (context, active, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  active ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                  size: 16,
                  color: active ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      active ? "Branch Operational (Active)" : "Branch Suspended (Inactive)",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? const Color(0xFF15803D) : const Color(0xFF991B1B),
                      ),
                    ),
                    Text(
                      active
                          ? "Branch is visible in appointment bookings and portal directory"
                          : "Branch is hidden from new bookings and patient listings",
                      style: TextStyle(
                        fontSize: 11,
                        color: active ? const Color(0xFF166534) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: active,
                onChanged: (val) {
                  _branchStatus.value = val;
                  setState(() {});
                },
                activeThumbColor: const Color(0xFF16A34A),
                activeTrackColor: const Color(0xFFBBF7D0),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickTime({required bool isOpening}) async {
    final initial = isOpening
        ? (_parseTimeOfDay(_openingHours.text) ?? const TimeOfDay(hour: 9, minute: 0))
        : (_parseTimeOfDay(_closingHours.text) ?? const TimeOfDay(hour: 22, minute: 0));

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox(),
      ),
    );

    if (picked != null) {
      final formatted = "${_twoDigits(picked.hour)}:${_twoDigits(picked.minute)}";
      setState(() {
        if (isOpening) {
          _openingHours.text = formatted;
        } else {
          _closingHours.text = formatted;
        }
        _hoursError = null;
      });
    }
  }

  TimeOfDay? _parseTimeOfDay(String timeStr) {
    if (timeStr.isEmpty || !timeStr.contains(":")) return null;
    try {
      final parts = timeStr.split(":");
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  String _twoDigits(int n) => n >= 10 ? "$n" : "0$n";

  Widget _buildFooter() {
    final isCreate = widget.type == "create";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _isSaving ? null : () => context.pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Cancel", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    isCreate ? "Create Branch" : "Save Changes",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _branchNameError = null;
      _branchCodeError = null;
      _branchPhoneError = null;
      _addressError = null;
      _postcodeError = null;
      _cityError = null;
      _stateError = null;
      _launchDateError = null;
      _hoursError = null;
    });

    bool isValid = true;
    if (_branchName.text.trim().isEmpty) {
      _branchNameError = "Branch name is required";
      isValid = false;
    }
    if (_branchCode.text.trim().isEmpty) {
      _branchCodeError = "Branch code is required";
      isValid = false;
    }
    if (_branchPhone.text.trim().isEmpty) {
      _branchPhoneError = "Phone number is required";
      isValid = false;
    }
    if (_address.text.trim().isEmpty) {
      _addressError = "Address is required";
      isValid = false;
    }
    if (_postcode.text.trim().isEmpty) {
      _postcodeError = "Postcode is required";
      isValid = false;
    }
    if (_city.text.trim().isEmpty) {
      _cityError = "City is required";
      isValid = false;
    }
    if (_state.text.trim().isEmpty) {
      _stateError = "State is required";
      isValid = false;
    }
    if (_launchDate.text.trim().isEmpty) {
      _launchDateError = "Launch date is required";
      isValid = false;
    }
    if (!_is24Hours.value) {
      if (_openingHours.text.trim().isEmpty || _closingHours.text.trim().isEmpty) {
        _hoursError = "Opening and closing hours are required";
        isValid = false;
      }
    }

    if (!isValid) {
      setState(() {});
      showDialogError(context, "Please complete all required fields.");
      return;
    }

    setState(() => _isSaving = true);

    final imageVal = _branchImage.controller.text.trim();
    final finalBranchImage = imageVal.isEmpty ? null : imageVal;
    final convertedLaunchDate = convertStringToDate(_launchDate.text.trim());

    try {
      if (widget.type == "create") {
        final res = await BranchController.create(
          CreateBranchRequest(
            branchName: _branchName.text.trim(),
            branchCode: _branchCode.text.trim(),
            phoneNumber: _branchPhone.text.trim(),
            address: _address.text.trim(),
            city: _city.text.trim(),
            postcode: _postcode.text.trim(),
            state: _state.text.trim(),
            is24Hours: _is24Hours.value ? 1 : 0,
            branchOpeningHours: _is24Hours.value ? "00:00" : _openingHours.text.trim(),
            branchClosingHours: _is24Hours.value ? "23:59" : _closingHours.text.trim(),
            branchLaunchDate: convertedLaunchDate,
            branchImageUrl: finalBranchImage,
          ),
        );

        if (responseCode(res.code)) {
          final refreshRes = await BranchController.getAll(context, 1, pageSize);
          if (mounted) {
            if (responseCode(refreshRes.code)) {
              context.read<BranchController>().branchAllResponse = refreshRes;
            }
            context.pop();
            showDialogSuccess(context, 'Successfully created branch "${_branchName.text.trim()}"');
          }
        } else {
          if (mounted) {
            showDialogError(context, res.message ?? res.data?.message ?? "Failed to create branch");
          }
        }
      } else {
        final res = await BranchController.update(
          UpdateBranchRequest(
            branchId: widget.branch?.branchId ?? "",
            branchCode: _branchCode.text.trim(),
            branchName: _branchName.text.trim(),
            phoneNumber: _branchPhone.text.trim(),
            address: _address.text.trim(),
            city: _city.text.trim(),
            postcode: _postcode.text.trim(),
            state: _state.text.trim(),
            is24Hours: _is24Hours.value ? 1 : 0,
            branchOpeningHours: _is24Hours.value ? "00:00" : _openingHours.text.trim(),
            branchClosingHours: _is24Hours.value ? "23:59" : _closingHours.text.trim(),
            branchLaunchDate: convertedLaunchDate,
            branchImageUrl: finalBranchImage,
            branchStatus: _branchStatus.value ? 1 : 0,
          ),
        );

        if (responseCode(res.code)) {
          final refreshRes = await BranchController.getAll(context, 1, pageSize);
          if (mounted) {
            if (responseCode(refreshRes.code)) {
              context.read<BranchController>().branchAllResponse = refreshRes;
            }
            context.pop();
            showDialogSuccess(context, 'Successfully updated "${_branchName.text.trim()}"');
          }
        } else {
          if (mounted) {
            showDialogError(context, res.message ?? res.data?.message ?? "Failed to update branch");
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showDialogError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
