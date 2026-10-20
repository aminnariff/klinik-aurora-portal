import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/promotion/promotion_controller.dart';
import 'package:klinik_aurora_portal/models/promotion/promotion_all_response.dart';
import 'package:klinik_aurora_portal/models/promotion/update_promotion_request.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/app_multi_image_field.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:provider/provider.dart';

class PromotionDetail extends StatefulWidget {
  final Data promotion;
  const PromotionDetail({super.key, required this.promotion});

  @override
  State<PromotionDetail> createState() => _PromotionDetailState();
}

class _PromotionDetailState extends State<PromotionDetail> {
  final TextEditingController _promotionName = TextEditingController();
  final TextEditingController _promotionDescription = TextEditingController();
  final TextEditingController _promotionTnc = TextEditingController();
  final TextEditingController _startDate = TextEditingController();
  final TextEditingController _endDate = TextEditingController();

  bool _showOnStart = false;
  bool _promotionStatus = true;
  bool _isSubmitting = false;

  String? _nameError;
  String? _descError;
  String? _startDateError;
  String? _endDateError;

  List<String> _imageUrls = [];
  final List<String> _initialImagePaths = [];

  @override
  void initState() {
    super.initState();
    _promotionName.text = widget.promotion.promotionName ?? '';
    _promotionDescription.text = widget.promotion.promotionDescription ?? '';
    _promotionTnc.text = widget.promotion.promotionTnc ?? '';
    _startDate.text = dateConverter(widget.promotion.promotionStartDate, format: 'dd-MM-yyyy') ?? '';
    _endDate.text = dateConverter(widget.promotion.promotionEndDate, format: 'dd-MM-yyyy') ?? '';
    _showOnStart = widget.promotion.showOnStart == 1;
    _promotionStatus = widget.promotion.promotionStatus == 1;

    for (PromotionImage item in widget.promotion.promotionImage ?? []) {
      if (item.path != null && item.path!.isNotEmpty) {
        _imageUrls.add(item.path!);
        _initialImagePaths.add(item.path!);
      }
    }
  }

