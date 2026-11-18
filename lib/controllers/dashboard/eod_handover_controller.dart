import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';

class EodChannelBreakdown {
  final String channel;
  final int count;
  final double amount;

  const EodChannelBreakdown({
    required this.channel,
    required this.count,
    required this.amount,
  });

  factory EodChannelBreakdown.fromJson(Map<String, dynamic> json) => EodChannelBreakdown(
        channel: json['channel']?.toString() ?? 'Other',
        count: (json['count'] as num?)?.toInt() ?? 0,
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      );
}

class EodTransactionItem {
  final String paymentId;
  final String appointmentId;
  final String receiptNo;
  final int paymentType;
  final String state;
  final String channel;
  final double amount;
  final String userId;
  final String patientName;
  final String serviceName;
  final String branchName;
  final String paymentTime;

  const EodTransactionItem({
    required this.paymentId,
    required this.appointmentId,
    required this.receiptNo,
    required this.paymentType,
    required this.state,
    required this.channel,
    required this.amount,
    required this.userId,
    required this.patientName,
    required this.serviceName,
    required this.branchName,
    required this.paymentTime,
  });

  factory EodTransactionItem.fromJson(Map<String, dynamic> json) => EodTransactionItem(
        paymentId: json['paymentId']?.toString() ?? '',
        appointmentId: json['appointmentId']?.toString() ?? '',
        receiptNo: json['receiptNo']?.toString() ?? '-',
        paymentType: (json['paymentType'] as num?)?.toInt() ?? 1,
        state: json['state']?.toString() ?? '',
        channel: json['channel']?.toString() ?? 'Online',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        userId: json['userId']?.toString() ?? '',
        patientName: json['patientName']?.toString() ?? 'Patient',
        serviceName: json['serviceName']?.toString() ?? '-',
        branchName: json['branchName']?.toString() ?? '-',
        paymentTime: json['paymentTime']?.toString() ?? '',
      );
}

class EodHandoverData {
  final String date;
  final String? branchId;
  final String branchName;
  final Map<String, int> appointmentSummary;
  final double totalCollected;
  final double fiuuOnlineAmount;
  final int fiuuOnlineCount;
  final double counterProofAmount;
  final int counterProofCount;
  final double totalRefundAmount;
  final int refundCount;
  final double netRevenue;
  final List<EodChannelBreakdown> channelBreakdown;
  final int mismatchCount;
  final int unpaidCompletedCount;
  final int pendingPaymentCount;
  final List<EodTransactionItem> transactions;

  const EodHandoverData({
    required this.date,
    this.branchId,
    required this.branchName,
    required this.appointmentSummary,
    required this.totalCollected,
    required this.fiuuOnlineAmount,
    required this.fiuuOnlineCount,
    required this.counterProofAmount,
    required this.counterProofCount,
    required this.totalRefundAmount,
    required this.refundCount,
    required this.netRevenue,
    required this.channelBreakdown,
    required this.mismatchCount,
    required this.unpaidCompletedCount,
    required this.pendingPaymentCount,
    required this.transactions,
  });

  factory EodHandoverData.fromJson(Map<String, dynamic> json) {
    final d = (json['data'] as Map<String, dynamic>?) ?? json;
    final appt = (d['appointmentSummary'] as Map<String, dynamic>?) ?? {};
    final fin = (d['financialSummary'] as Map<String, dynamic>?) ?? {};
    final alerts = (d['reconciliationAlerts'] as Map<String, dynamic>?) ?? {};
    return EodHandoverData(
      date: d['date']?.toString() ?? '',
      branchId: d['branchId']?.toString(),
      branchName: d['branchName']?.toString() ?? 'All Branches',
      appointmentSummary: appt.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
      totalCollected: (fin['totalCollected'] as num?)?.toDouble() ?? 0,
      fiuuOnlineAmount: (fin['fiuuOnlineAmount'] as num?)?.toDouble() ?? 0,
      fiuuOnlineCount: (fin['fiuuOnlineCount'] as num?)?.toInt() ?? 0,
      counterProofAmount: (fin['counterProofAmount'] as num?)?.toDouble() ?? 0,
      counterProofCount: (fin['counterProofCount'] as num?)?.toInt() ?? 0,
      totalRefundAmount: (fin['totalRefundAmount'] as num?)?.toDouble() ?? 0,
      refundCount: (fin['refundCount'] as num?)?.toInt() ?? 0,
      netRevenue: (fin['netRevenue'] as num?)?.toDouble() ?? 0,
      channelBreakdown: ((fin['channelBreakdown'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(EodChannelBreakdown.fromJson)
          .toList(),
      mismatchCount: (alerts['mismatchCount'] as num?)?.toInt() ?? 0,
      unpaidCompletedCount: (alerts['unpaidCompletedCount'] as num?)?.toInt() ?? 0,
      pendingPaymentCount: (alerts['pendingPaymentCount'] as num?)?.toInt() ?? 0,
      transactions: ((d['transactions'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(EodTransactionItem.fromJson)
          .toList(),
    );
  }
}

class EodHandoverController {
  static Future<ApiResponse<EodHandoverData>> fetch(
    BuildContext context, {
    String? date,
    String? branchId,
  }) async {
    final q = <String, String>{
      if (date != null && date.isNotEmpty) 'date': date,
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
    };
    final queryStr = q.isEmpty ? '' : '?${Uri(queryParameters: q).query}';
    final res = await ApiController().call(
      context,
      method: Method.get,
      endpoint: 'admin/dashboard/eod-handover$queryStr',
    );
    try {
      if (res.data is Map<String, dynamic>) {
        return ApiResponse(
          code: res.code,
          message: res.message,
          data: EodHandoverData.fromJson(res.data as Map<String, dynamic>),
        );
      }
      return ApiResponse(code: res.code, message: res.message);
    } catch (e) {
      return ApiResponse(code: 400, message: e.toString());
    }
  }
}
