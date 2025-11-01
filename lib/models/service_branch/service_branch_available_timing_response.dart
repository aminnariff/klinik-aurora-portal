class ServiceBranchAvailableTimingResponse {
  String? message;
  List<String>? slots;
  int? total;

  ServiceBranchAvailableTimingResponse({this.message, this.slots, this.total});

  ServiceBranchAvailableTimingResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    slots = json['slots'].cast<String>();
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['slots'] = slots;
    data['total'] = total;
    return data;
  }
}
