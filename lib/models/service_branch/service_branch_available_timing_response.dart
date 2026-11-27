class ServiceBranchAvailableTimingResponse {
  String? message;
  List<String>? slots;
  int? total;
  String? sessionPreference;

  ServiceBranchAvailableTimingResponse({this.message, this.slots, this.total, this.sessionPreference});

  ServiceBranchAvailableTimingResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    slots = json['slots'].cast<String>();
    total = json['total'];
    sessionPreference = json['sessionPreference']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['slots'] = slots;
    data['total'] = total;
    if (sessionPreference != null) data['sessionPreference'] = sessionPreference;
    return data;
  }
}
