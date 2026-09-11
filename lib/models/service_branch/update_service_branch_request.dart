class UpdateServiceBranchRequest {
  String? serviceBranchId;
  int? serviceBranchStatus;
  List<String>? serviceBranchAvailableTime;
  String? serviceTime;
  Map<String, dynamic>? serviceTimeRules;
  bool resetServiceTimeRules = false;
  bool resetToHqDefault = false;

  UpdateServiceBranchRequest({
    this.serviceBranchId,
    this.serviceBranchStatus,
    this.serviceBranchAvailableTime,
    this.serviceTime,
    this.serviceTimeRules,
    this.resetServiceTimeRules = false,
    this.resetToHqDefault = false,
  });

  UpdateServiceBranchRequest.fromJson(Map<String, dynamic> json) {
    serviceBranchId = json['serviceBranchId'];
    serviceBranchStatus = json['serviceBranchStatus'];
    serviceBranchAvailableTime = json['serviceBranchAvailableTime'] != null
        ? (json['serviceBranchAvailableTime'] as List).cast<String>()
        : null;
    serviceTime = json['serviceTime'];
    if (json['serviceTimeRules'] != null && json['serviceTimeRules'] is Map<String, dynamic>) {
      serviceTimeRules = json['serviceTimeRules'];
    }
    resetToHqDefault = false;
    resetServiceTimeRules = false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (serviceBranchId != null) data['serviceBranchId'] = serviceBranchId;
    if (serviceBranchStatus != null) data['serviceBranchStatus'] = serviceBranchStatus;
    if (serviceBranchAvailableTime != null) data['serviceBranchAvailableTime'] = serviceBranchAvailableTime;
    if (resetToHqDefault) {
      data['serviceTime'] = null;
      data['serviceTimeRules'] = null;
    } else {
      if (serviceTime != null) {
        data['serviceTime'] = serviceTime;
      }
      if (resetServiceTimeRules) {
        data['serviceTimeRules'] = null;
      } else if (serviceTimeRules != null) {
        data['serviceTimeRules'] = serviceTimeRules;
      }
    }
    return data;
  }
}
