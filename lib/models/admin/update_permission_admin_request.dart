class UpdatePermissionAdminRequest {
  String? userId;
  List<String>? permissionIds;

  UpdatePermissionAdminRequest({this.userId, this.permissionIds});

  UpdatePermissionAdminRequest.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    permissionIds = json['permissionIds'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['permissionIds'] = permissionIds;
    return data;
  }
}
