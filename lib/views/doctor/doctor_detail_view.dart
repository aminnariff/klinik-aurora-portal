import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/models/doctor/doctor_branch_response.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';

class DoctorDetailView extends StatelessWidget {
  final Data doctor;
  const DoctorDetailView({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
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
                        _header(context),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding / 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppPadding.vertical(denominator: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: screenWidth1728(26),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel('Personal Information', Icons.person_outline_rounded),
                                        AppPadding.vertical(denominator: 2),
                                        _fieldLabel(context, 'Full Name'),
                                        AppSelectableText(
                                          doctor.doctorName ?? '—',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        _fieldLabel(context, 'Contact Number'),
                                        AppSelectableText(
                                          doctor.doctorPhone ?? '—',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        _fieldLabel(context, 'Branch'),
                                        AppSelectableText(
                                          doctor.branchName ?? '—',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        _fieldLabel(context, 'Status'),
                                        _statusChip(doctor.doctorStatus == 1),
                                        AppPadding.vertical(denominator: 2),
                                        _sectionLabel('Record Info', Icons.history_rounded),
                                        AppPadding.vertical(denominator: 2),
                                        _fieldLabel(context, 'Date Joined'),
                                        AppSelectableText(
                                          dateConverter(doctor.createdDate) ?? '—',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        _fieldLabel(context, 'Last Updated'),
                                        AppSelectableText(
                                          dateConverter(doctor.modifiedDate) ?? '—',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppPadding.horizontal(),
                                  SizedBox(
                                    width: screenWidth1728(30),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel('Photo', Icons.image_outlined),
                                        AppPadding.vertical(denominator: 2),
                                        if (doctor.doctorImage != null)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              '${Environment.imageUrl}${doctor.doctorImage}',
                                              height: 360,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Container(
                                                  height: 360,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(12),
                                                    color: disabledColor,
                                                  ),
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded /
                                                                (loadingProgress.expectedTotalBytes ?? 1)
                                                          : null,
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  height: 360,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(12),
                                                    color: disabledColor,
                                                  ),
                                                  child: const Center(child: Icon(Icons.error, color: errorColor)),
                                                );
                                              },
                                            ),
                                          )
                                        else
                                          Container(
                                            height: 360,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              color: disabledColor,
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.person_off_rounded, size: 48, color: Color(0xFF9CA3AF)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              AppPadding.vertical(denominator: 1 / 1.5),
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

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.person_rounded, size: 16, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 10),
          Text('PIC Details', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const Spacer(),
          CloseButton(onPressed: () => context.pop()),
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
          decoration: BoxDecoration(color: Color(0xFF6366F1), borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 13, color: Color(0xFF6B7280)),
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

  Widget _fieldLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
      ),
    );
  }

  Widget _statusChip(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: active ? Colors.green.shade700 : Colors.red.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
