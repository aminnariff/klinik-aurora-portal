num? _asNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

class DashboardResponse {
  String? message;
  Data? data;

  DashboardResponse({this.message, this.data});

  DashboardResponse.fromJson(Map<String, dynamic> json) {
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
  int? totalUser;
  int? totalActiveUser;
  int? totalActiveBranch;
  int? totalActivePromotion;
  List<TotalRegistrationByDay>? totalRegistrationByDay;
  List<TotalRegistrationByMonth>? totalRegistrationByMonth;
  int? totalAppointmentsToday;
  int? totalAppointmentsThisMonth;
  num? revenueThisMonth;
  List<RevenueByMonth>? revenueByMonth;
  num? totalPointsExpiring30Days;
  String? branchId;

  Data(
      {this.totalUser,
      this.totalActiveUser,
      this.totalActiveBranch,
      this.totalActivePromotion,
      this.totalRegistrationByDay,
      this.totalRegistrationByMonth,
      this.totalAppointmentsToday,
      this.totalAppointmentsThisMonth,
      this.revenueThisMonth,
      this.revenueByMonth,
      this.totalPointsExpiring30Days,
      this.branchId});

  Data.fromJson(Map<String, dynamic> json) {
    totalUser = json['totalUser'];
    totalActiveUser = json['totalActiveUser'];
    totalActiveBranch = json['totalActiveBranch'];
    totalActivePromotion = json['totalActivePromotion'];
    if (json['totalRegistrationByDay'] != null) {
      totalRegistrationByDay = <TotalRegistrationByDay>[];
      json['totalRegistrationByDay'].forEach((v) {
        totalRegistrationByDay!.add(TotalRegistrationByDay.fromJson(v));
      });
    }
    if (json['totalRegistrationByMonth'] != null) {
      totalRegistrationByMonth = <TotalRegistrationByMonth>[];
      json['totalRegistrationByMonth'].forEach((v) {
        totalRegistrationByMonth!.add(TotalRegistrationByMonth.fromJson(v));
      });
    }
    totalAppointmentsToday = json['totalAppointmentsToday'];
    totalAppointmentsThisMonth = json['totalAppointmentsThisMonth'];
    revenueThisMonth = _asNum(json['revenueThisMonth']);
    if (json['revenueByMonth'] != null) {
      revenueByMonth = <RevenueByMonth>[];
      json['revenueByMonth'].forEach((v) {
        revenueByMonth!.add(RevenueByMonth.fromJson(v));
      });
    }
    totalPointsExpiring30Days = _asNum(json['totalPointsExpiring30Days']);
    branchId = json['branchId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['totalUser'] = totalUser;
    data['totalActiveUser'] = totalActiveUser;
    data['totalActiveBranch'] = totalActiveBranch;
    data['totalActivePromotion'] = totalActivePromotion;
    if (totalRegistrationByDay != null) {
      data['totalRegistrationByDay'] = totalRegistrationByDay!.map((v) => v.toJson()).toList();
    }
    if (totalRegistrationByMonth != null) {
      data['totalRegistrationByMonth'] = totalRegistrationByMonth!.map((v) => v.toJson()).toList();
    }
    data['totalAppointmentsToday'] = totalAppointmentsToday;
    data['totalAppointmentsThisMonth'] = totalAppointmentsThisMonth;
    data['revenueThisMonth'] = revenueThisMonth;
    if (revenueByMonth != null) {
      data['revenueByMonth'] = revenueByMonth!.map((v) => v.toJson()).toList();
    }
    data['totalPointsExpiring30Days'] = totalPointsExpiring30Days;
    data['branchId'] = branchId;
    return data;
  }
}

class RevenueByMonth {
  int? year;
  int? month;
  num? revenueByMonth;

  RevenueByMonth({this.year, this.month, this.revenueByMonth});

  RevenueByMonth.fromJson(Map<String, dynamic> json) {
    year = json['year'];
    month = json['month'];
    revenueByMonth = _asNum(json['revenueByMonth']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['year'] = year;
    data['month'] = month;
    data['revenueByMonth'] = revenueByMonth;
    return data;
  }
}

class TotalRegistrationByDay {
  String? date;
  int? totalRegistrationByDay;

  TotalRegistrationByDay({this.date, this.totalRegistrationByDay});

  TotalRegistrationByDay.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    totalRegistrationByDay = json['totalRegistrationByDay'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['totalRegistrationByDay'] = totalRegistrationByDay;
    return data;
  }
}

class TotalRegistrationByMonth {
  int? year;
  int? month;
  int? totalRegistrationByMonth;

  TotalRegistrationByMonth({this.year, this.month, this.totalRegistrationByMonth});

  TotalRegistrationByMonth.fromJson(Map<String, dynamic> json) {
    year = json['year'];
    month = json['month'];
    totalRegistrationByMonth = json['totalRegistrationByMonth'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['year'] = year;
    data['month'] = month;
    data['totalRegistrationByMonth'] = totalRegistrationByMonth;
    return data;
  }
}
