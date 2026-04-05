import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/gestational/gestational_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_detail_response.dart';
import 'package:klinik_aurora_portal/views/appointment/payment_details.dart';
import 'package:klinik_aurora_portal/views/appointment/rescan_appointment.dart';
import 'package:klinik_aurora_portal/views/widgets/button/copy_button.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/extension/string.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/launcher/web_launcher.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';

class AppointmentDetailsView extends StatelessWidget {
  final AppointmentDetailResponse? response;

  const AppointmentDetailsView({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final data = response?.data;
    return SingleChildScrollView(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 840),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 24, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _headerBar(context, data),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main info row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _patientSection(context, data)),
                                const SizedBox(width: 20),
                                Expanded(child: _appointmentSection(context, data)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Color(0xFFF3F4F6), height: 1),
                            const SizedBox(height: 20),
                            // Fee row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _feeSection(context, data)),
                                const SizedBox(width: 20),
                                Expanded(child: _metaSection(context, data)),
                              ],
                            ),
                            // Rating / feedback (conditional)
                            if (data?.appointmentRating != null ||
                                (data?.appointmentFeedback != null && data!.appointmentFeedback!.isNotEmpty)) ...[
                              const SizedBox(height: 20),
                              const Divider(color: Color(0xFFF3F4F6), height: 1),
                              const SizedBox(height: 20),
                              _feedbackSection(context, data),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerBar(BuildContext context, Data? data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_note_rounded, size: 18, color: Color(0xFF6B7280)),
          const SizedBox(width: 8),
          const Text('Appointment Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          if (data?.appointmentId != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
              child: Text(
                '#${data!.appointmentId!.substring(0, 8).toUpperCase()}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontFamily: 'monospace'),
              ),
            ),
          ],
          const Spacer(),
          CopyButton(
            textToCopy:
                'Appointment Details\n\n${data?.user?.userFullName}\n${data?.user?.userPhone}\n${data?.user?.userEmail}\n${data?.service?.serviceName}\n${formatToDisplayDate(data?.appointmentDatetime ?? '')}\n${formatToDisplayTime(data?.appointmentDatetime ?? '')}\n${data?.branch?.branchName ?? ''}\nCreated: ${dateConverter(data?.createdDate ?? '')}\n',
            tooltip: 'Copy Appointment Details',
          ),
          const SizedBox(width: 4),
          CloseButton(onPressed: () => context.pop()),
        ],
      ),
    );
  }

  Widget _patientSection(BuildContext context, Data? data) {
    final user = data?.user;
    final name = user?.userFullName?.titleCase() ?? '—';
    final initials = name.trim().split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Patient', Icons.person_rounded),
        const SizedBox(height: 10),
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: primary.withAlpha(30),
              child: Text(
                initials,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  if (user?.userPhone != null) _subtleText(user!.userPhone!),
                  if (user?.userEmail != null) _subtleText(user!.userEmail!),
                  if (notNullOrEmptyString(user?.userNric)) _subtleText('NRIC: ${user!.userNric}'),
                ],
              ),
            ),
          ],
        ),
        if (notNullOrEmptyString(data?.appointmentNote)) ...[
          const SizedBox(height: 14),
          _fieldLabel('Note'),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: AppSelectableText(
              data!.appointmentNote!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
        ],
        if (data?.service?.dueDateToggle == 1) ...[
          const SizedBox(height: 14),
          _fieldLabel('Estimated Due Date (EDD)'),
          const SizedBox(height: 4),
          _valueText(dateConverter(data?.customerDueDate, format: 'dd-MM-yyyy') ?? '—'),
          if (notNullOrEmptyString(data?.service?.eddRequired)) ...[
            const SizedBox(height: 8),
            _fieldLabel('Gestational Age at Appointment'),
            const SizedBox(height: 4),
            _valueText(
              calculateGestationalAge(
                    edd: data?.customerDueDate ?? '',
                    appointmentDate: data?.appointmentDatetime ?? '',
                  ) ??
                  '—',
            ),
          ],
        ],
      ],
    );
  }

  Widget _appointmentSection(BuildContext context, Data? data) {
    final statusCode = data?.appointmentStatus ?? 0;
    final statusEntry = appointmentStatus.firstWhere(
      (e) => statusCode.toString() == e.key,
      orElse: () => DropdownAttribute('0', 'Unknown'),
    );
    final statusColor = appointmentStatusColors[statusCode] ?? Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Appointment', Icons.event_note_rounded),
        const SizedBox(height: 10),
        // Date & Time chip
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: secondaryColor.withAlpha(60)),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_rounded, size: 18, color: secondaryColor),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatToDisplayDate(data?.appointmentDatetime ?? ''),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827)),
                  ),
                  Text(
                    formatToDisplayTime(data?.appointmentDatetime ?? ''),
                    style: const TextStyle(fontSize: 13, color: secondaryColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _fieldLabel('Branch'),
        const SizedBox(height: 4),
        _valueText(data?.branch?.branchName ?? '—'),
        const SizedBox(height: 12),
        // Service row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Service'),
                  const SizedBox(height: 4),
                  _valueText(data?.service?.serviceName ?? '—'),
                  if (data?.service?.servicePrice != null) _subtleText('RM ${data!.service!.servicePrice}'),
                ],
              ),
            ),
            // Rescan button (for screening services)
            if (data?.service?.serviceName?.toLowerCase().contains('screening') == true)
              TextButton.icon(
                onPressed: () {
                  showLoading();
                  ServiceBranchController.rescanServiceBranchId(context, branchId: data?.branch?.branchId).then((
                    value,
                  ) {
                    dismissLoading();
                    showDialog(
                      context: context,
                      builder: (_) => RescanAppointment(
                        appointment: AppointmentDetailResponse(data: data),
                        serviceBranchId: value.data?.serviceBranchId ?? '',
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Rescan', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _fieldLabel('Status'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                statusEntry.name,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor),
              ),
            ],
          ),
        ),
        if (notNullOrEmptyString(data?.appointmentAttachmentUrl)) ...[
          const SizedBox(height: 14),
          _fieldLabel('Attachment'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => launchWebUrl(data?.appointmentAttachmentUrl ?? '', webOnlyWindowName: '_blank'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: secondaryColor.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file_rounded, size: 15, color: secondaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data?.appointmentAttachmentUrl ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: secondaryColor,
                        decoration: TextDecoration.underline,
                        decorationColor: secondaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.open_in_new_rounded, size: 12, color: secondaryColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.info_outline_rounded, size: 11, color: Color(0xFF9CA3AF)),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Documents are stored for 6 months to 1 year and may be deleted thereafter. Please save your own copy.',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF), height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _feeSection(BuildContext context, Data? data) {
    final price = double.tryParse(data?.service?.servicePrice ?? '');
    final bookingFee = double.tryParse(data?.service?.serviceBookingFee ?? '');
    final isCompleted = data?.appointmentStatus == 5;
    final isPaid = isCompleted || isBookingFeePaid(data?.appointmentNote, payments: data?.payment);

    // Completed = fully paid at clinic → remaining balance is RM 0.00
    final balance = isCompleted
        ? (price != null ? 0.0 : null)
        : (price != null && bookingFee != null)
        ? (isPaid ? price - bookingFee : price)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Fees', Icons.receipt_long_outlined),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _feeCard(
                label: 'Service Price',
                value: price != null ? 'RM ${price.toStringAsFixed(2)}' : '—',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _feeCard(
                label: 'Booking Fee',
                value: bookingFee != null ? 'RM ${bookingFee.toStringAsFixed(2)}' : '—',
                icon: isPaid ? Icons.check_circle_outline_rounded : Icons.payments_outlined,
                color: isPaid ? const Color(0xFF15803D) : const Color(0xFF0369A1),
                badge: showPaymentStatus(context, isPaid ? 1 : 0),
              ),
            ),
          ],
        ),
        if (balance != null) ...[
          const SizedBox(height: 10),
          _feeCard(
            label: isCompleted ? 'Remaining Balance (Fully Paid)' : 'Remaining Balance',
            value: 'RM ${balance.toStringAsFixed(2)}',
            icon: isCompleted || (isPaid && balance == 0)
                ? Icons.check_circle_outline_rounded
                : Icons.account_balance_wallet_outlined,
            color: isCompleted || (isPaid && balance == 0) ? const Color(0xFF15803D) : const Color(0xFFC2410C),
            fullWidth: true,
          ),
        ],
      ],
    );
  }

  Widget _feeCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    Widget? badge,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                    ),
                    if (badge != null) ...[const SizedBox(width: 6), badge],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaSection(BuildContext context, Data? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Record Info', Icons.info_outline_rounded),
        const SizedBox(height: 10),
        _metaRow(Icons.add_circle_outline, 'Created', dateConverter(data?.createdDate) ?? '—'),
        const SizedBox(height: 8),
        _metaRow(Icons.edit_outlined, 'Last Updated', dateConverter(data?.modifiedDate) ?? '—'),
        if (data?.appointmentId != null) ...[
          const SizedBox(height: 8),
          _metaRow(Icons.tag_rounded, 'Appointment ID', data!.appointmentId!.toUpperCase()),
        ],
      ],
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)),
              ),
              Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _feedbackSection(BuildContext context, Data? data) {
    final rating = int.tryParse(data?.appointmentRating ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Patient Feedback', Icons.star_outline_rounded),
        const SizedBox(height: 10),
        if (rating != null)
          Row(
            children: [
              _fieldLabel('Rating'),
              const SizedBox(width: 12),
              ...List.generate(
                5,
                (i) => Icon(
                  i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 18,
                  color: i < rating ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$rating/5',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B)),
              ),
            ],
          ),
        if (data?.appointmentFeedback != null && data!.appointmentFeedback!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _fieldLabel('Comments'),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: AppSelectableText(
              data.appointmentFeedback!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
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
          text.toUpperCase(),
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

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
    );
  }

  Widget _valueText(String text) {
    return AppSelectableText(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
    );
  }

  Widget _subtleText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
    );
  }
}
