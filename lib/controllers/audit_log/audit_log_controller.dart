import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';

class AuditLogEntry {
  final int logId;
  final String adminId;
  final String adminName;
  final String adminEmail;
  final String? adminBranchId;
  final String? branchName;
  final String entityType;
  final String entityId;
  final String action;
  final String summary;
  final dynamic beforeState;
  final dynamic afterState;
  final String? ipAddress;
  final String createdDate;

  const AuditLogEntry({
    required this.logId,
    required this.adminId,
    required this.adminName,
    required this.adminEmail,
    this.adminBranchId,
    this.branchName,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.summary,
    this.beforeState,
    this.afterState,
    this.ipAddress,
    required this.createdDate,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      logId: (json['logId'] as num?)?.toInt() ?? 0,
      adminId: json['adminId']?.toString() ?? '',
      adminName: json['adminName']?.toString() ?? 'Admin',
      adminEmail: json['adminEmail']?.toString() ?? '',
      adminBranchId: json['adminBranchId']?.toString(),
      branchName: json['branchName']?.toString(),
      entityType: json['entityType']?.toString() ?? '',
      entityId: json['entityId']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      beforeState: json['beforeState'],
      afterState: json['afterState'],
      ipAddress: json['ipAddress']?.toString(),
      createdDate: json['createdDate']?.toString() ?? '',
    );
  }
}

class AuditLogPageResponse {
  final List<AuditLogEntry> data;
  final int totalCount;
  final int totalPage;
  final int currentPage;
  final int pageSize;
  final List<String> entityTypes;
  final List<String> actions;
  final bool tableReady;

  const AuditLogPageResponse({
    required this.data,
    required this.totalCount,
    required this.totalPage,
    required this.currentPage,
    required this.pageSize,
    required this.entityTypes,
    required this.actions,
    this.tableReady = true,
  });

  factory AuditLogPageResponse.fromJson(Map<String, dynamic> json) {
    final facets = (json['facets'] as Map<String, dynamic>?) ?? {};
    return AuditLogPageResponse(
      data: ((json['data'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AuditLogEntry.fromJson)
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalPage: (json['totalPage'] as num?)?.toInt() ?? 1,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 25,
      entityTypes: ((facets['entityTypes'] as List?) ?? []).map((e) => e.toString()).toList(),
      actions: ((facets['actions'] as List?) ?? []).map((e) => e.toString()).toList(),
      tableReady: json['tableReady'] != false,
    );
  }
}

class AuditLogController {
  static Future<ApiResponse<AuditLogPageResponse>> fetch(
    BuildContext context, {
    int page = 1,
    int pageSize = 25,
    String? entityType,
    String? action,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    final q = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (entityType != null && entityType.isNotEmpty) 'entityType': entityType,
      if (action != null && action.isNotEmpty) 'action': action,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
      if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
    };
    final queryStr = Uri(queryParameters: q).query;
    final res = await ApiController().call(
      context,
      method: Method.get,
      endpoint: 'admin/audit-log?$queryStr',
    );
    try {
      if (res.data is Map<String, dynamic>) {
        return ApiResponse(
          code: res.code,
          message: res.message,
          data: AuditLogPageResponse.fromJson(res.data as Map<String, dynamic>),
        );
      }
      return ApiResponse(code: res.code, message: res.message);
    } catch (e) {
      return ApiResponse(code: 400, message: e.toString());
    }
  }
}
