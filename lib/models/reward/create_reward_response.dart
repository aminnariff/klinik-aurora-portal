class CreateRewardResponse {
  String? message;
  String? id;

  CreateRewardResponse({this.message, this.id});

  CreateRewardResponse.fromJson(Map<String, dynamic> json) {
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
