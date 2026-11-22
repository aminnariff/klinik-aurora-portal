import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';

class PatientSummaryProfile {
  final String userId;
  final String fullname;
  final String username;
  final String email;
  final String phone;
  final String nric;
  final String? dob;
  final String? branchId;
  final String? branchName;
  final int totalPoint;
  final int status;
  final String? createdDate;

  const PatientSummaryProfile({
    required this.userId,
    required this.fullname,
    required this.username,
    required this.email,
    required this.phone,
    required this.nric,
    this.dob,
    this.branchId,
    this.branchName,
    required this.totalPoint,
    required this.status,
    this.createdDate,
  });

  factory PatientSummaryProfile.fromJson(Map<String, dynamic> json) => PatientSummaryProfile(
        userId: json['userId']?.toString() ?? '',
        fullname: json['userFullname']?.toString() ?? 'Patient',
        username: json['userName']?.toString() ?? '',
        email: json['userEmail']?.toString() ?? '',
        phone: json['userPhone']?.toString() ?? '',
        nric: json['userNric']?.toString() ?? '',
        dob: json['userDob']?.toString(),
        branchId: json['branchId']?.toString(),
        branchName: json['branchName']?.toString(),
        totalPoint: (json['totalPoint'] as num?)?.toInt() ?? 0,
        status: (json['userStatus'] as num?)?.toInt() ?? 1,
        createdDate: json['createdDate']?.toString(),
      );
}

class PatientVisitStats {
  final int totalVisits;
  final int completedVisits;
  final int upcomingVisits;
  final int cancelledVisits;
  final int noShowVisits;
  final String? lastVisitDate;
  final String? nextVisitDate;

  const PatientVisitStats({
    required this.totalVisits,
    required this.completedVisits,
    required this.upcomingVisits,
    required this.cancelledVisits,
    required this.noShowVisits,
    this.lastVisitDate,
    this.nextVisitDate,
  });

  factory PatientVisitStats.fromJson(Map<String, dynamic> json) => PatientVisitStats(
        totalVisits: (json['totalVisits'] as num?)?.toInt() ?? 0,
        completedVisits: (json['completedVisits'] as num?)?.toInt() ?? 0,
        upcomingVisits: (json['upcomingVisits'] as num?)?.toInt() ?? 0,
        cancelledVisits: (json['cancelledVisits'] as num?)?.toInt() ?? 0,
        noShowVisits: (json['noShowVisits'] as num?)?.toInt() ?? 0,
        lastVisitDate: json['lastVisitDate']?.toString(),
        nextVisitDate: json['nextVisitDate']?.toString(),
      );
}

class PatientRecentAppointment {
  final String appointmentId;
  final String appointmentDatetime;
  final int appointmentStatus;
  final String serviceName;
  final String branchName;
  final String? doctorName;
  final String? adminRemark;

  const PatientRecentAppointment({
    required this.appointmentId,
    required this.appointmentDatetime,
    required this.appointmentStatus,
    required this.serviceName,
    required this.branchName,
    this.doctorName,
    this.adminRemark,
  });

  factory PatientRecentAppointment.fromJson(Map<String, dynamic> json) => PatientRecentAppointment(
        appointmentId: json['appointmentId']?.toString() ?? '',
        appointmentDatetime: json['appointmentDatetime']?.toString() ?? '',
        appointmentStatus: (json['appointmentStatus'] as num?)?.toInt() ?? 1,
        serviceName: json['serviceName']?.toString() ?? 'Service',
        branchName: json['branchName']?.toString() ?? '',
        doctorName: json['doctorName']?.toString(),
        adminRemark: json['adminRemark']?.toString(),
      );
}

class PatientBabyTrackerSummary {
  final String eddDate;

  /// 1 single, 2 twins (Baby Tracker choice).
  final int babyCount;
  final int gestationalWeek;
  final int trimester;
  final bool isOverdue;
  final bool isBabyBorn;
  final String? babyName;
  final int todayKicks;

  const PatientBabyTrackerSummary({
    required this.eddDate,
    this.babyCount = 1,
    required this.gestationalWeek,
    required this.trimester,
    required this.isOverdue,
    required this.isBabyBorn,
    this.babyName,
    required this.todayKicks,
  });

  factory PatientBabyTrackerSummary.fromJson(Map<String, dynamic> json) => PatientBabyTrackerSummary(
        eddDate: json['eddDate']?.toString() ?? '',
        babyCount: (json['babyCount'] as num?)?.toInt() == 2 ? 2 : 1,
        gestationalWeek: (json['gestationalWeek'] as num?)?.toInt() ?? 0,
        trimester: (json['trimester'] as num?)?.toInt() ?? 1,
        isOverdue: json['isOverdue'] == true,
        isBabyBorn: json['isBabyBorn'] == true,
        babyName: json['babyName']?.toString(),
        todayKicks: (json['todayKicks'] as num?)?.toInt() ?? 0,
      );
}

class PatientSummaryData {
  final PatientSummaryProfile profile;
  final PatientVisitStats visitStats;
  final List<PatientRecentAppointment> recentAppointments;
  final PatientBabyTrackerSummary? babyTracker;
  final List<Map<String, dynamic>> vouchers;
  final List<Map<String, dynamic>> recentPoints;
  final String? nextPointExpiry;

  const PatientSummaryData({
    required this.profile,
    required this.visitStats,
    required this.recentAppointments,
    this.babyTracker,
    required this.vouchers,
    required this.recentPoints,
    this.nextPointExpiry,
  });

  factory PatientSummaryData.fromJson(Map<String, dynamic> json) {
    final d = (json['data'] as Map<String, dynamic>?) ?? json;
    return PatientSummaryData(
      profile: PatientSummaryProfile.fromJson((d['profile'] as Map<String, dynamic>?) ?? {}),
      visitStats: PatientVisitStats.fromJson((d['visitStats'] as Map<String, dynamic>?) ?? {}),
      recentAppointments: ((d['recentAppointments'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PatientRecentAppointment.fromJson)
          .toList(),
      babyTracker: d['babyTracker'] is Map<String, dynamic>
          ? PatientBabyTrackerSummary.fromJson(d['babyTracker'] as Map<String, dynamic>)
          : null,
      vouchers: ((d['vouchers'] as List?) ?? []).whereType<Map<String, dynamic>>().toList(),
      recentPoints: ((d['recentPoints'] as List?) ?? []).whereType<Map<String, dynamic>>().toList(),
      nextPointExpiry: d['nextPointExpiry']?.toString(),
    );
  }
}

class PatientSummaryController {
  static Future<ApiResponse<PatientSummaryData>> fetch(BuildContext context, String userId) async {
    final res = await ApiController().call(
      context,
      method: Method.get,
      endpoint: 'admin/user-management/summary/$userId',
    );
    try {
      if (res.data is Map<String, dynamic>) {
        return ApiResponse(
          code: res.code,
          message: res.message,
          data: PatientSummaryData.fromJson(res.data as Map<String, dynamic>),
        );
      }
      return ApiResponse(code: res.code, message: res.message);
    } catch (e) {
      return ApiResponse(code: 400, message: e.toString());
    }
  }
}
