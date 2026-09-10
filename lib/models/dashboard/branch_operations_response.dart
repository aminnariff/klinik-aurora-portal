class BranchOperationsResponse {
  String? message;
  BranchOperationsData? data;

  BranchOperationsResponse({this.message, this.data});

  BranchOperationsResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    data = json['data'] != null ? BranchOperationsData.fromJson(json['data']) : null;
  }
}

class BranchOperationsData {
  String? branchId;
  String? branchName;
  TodayOperationsSummary? today;
  List<UpcomingQueueItem>? upcomingQueue;
  List<DoctorOnDutyItem>? doctorsOnDuty;
  List<WeeklyActivityItem>? weeklyActivity;
  List<TopServiceItem>? topServices;
  num? revenueThisMonth;

  BranchOperationsData({
    this.branchId,
    this.branchName,
    this.today,
    this.upcomingQueue,
    this.doctorsOnDuty,
    this.weeklyActivity,
    this.topServices,
    this.revenueThisMonth,
  });

  BranchOperationsData.fromJson(Map<String, dynamic> json) {
    branchId = json['branchId'];
    branchName = json['branchName'];
    today = json['today'] != null ? TodayOperationsSummary.fromJson(json['today']) : null;
    if (json['upcomingQueue'] != null) {
      upcomingQueue = <UpcomingQueueItem>[];
      json['upcomingQueue'].forEach((v) {
        upcomingQueue!.add(UpcomingQueueItem.fromJson(v));
      });
    }
    if (json['doctorsOnDuty'] != null) {
      doctorsOnDuty = <DoctorOnDutyItem>[];
      json['doctorsOnDuty'].forEach((v) {
        doctorsOnDuty!.add(DoctorOnDutyItem.fromJson(v));
      });
    }
    if (json['weeklyActivity'] != null) {
      weeklyActivity = <WeeklyActivityItem>[];
      json['weeklyActivity'].forEach((v) {
        weeklyActivity!.add(WeeklyActivityItem.fromJson(v));
      });
    }
    if (json['topServices'] != null) {
      topServices = <TopServiceItem>[];
      json['topServices'].forEach((v) {
        topServices!.add(TopServiceItem.fromJson(v));
      });
    }
    revenueThisMonth = json['revenueThisMonth'] != null
        ? num.tryParse(json['revenueThisMonth'].toString()) ?? 0
        : 0;
  }
}

class TodayOperationsSummary {
  int? totalToday;
  int? totalCompleted;
  int? totalUpcoming;
  int? totalCancelledOrNoShow;

  TodayOperationsSummary({
    this.totalToday,
    this.totalCompleted,
    this.totalUpcoming,
    this.totalCancelledOrNoShow,
  });

  TodayOperationsSummary.fromJson(Map<String, dynamic> json) {
    totalToday = json['totalToday'] ?? 0;
    totalCompleted = json['totalCompleted'] ?? 0;
    totalUpcoming = json['totalUpcoming'] ?? 0;
    totalCancelledOrNoShow = json['totalCancelledOrNoShow'] ?? 0;
  }
}

class UpcomingQueueItem {
  String? appointmentId;
  String? appointmentDatetime;
  int? appointmentStatus;
  String? patientName;
  String? serviceName;
  String? doctorName;

  UpcomingQueueItem({
    this.appointmentId,
    this.appointmentDatetime,
    this.appointmentStatus,
    this.patientName,
    this.serviceName,
    this.doctorName,
  });

  UpcomingQueueItem.fromJson(Map<String, dynamic> json) {
    appointmentId = json['appointmentId'];
    appointmentDatetime = json['appointmentDatetime'];
    appointmentStatus = json['appointmentStatus'];
    patientName = json['patientName'];
    serviceName = json['serviceName'];
    doctorName = json['doctorName'];
  }
}

class DoctorOnDutyItem {
  String? doctorId;
  String? doctorName;
  String? doctorImage;
  int? doctorStatus;

  DoctorOnDutyItem({
    this.doctorId,
    this.doctorName,
    this.doctorImage,
    this.doctorStatus,
  });

  DoctorOnDutyItem.fromJson(Map<String, dynamic> json) {
    doctorId = json['doctorId'];
    doctorName = json['doctorName'];
    doctorImage = json['doctorImage'];
    doctorStatus = json['doctorStatus'];
  }
}

class WeeklyActivityItem {
  String? dateStr;
  String? dayName;
  int? completed;
  int? scheduled;

  WeeklyActivityItem({
    this.dateStr,
    this.dayName,
    this.completed,
    this.scheduled,
  });

  WeeklyActivityItem.fromJson(Map<String, dynamic> json) {
    dateStr = json['dateStr'];
    dayName = json['dayName'];
    completed = json['completed'] ?? 0;
    scheduled = json['scheduled'] ?? 0;
  }
}

class TopServiceItem {
  String? serviceId;
  String? serviceName;
  int? totalBookings;
  num? revenue;

  TopServiceItem({
    this.serviceId,
    this.serviceName,
    this.totalBookings,
    this.revenue,
  });

  TopServiceItem.fromJson(Map<String, dynamic> json) {
    serviceId = json['serviceId'];
    serviceName = json['serviceName'];
    totalBookings = json['totalBookings'] ?? 0;
    revenue = json['revenue'] != null ? num.tryParse(json['revenue'].toString()) ?? 0 : 0;
  }
}
