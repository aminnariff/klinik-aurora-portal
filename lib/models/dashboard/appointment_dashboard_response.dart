class AppointmentDashboardResponse {
  String? message;
  Data? data;

  AppointmentDashboardResponse({this.message, this.data});

  AppointmentDashboardResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  int? totalUpcoming;
  int? totalCompleted;
  int? totalCanceled;
  int? totalNoShow;
  double? potentialSales;

  Data({this.totalUpcoming, this.totalCompleted, this.totalCanceled, this.totalNoShow, this.potentialSales});

  Data.fromJson(Map<String, dynamic> json) {
    totalUpcoming = json['totalUpcoming'];
    totalCompleted = json['totalCompleted'];
    totalCanceled = json['totalCanceled'];
    totalNoShow = json['totalNoShow'];
    if (json['potentialSales'] != null) {
      potentialSales = double.parse(json['potentialSales'].toString());
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['totalUpcoming'] = totalUpcoming;
    data['totalCompleted'] = totalCompleted;
    data['totalCanceled'] = totalCanceled;
    data['totalNoShow'] = totalNoShow;
    data['potentialSales'] = potentialSales;
    return data;
  }
}
