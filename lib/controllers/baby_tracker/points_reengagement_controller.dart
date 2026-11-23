import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';

class PointsReengagementItem {
  final String userId;
  final String patientName;
  final String patientPhone;
  final String patientEmail;
  final String? branchId;
  final String branchName;
  final int totalPoints;
  final double cashValueRm;
  final String? nextExpiryDate;
  final String? lastVisitDate;
  final int daysSinceLastVisit;
  final bool hasUpcomingBooking;
  final String? upcomingBookingDate;
  final String? lastOutreachDate;
  final bool alreadyContactedRecently;
  final String suggestedMessage;
  final String? whatsappUrl;

  const PointsReengagementItem({
    required this.userId,
    required this.patientName,
    required this.patientPhone,
    required this.patientEmail,
    this.branchId,
    required this.branchName,
    required this.totalPoints,
    required this.cashValueRm,
    this.nextExpiryDate,
    this.lastVisitDate,
    required this.daysSinceLastVisit,
    required this.hasUpcomingBooking,
    this.upcomingBookingDate,
    this.lastOutreachDate,
    required this.alreadyContactedRecently,
    required this.suggestedMessage,
    this.whatsappUrl,
  });

  factory PointsReengagementItem.fromJson(Map<String, dynamic> json) => PointsReengagementItem(
        userId: json['userId']?.toString() ?? '',
        patientName: json['patientName']?.toString() ?? 'Patient',
        patientPhone: json['patientPhone']?.toString() ?? '',
        patientEmail: json['patientEmail']?.toString() ?? '',
        branchId: json['branchId']?.toString(),
        branchName: json['branchName']?.toString() ?? 'Klinik Aurora',
        totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
        cashValueRm: (json['cashValueRm'] as num?)?.toDouble() ?? 0.0,
        nextExpiryDate: json['nextExpiryDate']?.toString(),
        lastVisitDate: json['lastVisitDate']?.toString(),
        daysSinceLastVisit: (json['daysSinceLastVisit'] as num?)?.toInt() ?? 0,
        hasUpcomingBooking: json['hasUpcomingBooking'] == true,
        upcomingBookingDate: json['upcomingBookingDate']?.toString(),
        lastOutreachDate: json['lastOutreachDate']?.toString(),
        alreadyContactedRecently: json['alreadyContactedRecently'] == true,
        suggestedMessage: json['suggestedMessage']?.toString() ?? '',
        whatsappUrl: json['whatsappUrl']?.toString(),
      );
}

class PointsReengagementResponse {
  final int totalEligible;
  final int uncontactedCount;
  final List<PointsReengagementItem> items;

  const PointsReengagementResponse({
    required this.totalEligible,
    required this.uncontactedCount,
    required this.items,
  });

  factory PointsReengagementResponse.fromJson(Map<String, dynamic> json) {
    final d = (json['data'] as Map<String, dynamic>?) ?? json;
    return PointsReengagementResponse(
      totalEligible: (d['totalEligible'] as num?)?.toInt() ?? 0,
      uncontactedCount: (d['uncontactedCount'] as num?)?.toInt() ?? 0,
      items: ((d['items'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PointsReengagementItem.fromJson)
          .toList(),
    );
  }
}

class PointsReengagementController {
  static Future<ApiResponse<PointsReengagementResponse>> fetch(
    BuildContext context, {
    String? branchId,
    int minPoints = 500,
    bool onlyUnbooked = true,
  }) async {
    final q = <String, String>{
      'minPoints': minPoints.toString(),
      'onlyUnbooked': onlyUnbooked.toString(),
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
    };
    final queryStr = Uri(queryParameters: q).query;
    final res = await ApiController().call(
      context,
      method: Method.get,
      endpoint: 'admin/baby-tracker/points-reengagement?$queryStr',
    );
    try {
      if (res.data is Map<String, dynamic>) {
        return ApiResponse(
          code: res.code,
          message: res.message,
          data: PointsReengagementResponse.fromJson(res.data as Map<String, dynamic>),
        );
      }
      return ApiResponse(code: res.code, message: res.message);
    } catch (e) {
      return ApiResponse(code: 400, message: e.toString());
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> sendOutreach(
    BuildContext context, {
    required String userId,
    String? branchId,
    required String channel,
    String? message,
  }) async {
    final res = await ApiController().call(
      context,
      method: Method.post,
      endpoint: 'admin/baby-tracker/points-reengagement/send',
      data: {
        'userId': userId,
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        'channel': channel,
        if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
      },
    );
    return ApiResponse(
      code: res.code,
      message: res.message,
      data: res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : null,
    );
  }
}
