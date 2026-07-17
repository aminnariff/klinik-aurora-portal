class BulkUpsertAvailableDtResponse {
  int? code;
  String? message;
  List<BulkUpsertResult>? data;

  BulkUpsertAvailableDtResponse({this.code, this.message, this.data});

  factory BulkUpsertAvailableDtResponse.fromJson(Map<String, dynamic> json) =>
      BulkUpsertAvailableDtResponse(
        code: json['code'],
        message: json['message'],
        data: json['data'] == null
            ? null
            : (json['data'] as List)
                .map((e) => BulkUpsertResult.fromJson(Map<String, dynamic>.from(e)))
                .toList(),
      );
}

class BulkUpsertResult {
  String? serviceBranchId;
  bool? success;
  String? message;

  BulkUpsertResult({this.serviceBranchId, this.success, this.message});

  factory BulkUpsertResult.fromJson(Map<String, dynamic> json) => BulkUpsertResult(
        serviceBranchId: json['serviceBranchId'],
        success: json['success'],
        message: json['message'],
      );
}