  @override
  void dispose() {
    _promotionName.dispose();
    _promotionDescription.dispose();
    _promotionTnc.dispose();
    _startDate.dispose();
    _endDate.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _descError = null;
      _startDateError = null;
      _endDateError = null;

      if (_promotionName.text.trim().isEmpty) {
        _nameError = 'Promotion name is required';
        valid = false;
      }
      if (_promotionDescription.text.trim().isEmpty) {
        _descError = 'Description is required';
        valid = false;
      }
      if (_startDate.text.trim().isEmpty) {
        _startDateError = 'Start date is required';
        valid = false;
      }
      if (_endDate.text.trim().isEmpty) {
        _endDateError = 'End date is required';
        valid = false;
      }
    });
    return valid;
  }

  void _handleSubmit() {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);
    showLoading();

    PromotionController.update(
      context,
      UpdatePromotionRequest(
        promotionId: widget.promotion.promotionId ?? '',
        promotionName: _promotionName.text.trim(),
        promotionDescription: _promotionDescription.text.trim(),
        promotionTnc: _promotionTnc.text.trim().isEmpty ? null : _promotionTnc.text.trim(),
        promotionStartDate: convertStringToDate(_startDate.text.trim()),
        promotionEndDate: convertStringToDate(_endDate.text.trim()),
        showOnStart: _showOnStart,
        promotionStatus: _promotionStatus,
      ),
    ).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        final newImages = _imageUrls.where((url) => !_initialImagePaths.contains(url)).toList();
        if (newImages.isNotEmpty) {
          showLoading();
          PromotionController.uploadUrls(
            context,
            widget.promotion.promotionId!,
            newImages,
          ).then((uploadVal) {
            dismissLoading();
            setState(() => _isSubmitting = false);
            if (responseCode(uploadVal.code)) {
              context.pop();
              PromotionController.getAll(context, 1, pageSize).then(
                (allVal) => context.read<PromotionController>().promotionAllResponse = allVal,
              );
              showDialogSuccess(context, 'Promotion updated successfully!');
            } else {
              showDialogError(
                context,
                uploadVal.message ?? uploadVal.data?.message ?? 'ERROR : ${uploadVal.code}',
              );
            }
          }).catchError((e) {
            dismissLoading();
            setState(() => _isSubmitting = false);
            showDialogError(context, e.toString());
          });
        } else {
          setState(() => _isSubmitting = false);
          context.pop();
          PromotionController.getAll(context, 1, pageSize).then(
            (allVal) => context.read<PromotionController>().promotionAllResponse = allVal,
          );
          showDialogSuccess(context, 'Promotion updated successfully!');
        }
      } else {
        setState(() => _isSubmitting = false);
        showDialogError(
          context,
          value.message ?? value.data?.message ?? 'ERROR : ${value.code}',
        );
      }
    }).catchError((e) {
      dismissLoading();
      setState(() => _isSubmitting = false);
      showDialogError(context, e.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 20 : 32,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 780,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: isMobile ? _buildMobileLayout(context) : _buildDesktopLayout(context),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign_rounded, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Promotion',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 2),
                Text(
                  'Update promotion content, banner images, and active schedule',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
            onPressed: () => context.pop(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildDetailsColumn(context)),
        const SizedBox(width: 28),
        Expanded(child: _buildMediaScheduleColumn(context)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailsColumn(context),
        const SizedBox(height: 20),
        _buildMediaScheduleColumn(context),
      ],
    );
  }

  Widget _buildDetailsColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('PROMOTION CONTENT', Icons.article_outlined),
        const SizedBox(height: 14),
        _fieldLabel('Promotion Title', isRequired: true),
        const SizedBox(height: 6),
        _styledTextField(
          controller: _promotionName,
          hint: 'e.g. Raya Glow Treatment Special',
          errorText: _nameError,
        ),
        const SizedBox(height: 14),
        _fieldLabel('Description', isRequired: true),
        const SizedBox(height: 6),
        _styledTextField(
          controller: _promotionDescription,
          hint: 'Describe promotion offerings, highlights, or discounts...',
          maxLines: 4,
          errorText: _descError,
        ),
        const SizedBox(height: 14),
        _fieldLabel('Terms & Conditions (Optional)'),
        const SizedBox(height: 6),
        _styledTextField(
          controller: _promotionTnc,
          hint: 'Redemption terms, appointment validity, exclusions...',
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildMediaScheduleColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('BANNER IMAGES', Icons.image_outlined),
        const SizedBox(height: 12),
        AppMultiImageField(
          images: _imageUrls,
          onChanged: (updated) {
            for (final initial in List<String>.from(_initialImagePaths)) {
              if (!updated.contains(initial)) {
                _initialImagePaths.remove(initial);
                for (final img in widget.promotion.promotionImage ?? []) {
                  if (img.path == initial && img.id != null) {
                    PromotionController.remove(context, img.id!);
                    break;
                  }
                }
              }
            }
            setState(() {
              _imageUrls = updated;
            });
          },
          folder: 'promotion',
          maxImages: 3,
        ),
        const SizedBox(height: 20),
        _sectionHeader('SCHEDULE & VISIBILITY', Icons.schedule_outlined),
        const SizedBox(height: 14),
        _fieldLabel('Start Date', isRequired: true),
        const SizedBox(height: 6),
        _buildDatePickerField(
          controller: _startDate,
          hint: 'Select start date',
          errorText: _startDateError,
          isStartDate: true,
        ),
        const SizedBox(height: 14),
        _fieldLabel('End Date', isRequired: true),
        const SizedBox(height: 6),
        _buildDatePickerField(
          controller: _endDate,
          hint: 'Select end date',
          errorText: _endDateError,
          isStartDate: false,
        ),
        const SizedBox(height: 18),
        _buildShowOnStartCard(),
        const SizedBox(height: 12),
        _buildStatusToggleCard(),
      ],
    );
  }

  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String hint,
    String? errorText,
    required bool isStartDate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            DateTime? initial;
            if (controller.text.isNotEmpty) {
              try {
                initial = DateFormat('dd-MM-yyyy').parseStrict(controller.text);
              } catch (_) {}
            }
            final results = await showCalendarDatePicker2Dialog(
              context: context,
              config: CalendarDatePicker2WithActionButtonsConfig(
                currentDate: initial ?? DateTime.now(),
              ),
              dialogSize: const Size(360, 360),
              borderRadius: BorderRadius.circular(16),
            );
            if (results != null && results.isNotEmpty && results.first != null) {
              setState(() {
                controller.text = dateConverter('${results.first}', format: 'dd-MM-yyyy') ?? '';
                if (isStartDate) {
                  _startDateError = null;
                } else {
                  _endDateError = null;
                }
              });
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: errorText != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    controller.text.isNotEmpty ? controller.text : hint,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: controller.text.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                      color: controller.text.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                    splashRadius: 14,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => controller.clear()),
                  ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11)),
        ],
      ],
    );
  }

  Widget _buildShowOnStartCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _showOnStart ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _showOnStart ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star_rounded,
            size: 20,
            color: _showOnStart ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Featured on App Launch',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _showOnStart ? const Color(0xFFB45309) : const Color(0xFF334155),
                  ),
                ),
                Text(
                  'Shows full-screen popup banner when mobile app opens',
                  style: TextStyle(
                    fontSize: 11,
                    color: _showOnStart ? const Color(0xFF92400E) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _showOnStart,
            activeTrackColor: const Color(0xFFD97706),
            activeThumbColor: Colors.white,
            onChanged: (val) {
              setState(() => _showOnStart = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _promotionStatus ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _promotionStatus ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _promotionStatus ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 20,
            color: _promotionStatus ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _promotionStatus ? 'Status: Active' : 'Status: Inactive',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _promotionStatus ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                ),
                Text(
                  _promotionStatus ? 'Publicly visible to patients' : 'Hidden from promotions list',
                  style: TextStyle(
                    fontSize: 11,
                    color: _promotionStatus ? const Color(0xFF166534) : const Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _promotionStatus,
            activeTrackColor: const Color(0xFF16A34A),
            activeThumbColor: Colors.white,
            onChanged: (val) {
              setState(() => _promotionStatus = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _handleSubmit,
            icon: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_rounded, size: 18, color: Colors.white),
            label: const Text(
              'Update Promotion',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          title,
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

  Widget _fieldLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
        children: isRequired
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                ),
              ]
            : [],
      ),
    );
  }

  Widget _styledTextField({
    required TextEditingController controller,
    required String hint,
    String? errorText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: maxLines == 1 ? 42 : null,
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: errorText != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: errorText != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: primary, width: 1.5),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11)),
        ],
      ],
    );
  }
}
