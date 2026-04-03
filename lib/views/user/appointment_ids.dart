import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_controller.dart';
import 'package:klinik_aurora_portal/models/user/user_all_response.dart';
import 'package:klinik_aurora_portal/models/user/user_appointment_response.dart';
import 'package:klinik_aurora_portal/views/appointment/appointment_detail_view.dart';
import 'package:klinik_aurora_portal/views/widgets/no_records/no_records.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class UserAppointmentIds extends StatefulWidget {
  final UserAppointmentResponse? response;
  final UserResponse? patient;
  const UserAppointmentIds({super.key, required this.response, required this.patient});

  @override
  State<UserAppointmentIds> createState() => _UserAppointmentIdsState();
}

class _UserAppointmentIdsState extends State<UserAppointmentIds> {
  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'P';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final appointments = widget.response?.data ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600, maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: secondaryColor.withOpacity(0.1),
                    child: Text(
                      _initials(widget.patient?.userFullname),
                      style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patient?.userFullname ?? 'Patient History',
                          style: AppTypography.bodyMedium(context).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Total: ${widget.response?.total ?? 0} appointment(s)',
                          style: AppTypography.bodyMedium(context).apply(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

            // Scrollable List
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: appointments.isEmpty
                    ? const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: NoRecordsWidget())
                    : Column(children: appointments.map((item) => _buildAppointmentCard(item)).toList()),
              ),
            ),

            // Footer / Bottom spacing
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Data? item) {
    if (item == null) return const SizedBox.shrink();

    // Parse date parts
    DateTime? dt;
    String day = '—';
    String month = '—';
    String time = '—';

    if (item.appointmentDatetime != null) {
      try {
        dt = DateTime.parse(item.appointmentDatetime!).add(const Duration(hours: 8)); // Local MYT
        day = DateFormat('dd').format(dt);
        month = DateFormat('MMM').format(dt).toUpperCase();
        time = DateFormat('h:mm a').format(dt);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onTapAppointment(item.appointmentId),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Calendar Block
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(color: primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        month,
                        style: TextStyle(color: primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      Text(
                        day,
                        style: TextStyle(color: primary, fontSize: 22, fontWeight: FontWeight.bold, height: 1.1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${item.appointmentId}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontFamily: 'Monospace'),
                      ),
                    ],
                  ),
                ),

                // Action Arrow
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTapAppointment(String? appointmentId) {
    if (appointmentId == null) return;

    showLoading();
    AppointmentController.detail(context, appointmentId: appointmentId).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AppointmentDetailsView(response: value.data);
          },
        );
      }
    });
  }
}
