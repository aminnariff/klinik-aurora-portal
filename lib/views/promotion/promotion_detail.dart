import 'dart:async';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/promotion/promotion_controller.dart';
import 'package:klinik_aurora_portal/models/promotion/promotion_all_response.dart';
import 'package:klinik_aurora_portal/models/promotion/update_promotion_request.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/checkbox/checkbox.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/app_multi_image_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/read_only/read_only.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:provider/provider.dart';

class PromotionDetail extends StatefulWidget {
  final Data promotion;
  const PromotionDetail({super.key, required this.promotion});

  @override
  State<PromotionDetail> createState() => _PromotionDetailState();
}

class _PromotionDetailState extends State<PromotionDetail> {
  ValueNotifier<bool> isNoRecords = ValueNotifier<bool>(false);
  final TextEditingController _promotionName = TextEditingController();
  final TextEditingController _promotionDescription = TextEditingController();
  final TextEditingController _promotionTnc = TextEditingController();
  final TextEditingController _startDate = TextEditingController();
  final TextEditingController _endDate = TextEditingController();
  final ValueNotifier<bool> _showOnStart = ValueNotifier(false);
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  StreamController<DateTime> validateRebuild = StreamController.broadcast();
  List<String> _imageUrls = [];
  final List<String> _initialImagePaths = [];

