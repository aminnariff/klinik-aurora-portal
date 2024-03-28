class DeviceRequest {
  String? orderReference;
  String? serialNumber;
  String? oltId;
  String? card;
  String? port;
  String? ont;
  String? ontPON;
  String? ontMAC;
  String? nltType;
  String? ipAddress;
  int? page;
  int? pageSize;

  DeviceRequest(
      {this.orderReference,
      this.serialNumber,
      this.oltId,
      this.card,
      this.port,
      this.ont,
      this.ontPON,
      this.ontMAC,
      this.nltType,
      this.ipAddress,
      this.page,
      this.pageSize});

  DeviceRequest.fromJson(Map<String, dynamic> json) {
    orderReference = json['orderReference'];
    serialNumber = json['serialNumber'];
    oltId = json['oltId'];
    card = json['card'];
    port = json['port'];
    ont = json['ont'];
    ontPON = json['ontPON'];
    ontMAC = json['ontMAC'];
    nltType = json['nltType'];
    ipAddress = json['ipAddress'];
    page = json['page'];
    pageSize = json['pageSize'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['orderReference'] = orderReference;
    data['serialNumber'] = serialNumber;
    data['oltId'] = oltId;
    data['card'] = card;
    data['port'] = port;
    data['ont'] = ont;
    data['ontPON'] = ontPON;
    data['ontMAC'] = ontMAC;
    data['nltType'] = nltType;
    data['ipAddress'] = ipAddress;
    data['page'] = page;
    data['pageSize'] = pageSize;
    return data;
  }
}
