class PermissionAllResponse {
  String? message;
  List<Data>? data;

  PermissionAllResponse({this.message, this.data});

  PermissionAllResponse.fromJson(Map<String, dynamic> json) {
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
  String? permissionId;
  String? permissionName;
  int? permissionStatus;
  String? createdByEmail;
  String? createdDate;
  String? modifiedDate;

  Data(
      {this.permissionId,
      this.permissionName,
      this.permissionStatus,
      this.createdByEmail,
      this.createdDate,
      this.modifiedDate});

  Data.fromJson(Map<String, dynamic> json) {
    permissionId = json['permissionId'];
    permissionName = json['permissionName'];
    permissionStatus = json['permissionStatus'];
    createdByEmail = json['createdByEmail'];
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['permissionId'] = permissionId;
    data['permissionName'] = permissionName;
    data['permissionStatus'] = permissionStatus;
    data['createdByEmail'] = createdByEmail;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    return data;
  }
}