  @override
  void initState() {
    _promotionName.text = widget.promotion.promotionName ?? '';
    _promotionDescription.text = widget.promotion.promotionDescription ?? '';
    _promotionTnc.text = widget.promotion.promotionTnc ?? '';
    _startDate.text = dateConverter(widget.promotion.promotionStartDate, format: 'dd-MM-yyyy') ?? '';
    _endDate.text = dateConverter(widget.promotion.promotionEndDate, format: 'dd-MM-yyyy') ?? '';
    _showOnStart.value = widget.promotion.showOnStart == 1;
    for (PromotionImage item in widget.promotion.promotionImage ?? []) {
      if (item.path != null && item.path!.isNotEmpty) {
        _imageUrls.add(item.path!);
        _initialImagePaths.add(item.path!);
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return editPromotion();
  }

  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 13, color: const Color(0xFF6B7280)),
        const SizedBox(width: 5),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Row editPromotion() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                CardContainer(
                  IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Header ──────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.campaign_rounded, size: 16, color: Color(0xFF6366F1)),
                              ),
                              const SizedBox(width: 10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Edit Promotion', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                  Text(
                                    'Update promotion content, images, and schedule',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              CloseButton(onPressed: () => context.pop()),
                            ],
                          ),
                        ),
                        // ── Body ────────────────────────────────────────────
                        Padding(
                          padding: EdgeInsets.all(screenPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                spacing: screenPadding,
                                runSpacing: screenPaddingVertical(),
                                crossAxisAlignment: WrapCrossAlignment.start,
                                children: [
                                  // Left: Content
                                  SizedBox(
                                    width: screenWidth1728(26),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel('Promotion Content', Icons.article_outlined),
                                        const SizedBox(height: 12),
                                        InputField(
                                          field: InputFieldAttribute(controller: _promotionName, labelText: 'Name'),
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        TextField(
                                          maxLines: null,
                                          style: Theme.of(context).textTheme.bodyMedium!.apply(),
                                          controller: _promotionDescription,
                                          decoration: appInputDecoration(context, 'Description'),
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        TextField(
                                          maxLines: null,
                                          style: Theme.of(context).textTheme.bodyMedium!.apply(),
                                          controller: _promotionTnc,
                                          decoration: appInputDecoration(context, 'Terms and Conditions'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Right: Media + Schedule
                                  SizedBox(
                                    width: screenWidth1728(30),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
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
                                        _sectionLabel('Schedule', Icons.schedule_outlined),
                                        const SizedBox(height: 12),
                                        GestureDetector(
                                          onTap: () async {
                                            var results = await showCalendarDatePicker2Dialog(
                                              context: context,
                                              config: CalendarDatePicker2WithActionButtonsConfig(
                                                currentDate: DateTime.now(),
                                              ),
                                              dialogSize: Size(screenWidth1728(60), screenHeight829(60)),
                                              borderRadius: BorderRadius.circular(15),
                                            );
                                            _startDate.text =
                                                dateConverter('${results?.first}', format: 'dd-MM-yyyy') ?? '';
                                          },
                                          child: ReadOnly(
                                            InputField(
                                              field: InputFieldAttribute(
                                                controller: _startDate,
                                                isEditable: false,
                                                labelText: 'promotionPage'.tr(gender: 'startDate'),
                                                suffixWidget: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [Icon(Icons.calendar_month)],
                                                ),
                                              ),
                                            ),
                                            isEditable: false,
                                          ),
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        GestureDetector(
                                          onTap: () async {
                                            var results = await showCalendarDatePicker2Dialog(
                                              context: context,
                                              config: CalendarDatePicker2WithActionButtonsConfig(
                                                currentDate: DateTime.now().add(const Duration(days: 1)),
                                              ),
                                              dialogSize: Size(screenWidth1728(60), screenHeight829(60)),
                                              borderRadius: BorderRadius.circular(15),
                                            );
                                            _endDate.text =
                                                dateConverter('${results?.first}', format: 'dd-MM-yyyy') ?? '';
                                          },
                                          child: ReadOnly(
                                            InputField(
                                              field: InputFieldAttribute(
                                                controller: _endDate,
                                                isEditable: false,
                                                labelText: 'promotionPage'.tr(gender: 'endDate'),
                                                suffixWidget: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [Icon(Icons.calendar_month)],
                                                ),
                                              ),
                                            ),
                                            isEditable: false,
                                          ),
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        ValueListenableBuilder<bool>(
                                          valueListenable: _showOnStart,
                                          builder: (context, shown, _) {
                                            return GestureDetector(
                                              onTap: () => _showOnStart.value = !shown,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: shown ? const Color(0xFFEEF2FF) : const Color(0xFFF9FAFB),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: shown ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    CheckBoxWidget((p0) => _showOnStart.value = !shown, value: shown),
                                                    AppPadding.horizontal(denominator: 2),
                                                    Flexible(
                                                      child: Text(
                                                        'promotionPage'.tr(gender: 'showOnStart'),
                                                        style: TextStyle(
                                                          fontWeight: shown ? FontWeight.w600 : FontWeight.normal,
                                                          color: shown ? const Color(0xFF6366F1) : null,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Button(() {
                                    if (validate()) {
                                      showLoading();
                                      PromotionController.update(
                                        context,
                                        UpdatePromotionRequest(
                                          promotionId: widget.promotion.promotionId ?? '',
                                          promotionName: _promotionName.text,
                                          promotionDescription: _promotionDescription.text,
                                          promotionTnc: _promotionTnc.text,
                                          promotionStartDate: convertStringToDate(_startDate.text),
                                          promotionEndDate: convertStringToDate(_endDate.text),
                                          showOnStart: _showOnStart.value,
                                          promotionStatus: widget.promotion.promotionStatus == 1 ? true : false,
                                        ),
                                      ).then((value) {
                                        dismissLoading();
                                        if (responseCode(value.code)) {
                                          final newImages = _imageUrls
                                              .where((url) => !_initialImagePaths.contains(url))
                                              .toList();
                                          if (newImages.isNotEmpty) {
                                            showLoading();
                                            PromotionController.uploadUrls(
                                              context,
                                              widget.promotion.promotionId!,
                                              newImages,
                                            ).then((uploadVal) {
                                              dismissLoading();
                                              if (responseCode(uploadVal.code)) {
                                                context.pop();
                                                PromotionController.getAll(context, 1, pageSize).then(
                                                  (allVal) =>
                                                      context.read<PromotionController>().promotionAllResponse =
                                                          allVal,
                                                );
                                                showDialogSuccess(context, 'Promotion updated successfully!');
                                              } else {
                                                showDialogError(
                                                  context,
                                                  uploadVal.message ??
                                                      uploadVal.data?.message ??
                                                      'ERROR : ${uploadVal.code}',
                                                );
                                              }
                                            }).catchError((e) {
                                              dismissLoading();
                                              showDialogError(context, e.toString());
                                            });
                                          } else {
                                            context.pop();
                                            PromotionController.getAll(context, 1, pageSize).then(
                                              (allVal) =>
                                                  context.read<PromotionController>().promotionAllResponse =
                                                      allVal,
                                            );
                                            showDialogSuccess(context, 'Promotion updated successfully!');
                                          }
                                        } else {
                                          showDialogError(
                                            context,
                                            value.message ?? value.data?.message ?? 'ERROR : ${value.code}',
                                          );
                                        }
                                      }).catchError((e) {
                                        dismissLoading();
                                        showDialogError(context, e.toString());
                                      });
                                    }
                                  }, actionText: 'button'.tr(gender: 'update')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool validate() {
    bool temp = true;
    if (_promotionName.text == '') {
      temp = false;
      showDialogError(context, ErrorMessage.required(field: 'Name'));
    } else if (_promotionDescription.text == '') {
      temp = false;
      showDialogError(context, ErrorMessage.required(field: 'Description'));
    }
    if (_startDate.text == '') {
      temp = false;
      showDialogError(context, ErrorMessage.required(field: 'promotionPage'.tr(gender: 'startDate')));
    } else if (_endDate.text == '') {
      temp = false;
      showDialogError(context, ErrorMessage.required(field: 'promotionPage'.tr(gender: 'endDate')));
    }
    setState(() {});
    return temp;
  }
}
