class AuthResponse {
  String? message;
  Data? data;

  AuthResponse({this.message, this.data});

  AuthResponse.fromJson(Map<String, dynamic> json) {
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
  User? user;
  String? accessToken;
  String? refreshToken;
  String? issuedDt;
  String? expiryDt;
  List<String>? userPermissions;

  Data({this.user, this.accessToken, this.refreshToken, this.issuedDt, this.expiryDt, this.userPermissions});

  Data.fromJson(Map<String, dynamic> json) {
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    accessToken = json['accessToken'];
    refreshToken = json['refreshToken'];
    issuedDt = json['issuedDt'];
    expiryDt = json['expiryDt'];
    userPermissions = json['userPermissions'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (user != null) {
      data['user'] = user!.toJson();
    }
    data['accessToken'] = accessToken;
    data['refreshToken'] = refreshToken;
    data['issuedDt'] = issuedDt;
    data['expiryDt'] = expiryDt;
    data['userPermissions'] = userPermissions;
    return data;
  }
}

class User {
  String? userId;
  String? userEmail;
  String? userName;
  String? fullName;

  User({this.userId, this.userEmail, this.userName, this.fullName});

  User.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    userEmail = json['userEmail'];
    userName = json['userName'];
    fullName = json['fullName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['userEmail'] = userEmail;
    data['userName'] = userName;
    data['fullName'] = fullName;
    return data;
  }
}
