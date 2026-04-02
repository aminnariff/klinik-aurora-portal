class BranchPerformanceResponse {
  String? message;
  BranchPerformanceData? data;

  BranchPerformanceResponse({this.message, this.data});

  BranchPerformanceResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    data = json['data'] != null ? BranchPerformanceData.fromJson(json['data']) : null;
  }
}

class BranchPerformanceData {
  List<DayPerformance>? last7Days;
  List<MonthPerformance>? last3Months;

  BranchPerformanceData({this.last7Days, this.last3Months});

  BranchPerformanceData.fromJson(Map<String, dynamic> json) {
    if (json['last7Days'] != null) {
      last7Days = <DayPerformance>[];
      json['last7Days'].forEach((v) {
        last7Days!.add(DayPerformance.fromJson(v));
      });
    }
    if (json['last3Months'] != null) {
      last3Months = <MonthPerformance>[];
      json['last3Months'].forEach((v) {
        last3Months!.add(MonthPerformance.fromJson(v));
      });
    }
  }
}

class DayPerformance {
  String? fullDate;
  String? dd;
  String? mmm;
  String? yyyy;
  int? total;
  List<BranchCount>? data;

  DayPerformance({this.fullDate, this.dd, this.mmm, this.yyyy, this.total, this.data});

  DayPerformance.fromJson(Map<String, dynamic> json) {
    fullDate = json['fullDate'];
    dd = json['dd'];
    mmm = json['MMM'];
    yyyy = json['yyyy'];
    total = json['total'];
    if (json['data'] != null) {
      data = <BranchCount>[];
      json['data'].forEach((v) {
        data!.add(BranchCount.fromJson(v));
      });
    }
  }
}

class MonthPerformance {
  String? monthYear;
  String? mmm;
  String? yyyy;
  int? total;
  List<BranchCount>? data;

  MonthPerformance({this.monthYear, this.mmm, this.yyyy, this.total, this.data});

  MonthPerformance.fromJson(Map<String, dynamic> json) {
    monthYear = json['monthYear'];
    mmm = json['MMM'];
    yyyy = json['yyyy'];
    total = json['total'];
    if (json['data'] != null) {
      data = <BranchCount>[];
      json['data'].forEach((v) {
        data!.add(BranchCount.fromJson(v));
      });
    }
  }
}

class BranchCount {
  String? branchName;
  int? totalAppointments;

  BranchCount({this.branchName, this.totalAppointments});

  BranchCount.fromJson(Map<String, dynamic> json) {
    branchName = json['branchName'];
    totalAppointments = json['totalAppointments'];
  }
}
