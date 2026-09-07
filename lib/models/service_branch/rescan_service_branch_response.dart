class RescanServiceBranchResponse {
  String? message;
  String? serviceBranchId;
  String? serviceName;
  String? serviceTime;
  String? servicePrice;

  RescanServiceBranchResponse({
    this.message,
    this.serviceBranchId,
    this.serviceName,
    this.serviceTime,
    this.servicePrice,
  });

  RescanServiceBranchResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    serviceBranchId = json['serviceBranchId'];
    serviceName = json['serviceName'];
    serviceTime = json['serviceTime']?.toString();
    servicePrice = json['servicePrice']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['serviceBranchId'] = serviceBranchId;
    data['serviceName'] = serviceName;
    data['serviceTime'] = serviceTime;
    data['servicePrice'] = servicePrice;
    return data;
  }
}
