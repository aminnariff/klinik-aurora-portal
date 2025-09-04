class UpdateServiceBranchRequest {
  String? serviceBranchId;
  int? serviceBranchStatus;
  List<String>? serviceBranchAvailableTime;

  UpdateServiceBranchRequest({this.serviceBranchId, this.serviceBranchStatus, this.serviceBranchAvailableTime});

  UpdateServiceBranchRequest.fromJson(Map<String, dynamic> json) {
    serviceBranchId = json['serviceBranchId'];
    serviceBranchStatus = json['serviceBranchStatus'];
    serviceBranchAvailableTime = json['serviceBranchAvailableTime'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['serviceBranchId'] = serviceBranchId;
    data['serviceBranchStatus'] = serviceBranchStatus;
    data['serviceBranchAvailableTime'] = serviceBranchAvailableTime;
    return data;
  }
}
