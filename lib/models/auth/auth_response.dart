class AuthResponse {
  String? message;
  JwtResponseModel? jwtResponseModel;
  List<UserPermissions>? userPermissions;

  AuthResponse({this.message, this.jwtResponseModel, this.userPermissions});

  AuthResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    jwtResponseModel = json['jwtResponseModel'] != null ? JwtResponseModel.fromJson(json['jwtResponseModel']) : null;
    if (json['userPermissions'] != null) {
      userPermissions = <UserPermissions>[];
      json['userPermissions'].forEach((v) {
        userPermissions!.add(UserPermissions.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (jwtResponseModel != null) {
      data['jwtResponseModel'] = jwtResponseModel!.toJson();
    }
    if (userPermissions != null) {
      data['userPermissions'] = userPermissions!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class JwtResponseModel {
  String? token;
  String? issuedDt;
  String? expiryDt;

  JwtResponseModel({this.token, this.issuedDt, this.expiryDt});

  JwtResponseModel.fromJson(Map<String, dynamic> json) {
    token = json['token'];
    issuedDt = json['issuedDt'];
    expiryDt = json['expiryDt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['token'] = token;
    data['issuedDt'] = issuedDt;
    data['expiryDt'] = expiryDt;
    return data;
  }
}

class UserPermissions {
  String? name;
  String? type;

  UserPermissions({this.name, this.type});

  UserPermissions.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['type'] = type;
    return data;
  }
}
