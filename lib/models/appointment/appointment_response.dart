class AppointmentResponse {
  String? message;
  List<Data>? data;
  int? totalCount;
  int? totalPage;

  AppointmentResponse({this.message, this.data, this.totalCount, this.totalPage});

  AppointmentResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
    totalCount = json['totalCount'];
    totalPage = json['totalPage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['totalCount'] = totalCount;
    data['totalPage'] = totalPage;
    return data;
  }
}

class Data {
  String? appointmentId;
  String? serviceBranchId;
  String? appointmentDatetime;
  String? appointmentNote;
  String? customerDueDate;
  int? appointmentRating;
  String? appointmentFeedback;
  int? appointmentStatus;
  String? createdDate;
  String? modifiedDate;
  User? user;
  Service? service;
  List<Payment>? payment;
  Branch? branch;

  Data({
    this.appointmentId,
    this.serviceBranchId,
    this.appointmentDatetime,
    this.appointmentNote,
    this.customerDueDate,
    this.appointmentRating,
    this.appointmentFeedback,
    this.appointmentStatus,
    this.createdDate,
    this.modifiedDate,
    this.user,
    this.service,
    this.payment,
    this.branch,
  });

  Data.fromJson(Map<String, dynamic> json) {
    appointmentId = json['appointmentId'];
    serviceBranchId = json['serviceBranchId'];
    appointmentDatetime = json['appointmentDatetime'];
    appointmentNote = json['appointmentNote'];
    customerDueDate = json['customerDueDate'];
    appointmentRating = json['appointmentRating'];
    appointmentFeedback = json['appointmentFeedback'];
    appointmentStatus = json['appointmentStatus'];
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    service = json['service'] != null ? Service.fromJson(json['service']) : null;
    if (json['payment'] != null) {
      payment = <Payment>[];
      json['payment'].forEach((v) {
        payment!.add(Payment.fromJson(v));
      });
    }
    branch = json['branch'] != null ? Branch.fromJson(json['branch']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['appointmentId'] = appointmentId;
    data['serviceBranchId'] = serviceBranchId;
    data['appointmentDatetime'] = appointmentDatetime;
    data['appointmentNote'] = appointmentNote;
    data['customerDueDate'] = customerDueDate;
    data['appointmentRating'] = appointmentRating;
    data['appointmentFeedback'] = appointmentFeedback;
    data['appointmentStatus'] = appointmentStatus;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    if (service != null) {
      data['service'] = service!.toJson();
    }
    if (payment != null) {
      data['payment'] = payment!.map((v) => v.toJson()).toList();
    }
    if (branch != null) {
      data['branch'] = branch!.toJson();
    }
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
  String? serviceDescription;
  String? servicePrice;
  int? isAdminOnly;
  int? dueDateToggle;
  String? eddRequired;
  int? doctorType;
  String? serviceBookingFee;

  Service({
    this.serviceId,
    this.serviceName,
    this.serviceDescription,
    this.servicePrice,
    this.doctorType,
    this.isAdminOnly,
    this.dueDateToggle,
    this.eddRequired,
    this.serviceBookingFee,
  });

  Service.fromJson(Map<String, dynamic> json) {
    serviceId = json['serviceId'];
    serviceName = json['serviceName'];
    serviceDescription = json['serviceDescription'];
    servicePrice = json['servicePrice'];
    doctorType = json['doctorType'];
    isAdminOnly = json['isAdminOnly'];
    dueDateToggle = json['dueDateToggle'];
    eddRequired = json['eddRequired'];
    serviceBookingFee = json['serviceBookingFee'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['serviceId'] = serviceId;
    data['serviceName'] = serviceName;
    data['serviceDescription'] = serviceDescription;
    data['servicePrice'] = servicePrice;
    data['doctorType'] = doctorType;
    data['serviceBookingFee'] = serviceBookingFee;
    data['dueDateToggle'] = dueDateToggle;
    data['eddRequired'] = eddRequired;
    data['doctorType'] = doctorType;
    return data;
  }
}

class Payment {
  String? paymentId;
  int? paymentType;
  String? paymentAsset;
  String? paymentAmount;
  int? paymentStatus;
  String? createdDate;
  String? modifiedDate;

  Payment({
    this.paymentId,
    this.paymentType,
    this.paymentAsset,
    this.paymentAmount,
    this.paymentStatus,
    this.createdDate,
    this.modifiedDate,
  });

  Payment.fromJson(Map<String, dynamic> json) {
    paymentId = json['paymentId'];
    paymentType = json['paymentType'];
    paymentAsset = json['paymentAsset'];
    paymentAmount = json['paymentAmount'];
    paymentStatus = json['paymentStatus'];
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['paymentId'] = paymentId;
    data['paymentType'] = paymentType;
    data['paymentAsset'] = paymentAsset;
    data['paymentAmount'] = paymentAmount;
    data['paymentStatus'] = paymentStatus;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
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
