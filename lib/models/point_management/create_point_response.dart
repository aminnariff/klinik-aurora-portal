class CreatePointResponse {
  String? message;
  String? id;

  CreatePointResponse({this.message, this.id});

  CreatePointResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['id'] = id;
    return data;
  }
}
