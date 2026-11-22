import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';

class PatientRecallItem {
  final String userId;
  final String patientName;
  final String patientPhone;
  final String patientEmail;
  final String? branchId;
  final String branchName;
  final String eddDate;

  /// 1 single, 2 twins (Baby Tracker choice); twins get twin scan windows.
  final int babyCount;
  final int gestationalWeek;
  final String milestoneKey;
  final String milestoneLabel;
  final String recommendedScan;
  final bool hasBooked;
  final bool alreadyRecalled;
  final String? lastRecallSentAt;
  final String? lastRecallChannel;
  final String? lastRecallBy;
  final String suggestedMessage;
  final String? whatsappUrl;

  const PatientRecallItem({
    required this.userId,
    required this.patientName,
    required this.patientPhone,
    required this.patientEmail,
    this.branchId,
    required this.branchName,
    required this.eddDate,
    this.babyCount = 1,
    required this.gestationalWeek,
    required this.milestoneKey,
    required this.milestoneLabel,
    required this.recommendedScan,
    required this.hasBooked,
    required this.alreadyRecalled,
    this.lastRecallSentAt,
    this.lastRecallChannel,
    this.lastRecallBy,
    required this.suggestedMessage,
    this.whatsappUrl,
  });

  factory PatientRecallItem.fromJson(Map<String, dynamic> json) => PatientRecallItem(
        userId: json['userId']?.toString() ?? '',
        patientName: json['patientName']?.toString() ?? 'Patient',
        patientPhone: json['patientPhone']?.toString() ?? '',
        patientEmail: json['patientEmail']?.toString() ?? '',
        branchId: json['branchId']?.toString(),
        branchName: json['branchName']?.toString() ?? 'Unassigned',
        eddDate: json['eddDate']?.toString() ?? '',
        babyCount: (json['babyCount'] as num?)?.toInt() == 2 ? 2 : 1,
        gestationalWeek: (json['gestationalWeek'] as num?)?.toInt() ?? 0,
        milestoneKey: json['milestoneKey']?.toString() ?? '',
        milestoneLabel: json['milestoneLabel']?.toString() ?? '',
        recommendedScan: json['recommendedScan']?.toString() ?? '',
        hasBooked: json['hasBooked'] == true,
        alreadyRecalled: json['alreadyRecalled'] == true,
        lastRecallSentAt: json['lastRecallSentAt']?.toString(),
        lastRecallChannel: json['lastRecallChannel']?.toString(),
        lastRecallBy: json['lastRecallBy']?.toString(),
        suggestedMessage: json['suggestedMessage']?.toString() ?? '',
        whatsappUrl: json['whatsappUrl']?.toString(),
      );
}

class PatientRecallResponse {
  final int totalEligible;
  final int unbookedCount;
  final int pendingOutreachCount;
  final int alreadyRecalledCount;
  final Map<String, int> byMilestone;
  final List<PatientRecallItem> items;

  const PatientRecallResponse({
    required this.totalEligible,
    required this.unbookedCount,
    required this.pendingOutreachCount,
    required this.alreadyRecalledCount,
    required this.byMilestone,
    required this.items,
  });

  factory PatientRecallResponse.fromJson(Map<String, dynamic> json) {
    final d = (json['data'] as Map<String, dynamic>?) ?? json;
    final s = (d['summary'] as Map<String, dynamic>?) ?? {};
    final byM = (s['byMilestone'] as Map<String, dynamic>?) ?? {};
    return PatientRecallResponse(
      totalEligible: (s['totalEligible'] as num?)?.toInt() ?? 0,
      unbookedCount: (s['unbookedCount'] as num?)?.toInt() ?? 0,
      pendingOutreachCount: (s['pendingOutreachCount'] as num?)?.toInt() ?? 0,
      alreadyRecalledCount: (s['alreadyRecalledCount'] as num?)?.toInt() ?? 0,
      byMilestone: byM.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
      items: ((d['items'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PatientRecallItem.fromJson)
          .toList(),
    );
  }
}

class PatientRecallController {
  static Future<ApiResponse<PatientRecallResponse>> fetch(
    BuildContext context, {
    String? branchId,
    String milestone = 'all',
    bool onlyUnbooked = false,
  }) async {
    final q = <String, String>{
      'milestone': milestone,
      'onlyUnbooked': onlyUnbooked.toString(),
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
    };
    final queryStr = Uri(queryParameters: q).query;
    final res = await ApiController().call(
      context,
      method: Method.get,
      endpoint: 'admin/baby-tracker/recalls?$queryStr',
    );
    try {
      if (res.data is Map<String, dynamic>) {
        return ApiResponse(
          code: res.code,
          message: res.message,
          data: PatientRecallResponse.fromJson(res.data as Map<String, dynamic>),
        );
      }
      return ApiResponse(code: res.code, message: res.message);
    } catch (e) {
      return ApiResponse(code: 400, message: e.toString());
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> sendRecall(
    BuildContext context, {
    required String userId,
    String? branchId,
    required String milestoneKey,
    required int gestationalWeek,
    required String channel, // 'whatsapp' | 'push' | 'both'
    String? message,
  }) async {
    final res = await ApiController().call(
      context,
      method: Method.post,
      endpoint: 'admin/baby-tracker/recalls/send',
      data: {
        'userId': userId,
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        'milestoneKey': milestoneKey,
        'gestationalWeek': gestationalWeek,
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
