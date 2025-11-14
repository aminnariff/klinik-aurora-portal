class AppointmentDetailResponse {
  String? message;
  Data? data;

  AppointmentDetailResponse({this.message, this.data});

  AppointmentDetailResponse.fromJson(Map<String, dynamic> json) {
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
  String? appointmentId;
  String? appointmentDatetime;
  String? appointmentNote;
  String? customerDueDate;
  String? appointmentRating;
  String? appointmentFeedback;
  int? appointmentStatus;
  int? appointmentIsDeleted;
  String? createdDate;
  String? modifiedDate;
  User? user;
  Service? service;
  Branch? branch;
  String? serviceBranchId;

  Data({
    this.appointmentId,
    this.appointmentDatetime,
    this.appointmentNote,
    this.customerDueDate,
    this.appointmentRating,
    this.appointmentFeedback,
    this.appointmentStatus,
    this.appointmentIsDeleted,
    this.createdDate,
    this.modifiedDate,
    this.user,
    this.service,
    this.branch,
    this.serviceBranchId,
  });

  Data.fromJson(Map<String, dynamic> json) {
    appointmentId = json['appointmentId'];
    appointmentDatetime = json['appointmentDatetime'];
    appointmentNote = json['appointmentNote'];
    customerDueDate = json['customerDueDate'];
    appointmentRating = json['appointmentRating'];
    appointmentFeedback = json['appointmentFeedback'];
    appointmentStatus = json['appointmentStatus'];
    appointmentIsDeleted = json['appointmentIsDeleted'];
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    service = json['service'] != null ? Service.fromJson(json['service']) : null;
    branch = json['branch'] != null ? Branch.fromJson(json['branch']) : null;
    serviceBranchId = json['serviceBranchId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['appointmentId'] = appointmentId;
    data['appointmentDatetime'] = appointmentDatetime;
    data['appointmentNote'] = appointmentNote;
    data['customerDueDate'] = customerDueDate;
    data['appointmentRating'] = appointmentRating;
    data['appointmentFeedback'] = appointmentFeedback;
    data['appointmentStatus'] = appointmentStatus;
    data['appointmentIsDeleted'] = appointmentIsDeleted;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    if (service != null) {
      data['service'] = service!.toJson();
    }
    if (branch != null) {
      data['branch'] = branch!.toJson();
    }
    data['serviceBranchId'] = serviceBranchId;
    return data;
  }
}

class User {
  String? userId;
  String? userName;
  String? userFullName;
  String? userEmail;
  String? userNric;
  String? userPhone;

  User({this.userId, this.userName, this.userFullName, this.userEmail, this.userNric, this.userPhone});

  User.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    userName = json['userName'];
    userFullName = json['userFullName'];
    userEmail = json['userEmail'];
    userNric = json['userNric'];
    userPhone = json['userPhone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['userName'] = userName;
    data['userFullName'] = userFullName;
    data['userEmail'] = userEmail;
    data['userNric'] = userNric;
    data['userPhone'] = userPhone;
    return data;
  }
}

class Service {
  String? serviceId;
  String? serviceName;
  int? doctorType;
  String? serviceBookingFee;
  String? servicePrice;
  int? isAdminOnly;
  int? dueDateToggle;
  String? eddRequired;

  Service({
    this.serviceId,
    this.serviceName,
    this.doctorType,
    this.serviceBookingFee,
    this.servicePrice,
    this.isAdminOnly,
    this.dueDateToggle,
    this.eddRequired,
  });

  Service.fromJson(Map<String, dynamic> json) {
    serviceId = json['serviceId'];
    serviceName = json['serviceName'];
    doctorType = json['doctorType'];
    serviceBookingFee = json['serviceBookingFee'];
    servicePrice = json['servicePrice'];
    isAdminOnly = json['isAdminOnly'];
    dueDateToggle = json['dueDateToggle'];
    eddRequired = json['eddRequired'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['serviceId'] = serviceId;
    data['serviceName'] = serviceName;
    data['doctorType'] = doctorType;
    data['serviceBookingFee'] = serviceBookingFee;
    data['servicePrice'] = servicePrice;
    data['isAdminOnly'] = isAdminOnly;
    data['dueDateToggle'] = dueDateToggle;
    data['eddRequired'] = eddRequired;
    return data;
  }
}

class Branch {
  String? branchId;
  String? branchCode;
  String? branchName;

  Branch({this.branchId, this.branchCode, this.branchName});

  Branch.fromJson(Map<String, dynamic> json) {
    branchId = json['branchId'];
    branchCode = json['branchCode'];
    branchName = json['branchName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['branchId'] = branchId;
    data['branchCode'] = branchCode;
    data['branchName'] = branchName;
    return data;
  }
}
