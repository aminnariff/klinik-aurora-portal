import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';

class CheckoutAddOnItem {
  String name;
  double price;
  int quantity;

  CheckoutAddOnItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
      };

  factory CheckoutAddOnItem.fromJson(Map<String, dynamic> json) => CheckoutAddOnItem(
        name: json['name']?.toString() ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );
}

class CheckoutMilestoneRule {
  final String key;
  final String label;
  final int bonusPoints;
  final int minWeek;
  final int maxWeek;

  const CheckoutMilestoneRule({
    required this.key,
    required this.label,
    required this.bonusPoints,
    required this.minWeek,
    required this.maxWeek,
  });

  factory CheckoutMilestoneRule.fromJson(Map<String, dynamic> json) => CheckoutMilestoneRule(
        key: json['key']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        bonusPoints: (json['bonusPoints'] as num?)?.toInt() ?? 0,
        minWeek: (json['minWeek'] as num?)?.toInt() ?? 0,
        maxWeek: (json['maxWeek'] as num?)?.toInt() ?? 0,
      );
}

class CheckoutPreviewData {
  final String appointmentId;
  final String userId;
  final String patientName;
  final String patientPhone;
  final String branchId;
  final String branchName;
  final String? doctorName;
  final String serviceName;
  final double basePrice;
  final double serviceBookingFee;
  final double bookingFeePaid;
  final double expectedBalance;
  final int currentPoints;
  final int? gestationalWeek;
  final CheckoutMilestoneRule? detectedMilestone;
  final List<CheckoutMilestoneRule> milestones;
  final List<CheckoutAddOnItem> suggestedAddOns;

  const CheckoutPreviewData({
    required this.appointmentId,
    required this.userId,
    required this.patientName,
    required this.patientPhone,
    required this.branchId,
    required this.branchName,
    this.doctorName,
    required this.serviceName,
    required this.basePrice,
    this.serviceBookingFee = 0.0,
    required this.bookingFeePaid,
    required this.expectedBalance,
    required this.currentPoints,
    this.gestationalWeek,
    this.detectedMilestone,
    required this.milestones,
    required this.suggestedAddOns,
  });

