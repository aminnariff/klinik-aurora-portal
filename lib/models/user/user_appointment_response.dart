class UserAppointmentResponse {
  String? message;
  String? userId;
  int? total;
  List<Data>? data;

  UserAppointmentResponse({this.message, this.userId, this.total, this.data});

  UserAppointmentResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    userId = json['userId'];
    total = json['total'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['userId'] = userId;
    data['total'] = total;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? appointmentId;
  String? appointmentDatetime;

  Data({this.appointmentId, this.appointmentDatetime});

  Data.fromJson(Map<String, dynamic> json) {
    appointmentId = json['appointmentId'];
    appointmentDatetime = json['appointmentDatetime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['appointmentId'] = appointmentId;
    data['appointmentDatetime'] = appointmentDatetime;
    return data;
  }
}
