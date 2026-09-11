class UpdateServiceBranchRequest {
  String? serviceBranchId;
  int? serviceBranchStatus;
  List<String>? serviceBranchAvailableTime;
  String? serviceTime;
  bool resetToHqDefault = false;

  UpdateServiceBranchRequest({
    this.serviceBranchId,
    this.serviceBranchStatus,
    this.serviceBranchAvailableTime,
    this.serviceTime,
    this.resetToHqDefault = false,
  });

  UpdateServiceBranchRequest.fromJson(Map<String, dynamic> json) {
    serviceBranchId = json['serviceBranchId'];
    serviceBranchStatus = json['serviceBranchStatus'];
    serviceBranchAvailableTime = json['serviceBranchAvailableTime'] != null
        ? (json['serviceBranchAvailableTime'] as List).cast<String>()
        : null;
    serviceTime = json['serviceTime'];
    resetToHqDefault = false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (serviceBranchId != null) data['serviceBranchId'] = serviceBranchId;
    if (serviceBranchStatus != null) data['serviceBranchStatus'] = serviceBranchStatus;
    if (serviceBranchAvailableTime != null) data['serviceBranchAvailableTime'] = serviceBranchAvailableTime;
    if (resetToHqDefault) {
      data['serviceTime'] = null;
    } else if (serviceTime != null) {
      data['serviceTime'] = serviceTime;
    }
    return data;
  }
}
