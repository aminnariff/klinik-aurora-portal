class BranchRosterResponse {
  String? message;
  List<BranchRosterItem>? data;

  BranchRosterResponse({this.message, this.data});

  BranchRosterResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    final rawList = json['data'] ?? json['shifts'];
    if (rawList != null && rawList is List) {
      data = <BranchRosterItem>[];
      for (var v in rawList) {
        data!.add(BranchRosterItem.fromJson(v));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['message'] = message;
    if (data != null) {
      map['data'] = data!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class BranchRosterItem {
  String? rosterId;
  String? branchId;
  String? doctorId;
  String? doctorName;
  int? doctorType;
  String? rosterDate;
  String? startTime;
  String? endTime;
  int? maxConcurrent;
  int? isActive;

  BranchRosterItem({
    this.rosterId,
    this.branchId,
    this.doctorId,
    this.doctorName,
    this.doctorType,
    this.rosterDate,
    this.startTime,
    this.endTime,
    this.maxConcurrent,
    this.isActive,
  });

  BranchRosterItem.fromJson(Map<String, dynamic> json) {
    rosterId = json['rosterId']?.toString();
    branchId = json['branchId']?.toString();
    doctorId = json['doctorId']?.toString();
    doctorName = json['doctorName']?.toString();
    doctorType = json['doctorType'] != null ? int.tryParse(json['doctorType'].toString()) : null;
    rosterDate = json['rosterDate']?.toString();
    startTime = json['startTime']?.toString();
    endTime = json['endTime']?.toString();
    maxConcurrent = json['maxConcurrent'] != null ? int.tryParse(json['maxConcurrent'].toString()) : 1;
    isActive = json['isActive'] != null ? int.tryParse(json['isActive'].toString()) : 1;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['rosterId'] = rosterId;
    map['branchId'] = branchId;
    map['doctorId'] = doctorId;
    map['doctorName'] = doctorName;
    map['doctorType'] = doctorType;
    map['rosterDate'] = rosterDate;
    map['startTime'] = startTime;
    map['endTime'] = endTime;
    map['maxConcurrent'] = maxConcurrent;
    map['isActive'] = isActive;
    return map;
  }
}

class RosterShiftPayload {
  String? rosterId;
  String? rosterDate;
  String? startTime;
  String? endTime;
  int? maxConcurrent;

  RosterShiftPayload({
    this.rosterId,
    required this.rosterDate,
    required this.startTime,
    required this.endTime,
    this.maxConcurrent = 1,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    if (rosterId != null) map['rosterId'] = rosterId;
    map['rosterDate'] = rosterDate;
    map['startTime'] = startTime;
    map['endTime'] = endTime;
    map['maxConcurrent'] = maxConcurrent ?? 1;
    return map;
  }
}
