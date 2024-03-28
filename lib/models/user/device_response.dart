class DeviceResponse {
  List<DeviceDetailList>? deviceDetailList;
  int? numberOfRecords;
  String? message;

  DeviceResponse({this.deviceDetailList, this.numberOfRecords, this.message});

  DeviceResponse.fromJson(Map<String, dynamic> json) {
    if (json['deviceDetailList'] != null) {
      deviceDetailList = <DeviceDetailList>[];
      json['deviceDetailList'].forEach((v) {
        deviceDetailList!.add(DeviceDetailList.fromJson(v));
      });
    }
    numberOfRecords = json['numberOfRecords'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (deviceDetailList != null) {
      data['deviceDetailList'] = deviceDetailList!.map((v) => v.toJson()).toList();
    }
    data['numberOfRecords'] = numberOfRecords;
    data['message'] = message;
    return data;
  }
}

class DeviceDetailList {
  int? installationCharge;
  String? contactNumber;
  String? orderReference;
  String? ipAddress;
  String? card;
  String? port;
  String? ont;
  String? profileNumber;
  String? subProfileNumber;
  String? nltType;
  String? ontModel;
  String? ontSn;
  String? ontPon;
  String? ontMac;
  String? networkStatus;
  String? orderRequestIdentifier;

  DeviceDetailList(
      {this.installationCharge,
      this.contactNumber,
      this.orderReference,
      this.ipAddress,
      this.card,
      this.port,
      this.ont,
      this.profileNumber,
      this.subProfileNumber,
      this.nltType,
      this.ontModel,
      this.ontSn,
      this.ontPon,
      this.ontMac,
      this.orderRequestIdentifier,
      this.networkStatus});

  DeviceDetailList.fromJson(Map<String, dynamic> json) {
    installationCharge = json['installationCharge'];
    contactNumber = json['contactNumber'];
    orderReference = json['orderReference'];
    ipAddress = json['ipAddress'];
    card = json['card'];
    port = json['port'];
    ont = json['ont'];
    profileNumber = json['profileNumber'];
    subProfileNumber = json['subProfileNumber'];
    nltType = json['nltType'];
    ontModel = json['ontModel'];
    ontSn = json['ontSn'];
    ontPon = json['ontPon'];
    ontMac = json['ontMac'];
    networkStatus = json['networkStatus'];
    orderRequestIdentifier = json['orderRequestIdentifier'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['installationCharge'] = installationCharge;
    data['contactNumber'] = contactNumber;
    data['orderReference'] = orderReference;
    data['ipAddress'] = ipAddress;
    data['card'] = card;
    data['port'] = port;
    data['ont'] = ont;
    data['profileNumber'] = profileNumber;
    data['subProfileNumber'] = subProfileNumber;
    data['nltType'] = nltType;
    data['ontModel'] = ontModel;
    data['ontSn'] = ontSn;
    data['ontPon'] = ontPon;
    data['ontMac'] = ontMac;
    data['networkStatus'] = networkStatus;
    data['orderRequestIdentifier'] = orderRequestIdentifier;
    return data;
  }
}
