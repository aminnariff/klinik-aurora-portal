class UpdateAppointmentResponse {
  String? message;
  String? id;

  UpdateAppointmentResponse({this.message, this.id});

  UpdateAppointmentResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['id'] = id;
    return data;
  }
}
