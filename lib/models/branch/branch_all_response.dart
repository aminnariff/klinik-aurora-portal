class BranchAllResponse {
  String? message;
  List<Data>? data;

  BranchAllResponse({this.message, this.data});

  BranchAllResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
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
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? branchId;
  String? branchName;
  String? branchCode;
  String? phoneNumber;
  String? branchImage;
  bool? is24Hours;
  String? branchOpeningHours;
  String? branchClosingHours;
  String? branchLaunchDate;
  String? address;
  int? postcode;
  String? city;
  String? state;
  int? branchStatus;
  String? createdDate;
  String? modifiedDate;

  Data({
    this.branchId,
    this.branchName,
    this.branchCode,
    this.phoneNumber,
    this.branchImage,
    this.is24Hours,
    this.branchOpeningHours,
    this.branchClosingHours,
    this.branchLaunchDate,
    this.address,
    this.postcode,
    this.city,
    this.state,
    this.branchStatus,
    this.createdDate,
    this.modifiedDate,
  });

  Data.fromJson(Map<String, dynamic> json) {
    branchId = json['branchId'];
    branchName = json['branchName'];
    branchCode = json['branchCode'];
    phoneNumber = json['phoneNumber'];
    branchImage = json['branchImage'];
    is24Hours = json['is24Hours'];
    branchOpeningHours = json['branchOpeningHours'];
    branchClosingHours = json['branchClosingHours'];
    branchLaunchDate = json['branchLaunchDate'];
    address = json['address'];
    postcode = json['postcode'];
    city = json['city'];
    state = json['state'];
    branchStatus = json['branchStatus'];
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['branchId'] = branchId;
    data['branchName'] = branchName;
    data['branchCode'] = branchCode;
    data['phoneNumber'] = phoneNumber;
    data['branchImage'] = branchImage;
    data['is24Hours'] = is24Hours;
    data['branchOpeningHours'] = branchOpeningHours;
    data['branchClosingHours'] = branchClosingHours;
    data['branchLaunchDate'] = branchLaunchDate;
    data['address'] = address;
    data['postcode'] = postcode;
    data['city'] = city;
    data['state'] = state;
    data['branchStatus'] = branchStatus;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    return data;
  }
}
