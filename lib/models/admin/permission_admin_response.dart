class PermissionAdminResponse {
  String? message;
  List<Data>? data;

  PermissionAdminResponse({this.message, this.data});

  PermissionAdminResponse.fromJson(Map<String, dynamic> json) {
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
  String? userId;
  String? permissionId;
  String? permissionName;

  Data({this.userId, this.permissionId, this.permissionName});

  Data.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    permissionId = json['permissionId'];
    permissionName = json['permissionName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['permissionId'] = permissionId;
    data['permissionName'] = permissionName;
    return data;
  }
}
