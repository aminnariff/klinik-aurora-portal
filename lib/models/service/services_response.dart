class ServicesResponse {
  String? message;
  List<Data>? data;
  int? totalCount;
  int? totalPage;

  ServicesResponse({this.message, this.data, this.totalCount, this.totalPage});

  ServicesResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
    totalCount = json['totalCount'] is int
        ? json['totalCount']
        : int.tryParse(json['totalCount']?.toString() ?? '');
    totalPage = json['totalPage'] is int
        ? json['totalPage']
        : int.tryParse(json['totalPage']?.toString() ?? '');
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
  String? serviceId;
  String? serviceName;
  String? serviceDescription;
  String? servicePrice;
  String? serviceBookingFee;
  int? doctorType;
  String? serviceTime;
  String? serviceCategory;
  String? serviceImage;
  List<String>? serviceTemplate;
  int? serviceStatus;
  String? createdDate;
  String? modifiedDate;

  /// Gestational range, e.g. "11w0d-13w6d". Booking eligibility, and the
  /// patient scan timeline window when [scanMilestones] is set.
  String? eddRequired;

  /// Antenatal timeline steps this service covers: nt_scan, detail_scan, scan_4d5d, growth_scan.
  List<String> scanMilestones = const [];

  /// "single", "twin", or null for both.
  String? pregnancyType;

  Data({
    this.serviceId,
    this.serviceName,
    this.serviceDescription,
    this.servicePrice,
    this.serviceBookingFee,
    this.doctorType,
    this.serviceTime,
    this.serviceCategory,
    this.serviceImage,
    this.serviceTemplate,
    this.serviceStatus,
    this.createdDate,
    this.modifiedDate,
  });

  Data.fromJson(Map<String, dynamic> json) {
    serviceId = json['serviceId'];
    serviceName = json['serviceName'];
    serviceDescription = json['serviceDescription'];
    servicePrice = json['servicePrice'];
    serviceBookingFee = json['serviceBookingFee'];
    doctorType = json['doctorType'];
    serviceTime = json['serviceTime'];
    serviceCategory = json['serviceCategory'];
    serviceImage = json['serviceImage'];
    serviceTemplate =
        (json['serviceTemplate'] is List)
            ? List<String>.from(json['serviceTemplate'] ?? []).where((e) => e.trim().isNotEmpty).toList()
            : [];
    serviceStatus = json['serviceStatus'];
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
    eddRequired = json['eddRequired']?.toString();
    scanMilestones = (json['scanMilestones'] is List) ? List<String>.from(json['scanMilestones']) : const [];
    pregnancyType = json['pregnancyType']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['serviceId'] = serviceId;
    data['serviceName'] = serviceName;
    data['serviceDescription'] = serviceDescription;
    data['servicePrice'] = servicePrice;
    data['serviceBookingFee'] = serviceBookingFee;
    data['doctorType'] = doctorType;
    data['serviceTime'] = serviceTime;
    data['serviceCategory'] = serviceCategory;
    data['serviceImage'] = serviceImage;
    data['serviceTemplate'] = serviceTemplate;
    data['serviceStatus'] = serviceStatus;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    return data;
  }
}