  factory CheckoutPreviewData.fromJson(Map<String, dynamic> json) {
    final d = (json['data'] as Map<String, dynamic>?) ?? json;
    return CheckoutPreviewData(
      appointmentId: d['appointmentId']?.toString() ?? '',
      userId: d['userId']?.toString() ?? '',
      patientName: d['patientName']?.toString() ?? 'Patient',
      patientPhone: d['patientPhone']?.toString() ?? '',
      branchId: d['branchId']?.toString() ?? '',
      branchName: d['branchName']?.toString() ?? '',
      doctorName: d['doctorName']?.toString(),
      serviceName: d['serviceName']?.toString() ?? 'Consultation',
      basePrice: (d['basePrice'] as num?)?.toDouble() ?? 0.0,
      serviceBookingFee: (d['serviceBookingFee'] as num?)?.toDouble() ?? 0.0,
      bookingFeePaid: (d['bookingFeePaid'] as num?)?.toDouble() ?? 0.0,
      expectedBalance: (d['expectedBalance'] as num?)?.toDouble() ?? 0.0,
      currentPoints: (d['currentPoints'] as num?)?.toInt() ?? 0,
      gestationalWeek: (d['gestationalWeek'] as num?)?.toInt(),
      detectedMilestone: d['detectedMilestone'] != null
          ? CheckoutMilestoneRule.fromJson(d['detectedMilestone'] as Map<String, dynamic>)
          : null,
      milestones: ((d['milestones'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CheckoutMilestoneRule.fromJson)
          .toList(),
      suggestedAddOns: ((d['suggestedAddOns'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CheckoutAddOnItem.fromJson)
          .toList(),
    );
  }
}

class CheckoutResultData {
  final String appointmentId;
  final String patientName;
  final String serviceName;
  final double grossTotal;
  final double bookingFeePaid;
  final double netCollected;
  final String paymentMethod;
  final int pointsAwarded;
  final int basePoints;
  final int milestoneBonusPoints;
  final int newTotalPoints;
  final String whatsappReceipt;
  final String? whatsappUrl;

  const CheckoutResultData({
    required this.appointmentId,
    required this.patientName,
    required this.serviceName,
    required this.grossTotal,
    required this.bookingFeePaid,
    required this.netCollected,
    required this.paymentMethod,
    required this.pointsAwarded,
    required this.basePoints,
    required this.milestoneBonusPoints,
    required this.newTotalPoints,
    required this.whatsappReceipt,
    this.whatsappUrl,
  });

  factory CheckoutResultData.fromJson(Map<String, dynamic> json) {
    final d = (json['data'] as Map<String, dynamic>?) ?? json;
    return CheckoutResultData(
      appointmentId: d['appointmentId']?.toString() ?? '',
      patientName: d['patientName']?.toString() ?? '',
      serviceName: d['serviceName']?.toString() ?? '',
      grossTotal: (d['grossTotal'] as num?)?.toDouble() ?? 0.0,
      bookingFeePaid: (d['bookingFeePaid'] as num?)?.toDouble() ?? 0.0,
      netCollected: (d['netCollected'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: d['paymentMethod']?.toString() ?? 'cash',
      pointsAwarded: (d['pointsAwarded'] as num?)?.toInt() ?? 0,
      basePoints: (d['basePoints'] as num?)?.toInt() ?? 0,
      milestoneBonusPoints: (d['milestoneBonusPoints'] as num?)?.toInt() ?? 0,
      newTotalPoints: (d['newTotalPoints'] as num?)?.toInt() ?? 0,
      whatsappReceipt: d['whatsappReceipt']?.toString() ?? '',
      whatsappUrl: d['whatsappUrl']?.toString(),
    );
  }
}

class AppointmentCheckoutController {
  static Future<ApiResponse<CheckoutPreviewData>> fetchPreview(
    BuildContext context,
    String appointmentId,
  ) async {
    final res = await ApiController().call(
      context,
      method: Method.get,
      endpoint: 'admin/appointment/$appointmentId/checkout-preview',
    );
    try {
      if (res.data is Map<String, dynamic>) {
        return ApiResponse(
          code: res.code,
          message: res.message,
          data: CheckoutPreviewData.fromJson(res.data as Map<String, dynamic>),
        );
      }
      return ApiResponse(code: res.code, message: res.message);
    } catch (e) {
      return ApiResponse(code: 400, message: e.toString());
    }
  }

  static Future<ApiResponse<CheckoutResultData>> submitCheckout(
    BuildContext context,
    String appointmentId, {
    double? totalSpend,
    required double basePrice,
    required double bookingFeePaid,
    required List<CheckoutAddOnItem> extraItems,
    required double netCollected,
    required String paymentMethod,
    bool awardPoints = true,
    required int basePoints,
    required int milestoneBonusPoints,
    String? milestoneKey,
    String? milestoneName,
    String? adminNotes,
  }) async {
    final res = await ApiController().call(
      context,
      method: Method.post,
      endpoint: 'admin/appointment/$appointmentId/checkout',
      data: {
        'totalSpend': totalSpend ?? basePrice,
        'grossTotal': totalSpend ?? basePrice,
        'basePrice': basePrice,
        'bookingFeePaid': bookingFeePaid,
        'extraItems': extraItems.map((e) => e.toJson()).toList(),
        'netCollected': netCollected,
        'paymentMethod': paymentMethod,
        'awardPoints': awardPoints,
        'basePoints': basePoints,
        'milestoneBonusPoints': milestoneBonusPoints,
        if (milestoneKey != null && milestoneKey.isNotEmpty) 'milestoneKey': milestoneKey,
        if (milestoneName != null && milestoneName.isNotEmpty) 'milestoneName': milestoneName,
        if (adminNotes != null && adminNotes.trim().isNotEmpty) 'adminNotes': adminNotes.trim(),
      },
    );
    try {
      if (res.data is Map<String, dynamic>) {
        return ApiResponse(
          code: res.code,
          message: res.message,
          data: CheckoutResultData.fromJson(res.data as Map<String, dynamic>),
        );
      }
      return ApiResponse(code: res.code, message: res.message);
    } catch (e) {
      return ApiResponse(code: 400, message: e.toString());
    }
  }
}
