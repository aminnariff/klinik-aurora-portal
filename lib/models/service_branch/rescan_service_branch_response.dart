class RescanServiceBranchResponse {
  String? message;
  String? serviceBranchId;
  String? serviceName;

  RescanServiceBranchResponse({this.message, this.serviceBranchId, this.serviceName});

  RescanServiceBranchResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    serviceBranchId = json['serviceBranchId'];
    serviceName = json['serviceName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['serviceBranchId'] = serviceBranchId;
    data['serviceName'] = serviceName;
    return data;
  }
}
