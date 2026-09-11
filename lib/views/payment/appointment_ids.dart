import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_controller.dart';
import 'package:klinik_aurora_portal/models/payment/payment_success_response.dart';
import 'package:klinik_aurora_portal/views/appointment/appointment_detail_view.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentIds extends StatefulWidget {
  final PaymentSuccessResponse? response;
  const AppointmentIds({super.key, required this.response});

  @override
  State<AppointmentIds> createState() => _AppointmentIdsState();
}

class _AppointmentIdsState extends State<AppointmentIds> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTab = 0; // 0 = Needs Rescue (unrecovered), 1 = All Attempts

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isFailed => widget.response?.filters?.status == 'failed';

  List<PaymentAppointmentItem> _getFilteredItems() {
    var items = widget.response?.items ?? [];
    if (_isFailed && _selectedTab == 0) {
      items = items.where((item) => item.isRecovered != true).toList();
    }
    if (_searchQuery.trim().isEmpty) return items;
    final q = _searchQuery.toLowerCase().trim();
    return items.where((item) {
      final name = (item.patientName ?? '').toLowerCase();
      final phone = (item.patientPhone ?? '').toLowerCase();
      final service = (item.serviceName ?? '').toLowerCase();
      final branch = (item.branchName ?? '').toLowerCase();
      final id = (item.appointmentId ?? '').toLowerCase();
      return name.contains(q) || phone.contains(q) || service.contains(q) || branch.contains(q) || id.contains(q);
    }).toList();
  }

  List<String> _getFilteredIds() {
    final ids = widget.response?.data ?? [];
    if (_searchQuery.trim().isEmpty) return ids;
    final q = _searchQuery.toLowerCase().trim();
    return ids.where((id) => id.toLowerCase().contains(q)).toList();
  }

  Future<void> _launchWhatsApp(PaymentAppointmentItem item) async {
    String phone = item.patientPhone ?? '';
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '60${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('60')) {
      cleanPhone = '60$cleanPhone';
    }

    final patientName = item.patientName ?? 'Customer';
    final service = item.serviceName ?? 'appointment';
    final branch = item.branchName ?? 'Klinik Aurora';
    final dt = item.appointmentDatetime ?? '';

    final message =
        "Hi $patientName, this is $branch. We noticed an incomplete payment for your $service appointment scheduled for $dt. Would you like us to assist you with completing your booking?";
    final url = "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}";
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
    }
  }

  void _openAppointmentDetails(String? appointmentId) {
    if (appointmentId == null || appointmentId.isEmpty) return;
    showLoading();
    AppointmentController.detail(context, appointmentId: appointmentId).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AppointmentDetailsView(response: value.data),
        );
      } else {
        showDialogError(context, value.message ?? 'Failed to load details');
      }
    }).catchError((e) {
      dismissLoading();
      showDialogError(context, e.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final allItems = widget.response?.items ?? [];
    final unrecoveredTotal = allItems.where((i) => i.isRecovered != true).length;
    final totalCountAll = allItems.length;

    final hasItems = allItems.isNotEmpty;
    final filteredItems = hasItems ? _getFilteredItems() : <PaymentAppointmentItem>[];
    final filteredIds = !hasItems ? _getFilteredIds() : <String>[];
    final totalCount = hasItems ? filteredItems.length : filteredIds.length;

    final primaryAccent = _isFailed ? const Color(0xFFEF4444) : const Color(0xFF059669);
    final lightBg = _isFailed ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: math.min(680, MediaQuery.of(context).size.width * 0.94),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 24, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: lightBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isFailed ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                      color: primaryAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isFailed ? 'Incomplete / Failed Payments' : 'Successful Payments',
                          style: AppTypography.displayMedium(context).copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.response?.branchName ?? 'All Branches'} • ${widget.response?.filters?.date ?? ''}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  if (_isFailed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: unrecoveredTotal > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: unrecoveredTotal > 0 ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                        ),
                      ),
                      child: Text(
                        unrecoveredTotal > 0 ? '$unrecoveredTotal needs rescue' : 'All recovered',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: unrecoveredTotal > 0 ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: lightBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryAccent.withAlpha(60)),
                      ),
                      child: Text(
                        '$totalCount total',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryAccent,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF9CA3AF)),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    hintText: 'Search by patient name, phone, service, or ID...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF9CA3AF)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

            if (_isFailed && hasItems) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? const Color(0xFFFEE2E2) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedTab == 0 ? const Color(0xFFFCA5A5) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: _selectedTab == 0 ? const Color(0xFFDC2626) : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Needs Rescue ($unrecoveredTotal)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _selectedTab == 0 ? const Color(0xFFDC2626) : const Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? const Color(0xFFEFF6FF) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedTab == 1 ? const Color(0xFFBFDBFE) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.list_alt_rounded,
                              size: 14,
                              color: _selectedTab == 1 ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'All Attempts ($totalCountAll)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _selectedTab == 1 ? const Color(0xFF2563EB) : const Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Content List
            Flexible(
              child: totalCount == 0
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty ? 'No matches for "$_searchQuery"' : 'No records found',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    )
                  : hasItems
                      ? ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredItems.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return _buildItemCard(item, primaryAccent);
                          },
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredIds.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final id = filteredIds[index];
                            return CardContainer(
                              ListTile(
                                onTap: () => _openAppointmentDetails(id),
                                title: Text(id, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA3AF)),
                              ),
                            );
                          },
                        ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4B5563),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(PaymentAppointmentItem item, Color accentColor) {
    final hasPhone = notNullOrEmptyString(item.patientPhone);
    final amountStr = item.paymentAmount != null ? 'RM ${item.paymentAmount}' : '—';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openAppointmentDetails(item.appointmentId),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.patientName ?? 'N/A',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 2),
                          if (hasPhone)
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF6B7280)),
                                const SizedBox(width: 4),
                                Text(item.patientPhone!, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        amountStr,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 13, color: Color(0xFF2563EB)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        item.serviceName ?? 'Service',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (notNullOrEmptyString(item.appointmentDatetime)) ...[
                      const Icon(Icons.event_outlined, size: 13, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Text(
                        item.appointmentDatetime!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ],
                ),
                if (_isFailed) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (item.isRecovered == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF15803D)),
                              SizedBox(width: 4),
                              Text(
                                'Recovered (Paid)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFDC2626)),
                              SizedBox(width: 4),
                              Text(
                                'Needs Rescue',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.isRecovered != true && hasPhone) ...[
                            OutlinedButton.icon(
                              onPressed: () => _launchWhatsApp(item),
                              icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 13, color: Color(0xFF25D366)),
                              label: const Text('Rescue via WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF16A34A),
                                side: const BorderSide(color: Color(0xFF86EFAC)),
                                backgroundColor: const Color(0xFFF0FDF4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          TextButton(
                            onPressed: () => _openAppointmentDetails(item.appointmentId),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: const Size(0, 32),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                SizedBox(width: 2),
                                Icon(Icons.chevron_right_rounded, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

