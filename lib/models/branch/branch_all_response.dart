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
  String? address;
  int? postcode;
  String? city;
  String? state;
  int? branchStatus;
  String? createdDate;
  String? modifiedDate;

  Data(
      {this.branchId,
      this.branchName,
      this.address,
      this.postcode,
      this.city,
      this.state,
      this.branchStatus,
      this.createdDate,
      this.modifiedDate});

  Data.fromJson(Map<String, dynamic> json) {
    branchId = json['branchId'];
    branchName = json['branchName'];
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
