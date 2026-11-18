import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';

class QueueAppointmentItem {
  final String appointmentId;
  final String userId;
  final String patientName;
  final String patientPhone;
  final String serviceName;
  final String branchId;
  final String branchName;
  final String? doctorId;
  final String? doctorName;
  final String appointmentDatetime;
  final String appointmentTime;
  final int appointmentStatus;
  final String queueStatus; // scheduled | checked_in | in_room | completed | no_show
  final String? checkedInAt;
  final String? inRoomAt;
  final String? completedAt;
  final String? roomLabel;
  final String? adminRemark;
  final bool isPaid;
  final int waitMinutes;

  const QueueAppointmentItem({
    required this.appointmentId,
    required this.userId,
    required this.patientName,
    required this.patientPhone,
    required this.serviceName,
    required this.branchId,
    required this.branchName,
    this.doctorId,
    this.doctorName,
    required this.appointmentDatetime,
    required this.appointmentTime,
    required this.appointmentStatus,
    required this.queueStatus,
    this.checkedInAt,
    this.inRoomAt,
    this.completedAt,
    this.roomLabel,
    this.adminRemark,
    required this.isPaid,
    required this.waitMinutes,
  });

  factory QueueAppointmentItem.fromJson(Map<String, dynamic> json) => QueueAppointmentItem(
        appointmentId: json['appointmentId']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        patientName: json['patientName']?.toString() ?? 'Walk-in Patient',
        patientPhone: json['patientPhone']?.toString() ?? '',
        serviceName: json['serviceName']?.toString() ?? 'Consultation',
        branchId: json['branchId']?.toString() ?? '',
        branchName: json['branchName']?.toString() ?? '',
        doctorId: json['doctorId']?.toString(),
        doctorName: json['doctorName']?.toString(),
        appointmentDatetime: json['appointmentDatetime']?.toString() ?? '',
        appointmentTime: json['appointmentTime']?.toString() ?? '',
        appointmentStatus: (json['appointmentStatus'] as num?)?.toInt() ?? 1,
        queueStatus: json['queueStatus']?.toString() ?? 'scheduled',
        checkedInAt: json['checkedInAt']?.toString(),
        inRoomAt: json['inRoomAt']?.toString(),
        completedAt: json['completedAt']?.toString(),
        roomLabel: json['roomLabel']?.toString(),
        adminRemark: json['adminRemark']?.toString(),
        isPaid: json['isPaid'] == true,
        waitMinutes: (json['waitMinutes'] as num?)?.toInt() ?? 0,
      );
}

class QueueBoardData {
  final String date;
  final String? branchId;
  final bool queueColumnsReady;
  final int total;
  final int scheduled;
  final int checkedIn;
  final int inRoom;
  final int completed;
  final int noShow;
  final int avgWaitMinutes;
  final List<QueueAppointmentItem> items;

  const QueueBoardData({
    required this.date,
    this.branchId,
    required this.queueColumnsReady,
    required this.total,
    required this.scheduled,
    required this.checkedIn,
    required this.inRoom,
    required this.completed,
    required this.noShow,
    required this.avgWaitMinutes,
    required this.items,
  });

  factory QueueBoardData.fromJson(Map<String, dynamic> json) {
    final d = (json['data'] as Map<String, dynamic>?) ?? json;
    final s = (d['summary'] as Map<String, dynamic>?) ?? {};
    return QueueBoardData(
      date: d['date']?.toString() ?? '',
      branchId: d['branchId']?.toString(),
      queueColumnsReady: d['queueColumnsReady'] != false,
      total: (s['total'] as num?)?.toInt() ?? 0,
      scheduled: (s['scheduled'] as num?)?.toInt() ?? 0,
      checkedIn: (s['checked_in'] as num?)?.toInt() ?? 0,
      inRoom: (s['in_room'] as num?)?.toInt() ?? 0,
      completed: (s['completed'] as num?)?.toInt() ?? 0,
      noShow: (s['no_show'] as num?)?.toInt() ?? 0,
      avgWaitMinutes: (s['avgWaitMinutes'] as num?)?.toInt() ?? 0,
      items: ((d['items'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(QueueAppointmentItem.fromJson)
          .toList(),
    );
  }
}

class AppointmentQueueController {
  static Future<ApiResponse<QueueBoardData>> fetch(
    BuildContext context, {
    String? branchId,
    String? date,
  }) async {
    final q = <String, String>{
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      if (date != null && date.isNotEmpty) 'date': date,
    };
    final queryStr = q.isEmpty ? '' : '?${Uri(queryParameters: q).query}';
    final res = await ApiController().call(
      context,
      method: Method.get,
      endpoint: 'admin/appointment/queue$queryStr',
    );
    try {
      if (res.data is Map<String, dynamic>) {
        return ApiResponse(
          code: res.code,
          message: res.message,
          data: QueueBoardData.fromJson(res.data as Map<String, dynamic>),
        );
      }
      return ApiResponse(code: res.code, message: res.message);
    } catch (e) {
      return ApiResponse(code: 400, message: e.toString());
    }
  }

  static Future<ApiResponse<dynamic>> updateStatus(
    BuildContext context, {
    required String appointmentId,
    required String queueStatus,
    String? roomLabel,
    String? doctorId,
  }) async {
    return ApiController().call(
      context,
      method: Method.patch,
      endpoint: 'admin/appointment/queue/$appointmentId',
      data: {
        'queueStatus': queueStatus,
        'roomLabel': ?roomLabel,
        if (doctorId != null && doctorId.isNotEmpty) 'doctorId': doctorId,
      },
    );
  }
}
