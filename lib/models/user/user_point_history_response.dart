class UserPointHistoryResponse {
  bool? success;
  Data? data;

  UserPointHistoryResponse({this.success, this.data});

  UserPointHistoryResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  int? totalPoint;
  String? nextExpiry;
  List<History>? history;

  Data({this.totalPoint, this.nextExpiry, this.history});

  Data.fromJson(Map<String, dynamic> json) {
    totalPoint = json['totalPoint'];
    nextExpiry = json['nextExpiry'];
    if (json['history'] != null) {
      history = <History>[];
      json['history'].forEach((v) {
        history!.add(History.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['totalPoint'] = totalPoint;
    data['nextExpiry'] = nextExpiry;
    if (history != null) {
      data['history'] = history!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class History {
  String? transactionId;
  String? description;
  int? pointType;
  int? points;
  String? date;
  // List<Null>? breakdown;

  History({
    this.transactionId,
    this.description,
    this.pointType,
    this.points,
    this.date,
    // this.breakdown
  });

  History.fromJson(Map<String, dynamic> json) {
    transactionId = json['transactionId'];
    description = json['description'];
    pointType = json['pointType'];
    points = json['points'];
    date = json['date'];
    // if (json['breakdown'] != null) {
    //   breakdown = <Null>[];
    //   json['breakdown'].forEach((v) {
    //     breakdown!.add(Null.fromJson(v));
    //   });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['transactionId'] = transactionId;
    data['description'] = description;
    data['pointType'] = pointType;
    data['points'] = points;
    data['date'] = date;
    // if (breakdown != null) {
    //   data['breakdown'] = breakdown!.map((v) => v.toJson()).toList();
    // }
    return data;
  }
}
