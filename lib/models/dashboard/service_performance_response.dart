num? _asNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

class ServicePerformanceResponse {
  String? message;
  ServicePerformanceData? data;

  ServicePerformanceResponse({this.message, this.data});

  ServicePerformanceResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    data = json['data'] != null ? ServicePerformanceData.fromJson(json['data']) : null;
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

class ServicePerformanceData {
  String? startDate;
  String? endDate;
  String? branchId;
  List<ServicePerformanceItem>? services;

  ServicePerformanceData({this.startDate, this.endDate, this.branchId, this.services});

  ServicePerformanceData.fromJson(Map<String, dynamic> json) {
    startDate = json['startDate'];
    endDate = json['endDate'];
    branchId = json['branchId'];
    if (json['services'] != null) {
      services = <ServicePerformanceItem>[];
      json['services'].forEach((v) {
        services!.add(ServicePerformanceItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['startDate'] = startDate;
    data['endDate'] = endDate;
    data['branchId'] = branchId;
    if (services != null) {
      data['services'] = services!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ServicePerformanceItem {
  String? serviceId;
  String? serviceName;
  String? serviceCategory;
  num? servicePrice;
  int? totalBookings;
  int? totalUpcoming;
  int? totalCompleted;
  int? totalCancelled;
  int? totalNoShow;
  num? averageRating;
  num? completedRevenue;

  ServicePerformanceItem({
    this.serviceId,
    this.serviceName,
    this.serviceCategory,
    this.servicePrice,
    this.totalBookings,
    this.totalUpcoming,
    this.totalCompleted,
    this.totalCancelled,
    this.totalNoShow,
    this.averageRating,
    this.completedRevenue,
  });

  ServicePerformanceItem.fromJson(Map<String, dynamic> json) {
    serviceId = json['serviceId'];
    serviceName = json['serviceName'];
    serviceCategory = json['serviceCategory'];
    servicePrice = _asNum(json['servicePrice']);
    totalBookings = _asNum(json['totalBookings'])?.toInt();
    totalUpcoming = _asNum(json['totalUpcoming'])?.toInt();
    totalCompleted = _asNum(json['totalCompleted'])?.toInt();
    totalCancelled = _asNum(json['totalCancelled'])?.toInt();
    totalNoShow = _asNum(json['totalNoShow'])?.toInt();
    averageRating = _asNum(json['averageRating']);
    completedRevenue = _asNum(json['completedRevenue']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['serviceId'] = serviceId;
    data['serviceName'] = serviceName;
    data['serviceCategory'] = serviceCategory;
    data['servicePrice'] = servicePrice;
    data['totalBookings'] = totalBookings;
    data['totalUpcoming'] = totalUpcoming;
    data['totalCompleted'] = totalCompleted;
    data['totalCancelled'] = totalCancelled;
    data['totalNoShow'] = totalNoShow;
    data['averageRating'] = averageRating;
    data['completedRevenue'] = completedRevenue;
    return data;
  }
}
