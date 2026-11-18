import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';

class HeatmapCell {
  final int dayOfWeek; // 0=Mon .. 6=Sun
  final int hour; // 8 .. 21
  final int bookedCount;
  final int capacityCount;
  final int utilizationPct;

  const HeatmapCell({
    required this.dayOfWeek,
    required this.hour,
    required this.bookedCount,
    required this.capacityCount,
    required this.utilizationPct,
  });

  factory HeatmapCell.fromJson(Map<String, dynamic> json) => HeatmapCell(
        dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 0,
        hour: (json['hour'] as num?)?.toInt() ?? 8,
        bookedCount: (json['bookedCount'] as num?)?.toInt() ?? 0,
        capacityCount: (json['capacityCount'] as num?)?.toInt() ?? 0,
        utilizationPct: (json['utilizationPct'] as num?)?.toInt() ?? 0,
      );
}

class PractitionerLoadItem {
  final String doctorId;
  final String doctorName;
  final int doctorType;
  final String branchName;
  final int shiftHours;
  final int capacitySlots;
  final int bookedCount;
  final int utilizationPct;
  final String status; // overloaded | optimal | underutilized

  const PractitionerLoadItem({
    required this.doctorId,
    required this.doctorName,
    required this.doctorType,
    required this.branchName,
    required this.shiftHours,
    required this.capacitySlots,
    required this.bookedCount,
    required this.utilizationPct,
    required this.status,
  });

  factory PractitionerLoadItem.fromJson(Map<String, dynamic> json) => PractitionerLoadItem(
        doctorId: json['doctorId']?.toString() ?? '',
        doctorName: json['doctorName']?.toString() ?? 'Practitioner',
        doctorType: (json['doctorType'] as num?)?.toInt() ?? 1,
        branchName: json['branchName']?.toString() ?? '',
        shiftHours: (json['shiftHours'] as num?)?.toInt() ?? 0,
        capacitySlots: (json['capacitySlots'] as num?)?.toInt() ?? 0,
        bookedCount: (json['bookedCount'] as num?)?.toInt() ?? 0,
        utilizationPct: (json['utilizationPct'] as num?)?.toInt() ?? 0,
        status: json['status']?.toString() ?? 'optimal',
      );
}

class UtilizationHeatmapData {
  final String startDate;
  final String endDate;
  final String? branchId;
  final int totalCapacity;
  final int totalBooked;
  final int avgUtilizationPct;
  final int overloadedPractitioners;
  final int underutilizedPractitioners;
  final int unassignedAppointments;
  final List<HeatmapCell> heatmap;
  final List<HeatmapCell> peakSlots;
  final List<HeatmapCell> idleSlots;
  final List<PractitionerLoadItem> practitionerLoad;

  const UtilizationHeatmapData({
    required this.startDate,
    required this.endDate,
    this.branchId,
    required this.totalCapacity,
    required this.totalBooked,
    required this.avgUtilizationPct,
    required this.overloadedPractitioners,
    required this.underutilizedPractitioners,
    required this.unassignedAppointments,
    required this.heatmap,
    required this.peakSlots,
    required this.idleSlots,
    required this.practitionerLoad,
  });

  factory UtilizationHeatmapData.fromJson(Map<String, dynamic> json) {
    final d = (json['data'] as Map<String, dynamic>?) ?? json;
    final s = (d['summary'] as Map<String, dynamic>?) ?? {};
    return UtilizationHeatmapData(
      startDate: d['startDate']?.toString() ?? '',
      endDate: d['endDate']?.toString() ?? '',
      branchId: d['branchId']?.toString(),
      totalCapacity: (s['totalCapacity'] as num?)?.toInt() ?? 0,
      totalBooked: (s['totalBooked'] as num?)?.toInt() ?? 0,
      avgUtilizationPct: (s['avgUtilizationPct'] as num?)?.toInt() ?? 0,
      overloadedPractitioners: (s['overloadedPractitioners'] as num?)?.toInt() ?? 0,
      underutilizedPractitioners: (s['underutilizedPractitioners'] as num?)?.toInt() ?? 0,
      unassignedAppointments: (s['unassignedAppointments'] as num?)?.toInt() ?? 0,
      heatmap: ((d['heatmap'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(HeatmapCell.fromJson)
          .toList(),
      peakSlots: ((d['peakSlots'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(HeatmapCell.fromJson)
          .toList(),
      idleSlots: ((d['idleSlots'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(HeatmapCell.fromJson)
          .toList(),
      practitionerLoad: ((d['practitionerLoad'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PractitionerLoadItem.fromJson)
          .toList(),
    );
  }
}

class UtilizationHeatmapController {
  static Future<ApiResponse<UtilizationHeatmapData>> fetch(
    BuildContext context, {
    String? branchId,
    String? startDate,
    String? endDate,
  }) async {
    final q = <String, String>{
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
      if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
    };
    final queryStr = q.isEmpty ? '' : '?${Uri(queryParameters: q).query}';
    final res = await ApiController().call(
      context,
      method: Method.get,
      endpoint: 'admin/dashboard/utilization-heatmap$queryStr',
    );
    try {
      if (res.data is Map<String, dynamic>) {
        return ApiResponse(
          code: res.code,
          message: res.message,
          data: UtilizationHeatmapData.fromJson(res.data as Map<String, dynamic>),
        );
      }
      return ApiResponse(code: res.code, message: res.message);
    } catch (e) {
      return ApiResponse(code: 400, message: e.toString());
    }
  }
}
